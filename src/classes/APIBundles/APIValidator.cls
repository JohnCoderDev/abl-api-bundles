block-level on error undo, throw.
using Progress.Lang.ParameterList from propath.
using Progress.Reflect.Method from propath.
using Progress.Json.ObjectModel.* from propath.
using classes.APIBundles.APIValidator from propath.
using classes.APIBundles.Errors.* from propath.
using classes.APIBundles.Validation.* from propath.
using classes.APIBundles.Validation.Interfaces.* from propath.
using classes.APIBundles.Utils.SJsonToBuffer from propath.

class classes.APIBundles.APIValidator:
    define protected property validatorArguments as ParameterList no-undo get. set.
    define public property validationOK as logical no-undo get. private set.
    
    define private temp-table validators
        field validatorGroup as character initial '*'
        field validator as character
        field validatorType as character        
            index idxValidator as primary unique validator
            index idxType validatorType.
        
    define private temp-table validatorTypes
        field validatorType as character
        field executorMethod as character
            index idxType as primary unique validatorType.
            
    define private temp-table validationErrors
        field errorObject as Progress.Lang.Object.
    
    constructor APIValidator():
        assign validatorArguments = new ParameterList(1).
        validatorArguments:SetParameter(1, 'handle', 'input', ?).
        addValidatorType('procedure', 'procedureValidation').
        addValidatorType('class', 'classValidation').        
    end constructor.
    
    method protected Progress.Lang.Object procedureValidation(pBuffer as handle):
        define variable procedureResponse as Progress.Lang.Object no-undo.
        run value(validators.validator)(input pBuffer, output procedureResponse).
        return procedureResponse.
    end method.
    
    method protected Progress.Lang.Object classValidation(pBuffer as handle):
        define variable classObject as Validator no-undo.
        define variable classResponse as Progress.Lang.Object no-undo.
        assign 
            classObject = cast(Progress.Lang.Class:getClass(validators.validator):new(), Validator)
            classResponse = classObject:validate(pBuffer).
        delete object classObject.    
        return classResponse.
    end method.
 
    
    method public APIValidator applyValidators(pJson as JsonObject):
        return applyValidators(pJson, ?, ?).
    end method.
    
    method public APIValidator applyValidators(pJson as JsonObject, pGroup as character):
        return applyValidators(pJson, pGroup, ?).
    end method.    
    
    method public APIValidator applyValidators(pJson as JsonObject, pGroup as character, pReferenceBuffer as handle):
        define variable bufferHandle as handle no-undo.
        assign bufferHandle = SJsonToBuffer:parseJson(pJson, pReferenceBuffer).
        return applyValidators(bufferHandle, pGroup).
    end method.

    
    method public APIValidator applyValidators(pBuffer as handle):
        return applyValidators(pBuffer, ?).
    end method.
    
    method public APIValidator applyValidators(pBuffer as handle, pGroup as character):
        define variable validationResult as Progress.Lang.Object no-undo.
        empty temp-table validationErrors.
        
        validatorArguments:setParameter(1, 'handle', 'input', pBuffer).
        
        assign pGroup = if pGroup = ? then '*' else pGroup.
        
        for each validators no-lock 
            where validators.validatorGroup matches pGroup:
            
            find first validatorTypes 
                where validatorTypes.validatorType = validators.validatorType.
                
            assign 
                validationResult = this-object:getClass():Invoke(
                    this-object, 
                    validatorTypes.executorMethod, 
                    validatorArguments
                ).
                
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
    
    method public handle getValidationErrorsTable():
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
    
    method public JsonArray getValidationErrorsJsonArray():
        define variable resultArray as JsonArray no-undo.
        assign resultArray = new JsonArray().
        getValidationErrorsTable():write-json('JsonArray', resultArray, false, ?, false, true).
        return resultArray.
    end method.
    
    method protected void registerValidationResult(pResult as Progress.Lang.Object):
        if pResult = ? then return.
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
  
    method public APIValidator addValidator(pValidator as character, pValidatorType as character):
        return addValidator(pValidator, pValidatorType, ?).
    end method.
    
    method public APIValidator addValidator(pValidator as character, pValidatorType as character, pGroup as character):
        assertValidatorTypeExist(pValidatorType).
        
        if not findValidator(pValidator) then do:
            create validators.
        end.
        
        assign
            validators.validator = pValidator
            validators.validatorType = pValidatorType
            validators.validatorGroup = if pGroup = ? then '*' else pGroup.
            
        return this-object.
    end method.
    
    method public APIValidator addValidatorType(pValidatorType as character, pMethod as character):
        do on error undo, throw:
            this-object:getClass():getMethod(pMethod, validatorArguments).
            
            catch errorObject as Progress.Lang.Error:
                return error new classes.APIBundles.Errors.ValidationMethodNotFound(pMethod).
            end catch.    
        end.
        
        if not findValidatorType(pValidatorType) then do:
            create validatorTypes.
        end.
        
        assign
            validatorTypes.validatorType = pValidatorType
            validatorTypes.executorMethod = pMethod.
            
        return this-object.    
    end method.
    
    method private logical findValidator(pValidator as character):
        find first validators
            where validators.validator = pValidator
            no-error.
        return available validators.
    end method.    
    
    method private void assertValidatorTypeExist(pType as character):
        if not findValidatorType(pType) then do:
            return error new ValidatorTypeNotFound(pType).
        end.    
    end method.
    
    method private logical findValidatorType(pType as character):
        find first validatorTypes
            where validatorTypes.validatorType = pType
            no-error.
        return available validatorTypes.
    end method.
end class.
