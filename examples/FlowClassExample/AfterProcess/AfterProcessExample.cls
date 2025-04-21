block-level on error undo, throw.
using classes.APIBundles.* from propath.
using FlowClassExample.AfterProcess.* from propath.

// after the execution of the flow, this class will be called
// with the method runProcess
class FlowClassExample.AfterProcess.AfterProcessExample implements classes.APIBundles.Process.Interfaces.AfterProcess:
    define public property nextProcesses as APIAfterProcess no-undo get. set.
    
    constructor AfterProcessExample():
        assign nextProcesses = new APIAfterProcessesChild().
    end constructor.
    
    method public Progress.Lang.Object runProcess(pBuffer as handle):
        message 'here you go with the after process' view-as alert-box.
    end method.
end class.
