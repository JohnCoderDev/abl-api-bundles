block-level on error undo, throw.
using Progress.Lang.* from propath.
using Progress.Reflect.Method from propath.
using classes.APIBundles.* from propath.
using classes.APIBundles.Errors.* from propath.
using classes.APIBundles.Flow.Interfaces.* from propath.
using classes.APIBundles.Validation.Interfaces.* from propath.
using classes.APIBundles.Process.Interfaces.* from propath.

class classes.APIBundles.APIFlow implements Flow:
    define private property flowArgument as ParameterList no-undo get. set.
    define public property dataConfiguration as APIDataConfiguration no-undo get. protected set.
    define public property validations as APIValidator no-undo get. protected set.
    define public property corrections as APICorrector no-undo get. protected set.
    define public property afterProcess as APIAfterProcess no-undo get. protected set.
    
    define private property throwValidationErrors as logical no-undo get. set.
    
    define private temp-table flowTypes
        field flowType as character
        field executorMethod as character
        index idxType as primary unique flowType.
    
    define private temp-table flows
        field flowType as character
        field flowObject as character
        index idxObject as primary unique flowObject
        index idxType flowType.
    
    define private temp-table validationErrorsProcess
        field className as character.
        
    define private temp-table onProcesses
        field className as character.
            
        
    constructor APIFlow():
        assign flowArgument = new ParameterList(0).
        addFlowType('procedure', 'procedureFlow').
        addFlowType('class', 'classFlow').
        addFlowType('method', 'methodFlow').
    end constructor.    
    
    
    method protected void procedureFlow():
        run value(flows.flowObject)(
            input this-object
        ).    
    end method.
    
    method protected void classFlow():
        define variable flowClass as Flow no-undo.
        assign flowClass = cast(Progress.Lang.Class:getClass(flows.flowObject):new(), Flow).
        flowClass:executeFlow(this-object).
        delete object flowClass.
    end method.
    
    method protected void methodFlow():
        define variable methodArgument as ParameterList no-undo.
        assign methodArgument = new ParameterList(0).
        
        this-object
            :getClass()
            :Invoke(this-object, flows.flowObject, methodArgument).
    end method.
    
    method public void addFlow(pFlowObject as character, pFlowType as character):
        assertFlowTypeExist(pFlowType).
        if not findFlowObject(pFlowObject) then do:
            create flows.
        end.
        assign
            flows.flowType = pFlowType
            flows.flowObject = pFlowObject.    
    end method.
    
    method public void addFlowType(pFlowType as character, pExecutorMethod as character):
        do on error undo, throw:
            this-object:getClass():getMethod(pExecutorMethod, flowArgument).
            
            catch errorObject as Progress.Lang.Error:
                return error new FlowExecutorMethodNotFound(pExecutorMethod).
            end catch.
        end.
        if not findFlowType(pFlowType) then do:        
            create flowTypes.
        end.
        
        assign
            flowTypes.flowType = pFlowType
            flowTypes.executorMethod = pExecutorMethod.
    end method.
    
    method public void executeFlow(pFlow as Progress.Lang.Object):
        runFlow().
    end method.
    
    method public void runFlow():
        runFlow(true).
    end method.
    
    method public void runFlow(pUseBufferNameAsGroup as logical):
        if not dataConfiguration:hasBuffers() then do:
            return error new DataConfigurationNotSettled().
        end.
        
        runBeforeFlows(pUseBufferNameAsGroup).
        
        if not validations:validationOK then do:
            return.
        end.
        
        runEachFlow().
        executeValidationErrorsProcesses().
        runAfterProcesses(pUseBufferNameAsGroup).
    end method.
    
    method protected void runEachFlow():
        for each flows no-lock:
            find flowTypes where flowTypes.flowType = flows.flowType.
            invokeFlowObject().
        end.
    end method.
    
    method protected void invokeFlowObject():
        this-object:getClass():Invoke(this-object, flowTypes.executorMethod).
    end method.
    
    method protected void runBeforeFlows(pUseBufferNameAsGroup as logical):
        define variable currentBuffer as handle no-undo.
        define variable currentGroup as character no-undo.
        assign currentBuffer = dataConfiguration:getFirstBuffer().
        
        do while dataConfiguration:hasBufferAvailable():
            assign currentGroup = if pUseBufferNameAsGroup then currentBuffer:name else ?.
            runCorrections(currentBuffer, currentGroup).
            runValidations(currentBuffer, currentGroup).    
            assign currentBuffer = dataConfiguration:getNextBuffer().
        end.
    end method.
    
    method protected void runAfterProcesses(pUseBufferNameAsGroup as logical):
        define variable currentBuffer as handle no-undo.
        define variable currentGroup as character no-undo.
        
        if afterProcess <> ? then do:
            assign currentBuffer = dataConfiguration:getFirstBuffer().
            do while dataConfiguration:hasBufferAvailable():
                assign currentGroup = if pUseBufferNameAsGroup then currentBuffer:name else ?.
                afterProcess:runProcesses(currentBuffer, currentGroup).
                runOnProcesses().
                assign currentBuffer = dataConfiguration:getNextBuffer().
            end.
        end.    
    end method.
    
    method protected void runOnProcesses():
        for each onProcesses no-lock:
            executeOnProcess().
        end.
    end method.
    
    method protected void executeOnProcess():
        define variable onProcessObject as OnAfterProcess no-undo.
        assign onProcessObject = cast(Progress.Lang.Class:getClass(onProcesses.className):new(), OnAfterProcess).
        onProcessObject:executeProcess(afterProcess, this-object).
        delete object onProcessObject.
    end method.
    
    method protected void runCorrections(pBuffer as handle, pGroup as character):
        if corrections <> ? then do:
            corrections:applyCorrections(pBuffer, true, pGroup).
        end.
    end method.
    
    method protected void runValidations(pBuffer as handle, pGroup as character):
        if validations <> ? then do:
            validations:applyValidators(pBuffer, pGroup).
            executeValidationErrorsProcesses().
        end.
    end method.
    
    method protected logical shouldThrowValidationErrors():
        if validations <> ? then do:
            return not validations:validationOK and throwValidationErrors.
        end.
        return false.
    end method.
    
    method protected void executeValidationErrorsProcesses():
        if not validations:validationOK then do:
            for each validationErrorsProcess no-lock:
                executeCurrentValidationErrorProcess().
            end.
        end.    
        if shouldThrowValidationErrors() then do:
            validations:throwValidationErrors().
        end.
    end method.
    
    method protected void executeCurrentValidationErrorProcess():
        define variable errorProcess as OnValidationError no-undo.
        assign errorProcess = cast(Progress.Lang.Class:getClass(validationErrorsProcess.className):new(), OnValidationError).
        errorProcess:executeProcess(validations, this-object).
        delete object errorProcess.
    end method.
    
    method private logical findFlowObject(pObject as character):
        find first flows
            where flows.flowObject = pObject
            no-error.
        return available flows.
    end method.    
    
    method private void assertFlowTypeExist(pType as character):
        if not findFlowType(pType) then do:
            return error new FlowTypeNotFound(pType).
        end.
    end method.
    
    method private logical findFlowType(pType as character):
        find first flowTypes
            where flowTypes.flowType = pType
            no-error.
        return available flowTypes.
    end method.
    
    method public APIDataConfiguration startDataConfiguration():
        assign dataConfiguration = new APIDataConfiguration().
        return dataConfiguration.
    end method.
    
    method public APICorrector startCorrector():
        assign corrections = new APICorrector().
        return corrections.
    end method.
    
    method public APIValidator startValidator():
        assign validations = new APIValidator().
        return validations.
    end method.
    
    method public APIAfterProcess startAfterProcess():
        assign afterProcess = new APIAfterProcess().
        return afterProcess.
    end method.
    
    method public void throwValidationErrorsOn():
        assign throwValidationErrors = true.
    end method.
    
    method public void throwValidationErrorsOff():
        assign throwValidationErrors = false.
    end method.
    
    method public void addValidationErrorProcess(pClass as character):
        create validationErrorsProcess.
        assign validationErrorsProcess.className = pClass.
    end method.
    
    method public void addOnProcess(pClass as character):
        create onProcesses.
        assign onProcesses.className = pClass.
    end method.    
    
    destructor APIFlow():
        empty temp-table flowTypes.
        empty temp-table flows.
        empty temp-table onProcesses.
        empty temp-table validationErrorsProcess.
        delete object validations no-error.
        delete object corrections no-error.
        delete object dataConfiguration no-error.
        delete object afterProcess no-error.
    end destructor.
end class.
