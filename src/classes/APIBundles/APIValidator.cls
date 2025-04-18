block-level on error undo, throw.
using Progress.Lang.ParameterList from propath.
using Progress.Reflect.Method from propath.
using classes.APIBundles.APIValidator from propath.
using classes.APIBundles.Validation.* from propath.
using classes.APIBundles.Validation.Interfaces.* from propath.

class classes.APIBundles.APIValidator:
    define protected property validatorArguments as ParameterList no-undo get. set.
    define protected property validatorCallerMethod as Method no-undo get. set.
    define public property validationOK as logical no-undo get. private set.
    
    define private temp-table validators
        field validator as character
        field validatorType as character        
            index idxValidator as primary unique validator
            index idxType validatorType.
        
    define private temp-table validatorTypes
        field validatorType as character
        field methodName as character
            index idxType as primary unique validatorType.
            
    define private temp-table validationErrors
        field errorObject as Progress.Lang.Object.
    
    constructor APIValidator():
        assign validatorArguments = new ParameterList(2).
        registerValidatorType('procedure', 'procedureValidation').
        registerValidatorType('class', 'classValidation').        
    end constructor.
    
    method protected Progress.Lang.Object procedureValidation(pProcedure as character, pBuffer as handle):
        define variable procedureResponse as Progress.Lang.Object no-undo.
        run value(pProcedure)(input pBuffer, output procedureResponse).
        return procedureResponse.
    end method.
    
    method protected Progress.Lang.Object procedureValidation(pProcedure as character, pObject as Progress.Lang.Object):
        define variable procedureResponse as Progress.Lang.Object no-undo.
        run value(pProcedure)(input pObject, output procedureResponse).
        return procedureResponse.
    end method.
    
    method protected Progress.Lang.Object classValidation(pClass as character, pBuffer as handle):
        define variable classObject as Validator no-undo.
        assign classObject = cast(Progress.Lang.Class:getClass(pClass):new(), Validator).
        return classObject:validate(pBuffer).
    end method.
    
    method protected Progress.Lang.Object classValidation(pClass as character, pObject as Progress.Lang.Object):
        define variable classObject as Validator no-undo.
        assign classObject = cast(Progress.Lang.Class:getClass(pClass):new(), Validator).
        return classObject:validate(pObject).
    end method.
    
    method public APIValidator applyValidators(pBuffer as handle):
        define variable validationResult as Progress.Lang.Object no-undo.
        empty temp-table validationErrors.
                
        for each validators no-lock:
            find validatorTypes of validators.
            assign 
                validatorCallerMethod = getValidationCaller()
                validationResult = invokeValidator(validatorCallerMethod, pBuffer).
            registerValidationResult(validationResult).    
        end.
        
        updateValidationStatus().
        return this-object.
    end method.
    
    method private void updateValidationStatus():
        assign validationOK = not temp-table validationErrors:has-records.
    end method.
    
    method public void throwValidationErrors():
        updateValidationStatus().
        if validationOK then return.
        define variable errors as ValidationError no-undo.
        assign errors = new ValidationError().
        
        for each validationErrors:
            errors:appendValidationError(cast(validationErrors.errorObject, ValidationError)).
        end.
        
        return error errors.
    end method.
    
    method public APIValidator loadErrorsFromTable(
        pTable as handle, 
        pErrorCodeFieldName as character, 
        pErrorMessageFieldName as character
    ):
        define variable queryHandle as handle no-undo.
        define variable bufferHandle as handle no-undo.
        
        assign bufferHandle = pTable:default-buffer-handle.
        
        create query queryHandle.
        queryHandle:set-buffers(pTable:default-buffer-handle).
        queryHandle:query-prepare('for each ' + pTable:name).
        queryHandle:query-open.
        queryHandle:get-first.
        
        do while not queryHandle:query-off-end:
            create validationErrors.
            assign validationErrors.errorObject = new ValidationError(
                bufferHandle:buffer-field(pErrorMessageFieldName):buffer-value,
                bufferHandle:buffer-field(pErrorCodeFieldName):buffer-value,
                'temp-table'
            ).    
            queryHandle:get-next.
        end.
        
        queryHandle:query-close.
        delete object queryHandle.
        return this-object.
    end method.
    
    method public handle getErrorsTable():
        define variable errorsTable as handle no-undo.
        define variable bufferHandle as handle no-undo.
        define variable errorObject as ValidationError no-undo.
        
        create temp-table errorsTable.
        errorsTable:add-new-field('error-code', 'integer').
        errorsTable:add-new-field('error-message', 'character').
        errorsTable:add-new-field('error-class', 'character').
        errorsTable:temp-table-prepare('errors').
        
        bufferHandle = errorsTable:default-buffer-handle.
        
        for each validationErrors:
            bufferHandle:buffer-create.
            assign
                errorObject = cast(validationErrors.errorObject, ValidationError)
                bufferHandle:buffer-field('error-code'):buffer-value = errorObject:getMessageNum(1)
                bufferHandle:buffer-field('error-message'):buffer-value = errorObject:getMessage(1)
                bufferHandle:buffer-field('error-class'):buffer-value = errorObject:originalClass.
        end.
        
        return errorsTable.
    end method.
    
    method protected void registerValidationResult(pResult as Progress.Lang.Object):
        if pResult:getClass():TypeName = 'classes.APIBundles.Validation.ValidationOK' then return.
        
        define variable errorObject as Progress.Lang.Error no-undo.
        define variable idx as integer no-undo.
        
        assign errorObject = cast(pResult, Progress.Lang.Error).
        
        do idx = 1 to errorObject:NumMessages:
            create validationErrors.
            assign
                validationErrors.errorObject = new ValidationError(
                    errorObject:getMessage(idx),
                    errorObject:getMessageNum(idx),
                    errorObject:getClass():TypeName
                ).    
        end.
    end method.
    
    method private Progress.Lang.Object invokeValidator(pMethod as Method, pObject as Progress.Lang.Object):
        validatorArguments:setParameter(1, 'character', 'input', validators.validator).
        validatorArguments:setParameter(2, 'Progress.Lang.Object', 'input', pObject).
        return validatorCallerMethod:Invoke(this-object, validatorArguments).
    end method.
    
    method private Progress.Lang.Object invokeValidator(pMethod as Method, pBuffer as handle):
        validatorArguments:setParameter(1, 'character', 'input', validators.validator).
        validatorArguments:setParameter(2, 'handle', 'input', pBuffer).
        return validatorCallerMethod:Invoke(this-object, validatorArguments).
    end method.
    
    method private Method getValidationCaller():
        return this-object:getClass():getMethod(validatorTypes.methodName, validatorArguments).
    end method.
    
    method public APIValidator registerValidator(pValidator as character, pValidatorType as character):
        if not can-find(
            first validatorTypes 
            where validatorTypes.validatorType = pValidatorType
        ) then do:
            return error new classes.APIBundles.Errors.ValidatorTypeNotFound(pValidatorType).
        end.
        
        find first validators
            where validators.validator = pValidator
            no-error.
            
        if not available validators then do:
            create validators.
        end.
        
        assign
            validators.validator = pValidator
            validators.validatorType = pValidatorType.
            
        return this-object.
    end method.
    
    method public APIValidator registerValidatorType(pValidatorType as character, pMethod as character):
        do on error undo, throw:
            this-object:getClass():getMethod(pMethod, validatorArguments).
            
            catch errorObject as Progress.Lang.Error:
                return error new classes.APIBundles.Errors.ValidationMethodNotFound(pMethod).
            end catch.    
        end.
        
        find first validatorTypes
            where validatorTypes.validatorType = pValidatorType
            no-error.
        
        if not available validatorTypes then do:
            create validatorTypes.
        end.
        
        assign
            validatorTypes.validatorType = pValidatorType
            validatorTypes.methodName = pMethod.
            
        return this-object.    
    end method.
end class.
