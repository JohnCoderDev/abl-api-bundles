block-level on error undo, throw.
using Progress.Lang.* from propath.
using Progress.Reflect.Method from propath.
using classes.APIBundles.* from propath.
using classes.APIBundles.Errors.* from propath.
using classes.APIBundles.Flow.Interfaces.* from propath.

class classes.APIBundles.APIFlow implements Flow:
    define private property flowArgument as ParameterList no-undo get. set.
    define public property dataConfiguration as APIDataConfiguration no-undo get. protected set.
    define public property validations as APIValidator no-undo get. protected set.
    define public property corrections as APICorrector no-undo get. protected set.
    define public property afterProcess as APIAfterProcess no-undo get. protected set.
    
    define private temp-table flowTypes
        field flowType as character
        field executorMethod as character
        index idxType as primary unique flowType.
    
    define private temp-table flows
        field flowType as character
        field flowObject as character
        index idxObject as primary unique flowObject
        index idxType flowType.
        
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
    
    method public void runFlow(pUseGroup as logical):
        if not dataConfiguration:hasBuffers() then do:
            return error new DataConfigurationNotSettled().
        end.
        
        define variable currentBuffer as handle no-undo.
        define variable currentGroup as character no-undo.
        define variable currentArgument as ParameterList no-undo.
        assign 
            currentBuffer = dataConfiguration:getFirstBuffer().
        
        do while dataConfiguration:hasBufferAvailable():
            assign currentGroup = if pUseGroup then currentBuffer:name else ?.
            if corrections <> ? then do:
                corrections:applyCorrections(currentBuffer, true, currentGroup).
            end.
            if validations <> ? then do:
                validations:applyValidators(currentBuffer, currentGroup).
                if not validations:validationOK then do:
                    validations:throwValidationErrors().
                end.
            end.    
            assign currentBuffer = dataConfiguration:getNextBuffer().
        end.
        
        for each flows no-lock:
            find flowTypes of flows.
            assign 
                currentArgument = new ParameterList(0).
                this-object:getClass():Invoke(this-object, flowTypes.executorMethod).
        end.
        
        if validations <> ? then do:
            if not validations:validationOK then do:
                validations:throwValidationErrors().
            end.
        end.    
        
        
        if afterProcess <> ? then do:
            assign currentBuffer = dataConfiguration:getFirstBuffer().
            do while dataConfiguration:hasBufferAvailable():
                assign currentGroup = if pUseGroup then currentBuffer:name else ?.
                afterProcess:runProcesses(currentBuffer, currentGroup).
                assign currentBuffer = dataConfiguration:getNextBuffer().
            end.
        end.    
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
end class.
