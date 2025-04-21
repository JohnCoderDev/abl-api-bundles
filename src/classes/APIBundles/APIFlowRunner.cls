block-level on error undo, throw.
using classes.APIBundles.* from propath.
using classes.APIBundles.Errors.* from propath.

class classes.APIBundles.APIFlowRunner:
    define public property flowsCount as integer no-undo get. private set.
    
    define private temp-table flows
        field id as character
        field flowObject as Progress.Lang.Object
        index idxId as primary unique id.
        
    method public APIFlowRunner addFlow(pId as character, pObject as APIFlow):
        if not findFlow(pId) then do:
            create flows.
            assign flowsCount = flowsCount + 1.
        end.    
        assign flows.flowObject = pObject.
        return this-object.
    end method.
    
    method public APIFlowRunner addFlow(pId as character, pClass as character):
        define variable flowObject as APIFlow no-undo.
        assign flowObject = cast(Progress.Lang.Class:getClass(pClass):new(), APIFlow).
        return addFlow(pId, flowObject).
    end method.
    
    method public APIFlowRunner removeFlow(pId as character):
        if findFlow(pId) then do:
            delete flows.
            assign flowsCount = flowsCount - 1.
        end.
    end method.    
    
    method public void runFlows():
        runFlows(true).
    end method.
    
    method public void runFlows(pUseGroup as logical):
        for each flows no-lock:
            cast(flows.flowObject, APIFlow):runFlow(pUseGroup).
        end.
    end method.
    
    method public APIFlow getFlow(pId as character):
        if not findFlow(pId) then do:
            return error new FlowObjectNotFound(pId).
        end.
        return cast(flows.flowObject, APIFlow).
    end method.
    
    method private logical findFlow(pId as character):
        find first flows
            where flows.id = pId
            no-error.
        return available flows.    
    end method.
end class.
