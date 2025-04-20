block-level on error undo, throw.
using Progress.Lang.ParameterList from propath.
using Progress.Json.ObjectModel.* from propath.
using classes.APIBundles.APIAfterProcess from propath.
using classes.APIBundles.Errors.* from propath.
using classes.APIBundles.Process.Interfaces.* from propath.
using classes.APIBundles.Utils.JsonToBuffer from propath.

class classes.APIBundles.APIAfterProcess:
    define private property processArgument as ParameterList no-undo get. set.
    
    define private temp-table processes
        field processExecuter as character
        field processType as character
        field bufferHandle as handle
        field processId as character
        index idxType processType.
    
    define private temp-table processTypes 
        field processType as character
        field processMethod as character
        index idxType as primary unique processType.
        
    define private temp-table processesResponses
        field processExecuter as character
        field responseObject as Progress.Lang.Object.
        
    constructor APIAfterProcess():
        assign processArgument = new ParameterList(0).
        addProcessType('procedure', 'processProcedure').
        addProcessType('class', 'processClass').
    end constructor.
    
    method protected void processProcedure():
        define variable processResponse as Progress.Lang.Object.
        define variable nextProcess as APIAfterProcess no-undo.
        
        run value(processes.processExecuter)(
            input processes.bufferHandle,
            output processResponse,
            output nextProcess
        ).
        
        addResponse(processResponse).
        
        if (processResponseIsOK(processResponse) and nextProcess <> ?) then do:
            nextProcess:runProcesses().
            copyResponses(nextProcess).
        end.
        
        delete object nextProcess.
    end method.
    
    method protected void processClass():
        define variable processObject as AfterProcess no-undo.
        define variable processResponse as Progress.Lang.Object.
        
        assign 
            processObject = cast(Progress.Lang.Class:getClass(processes.processExecuter):new(), AfterProcess)
            processResponse = processObject:runProcess(processes.bufferHandle).
        
        if processResponseIsOK(processResponse) and processObject:nextProcess <> ? then do:
            processObject:nextProcess:runProcesses().
            copyResponses(processObject:nextProcess).
        end.
        
        delete object processObject.
    end method.
    
    method private logical processResponseIsOK(pResponse as Progress.Lang.Object):
        return pResponse:getClass():typeName = 'classes.APIBundles.Process.ProcessOK'.
    end method.
    
    method private void addResponse(pResponse as Progress.Lang.Object):
        create processesResponses.
        assign
            processesResponses.processExecuter = processes.processExecuter
            processesResponses.responseObject = pResponse.
    end method.
    
    method public void copyResponses(pProcesses as APIAfterProcess):
        define variable handleQuery as handle no-undo.
        define variable responsesDefaultBuffer as handle no-undo.
        
        assign responsesDefaultBuffer = pProcesses:getResponses():default-buffer-handle.
        
        create query handleQuery.
        handleQuery:query-prepare('for each ' + responsesDefaultBuffer:name).
        handleQuery:query-open.
        handleQuery:get-first.
        
        do while not handleQuery:query-off-end:
            addResponse(responsesDefaultBuffer).
            handleQuery:get-next.
        end.
        
        handleQuery:query-close.
        delete object handleQuery.
    end method.
    
    method private void addResponse(pSourceBuffer as handle):
        create processesResponses.
        temp-table processesResponses:default-buffer-handle:buffer-copy(pSourceBuffer).
    end method.
    
    method public handle getResponses():
        return temp-table processesResponses:handle.
    end method.
    
    method public void runProcesses():
        empty temp-table processesResponses.
        for each processes:
            find processTypes of processes.
            this-object
                :getClass()
                :getMethod(processTypes.processMethod, processArgument)
                :Invoke(processArgument).
        end.
    end method.
    
    method public APIAfterProcess addProcess(
        pExecuter as character,
        pType as character,
        pBufferHandle as handle
    ):
        return addProcess(pExecuter, pType, pBufferHandle, pBufferHandle:name).
    end method.
    
    method public APIAfterProcess addProcess(
        pExecuter as character,
        pType as character,
        pBufferHandle as handle,
        pId as character
    ):
        assertProcessTypeExist(pType).
        create processes.
        assign
            processes.processExecuter = pExecuter
            processes.processType = pType
            processes.bufferHandle = pBufferHandle
            processes.processId = pId .
        
        return this-object.
    end method.
    
    method public APIAfterProcess addProcess(
        pExecuter as character,
        pType as character,
        pJson as JsonObject,
        pId as character
    ):
        define variable bufferHandle as handle no-undo.
        define variable jsonTransformer as JsonToBuffer no-undo.
        assign 
            jsonTransformer = new JsonToBuffer()
            bufferHandle = jsonTransformer:parseJson(pJson).
        
        delete object jsonTransformer.
        return addProcess(pExecuter, pType, bufferHandle, pId).
    end method.
    
    method public APIAfterProcess addProcessType(
        pType as character, 
        pAssociatedMethod as character
    ):
        do on error undo, throw:
            this-object:getClass():getMethod(pAssociatedMethod, processArgument).
            
            catch errorObject as Progress.Lang.Error:
                return error new ProcessMethodNotFound(pAssociatedMethod).
            end catch.
        end.
        
        if not findProcessType(pType) then do:
            create processTypes.
        end.
        
        assign
            processTypes.processType = pType
            processTypes.processMethod = pAssociatedMethod.
        
        return this-object.
    end method.
    
    method private void assertProcessTypeExist(pType as character):
        if not findProcessType(pType) then do:
            return error new ProcessTypeNotFound(pType).
        end.
    end method.
    
    method private logical findProcessType(pType as character):
        find first processTypes
            where processTypes.processType = pType
            no-error.
        return available processTypes.
    end method.
end class.
