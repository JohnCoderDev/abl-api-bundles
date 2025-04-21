block-level on error undo, throw.
using classes.APIBundles.APIAfterProcess from propath.
using classes.APIBundles.Process.Interfaces.* from propath.

// this class will be called by the AfterProcessExample
class FlowClassExample.AfterProcess.SecondAfterProcess implements classes.APIBundles.Process.Interfaces.AfterProcess:
    define public property nextProcesses as APIAfterProcess no-undo get. set.
    
    method public Progress.Lang.Object runProcess(pBuffer as handle):
        message 
            'this is the second after process' skip
            pBuffer:buffer-field('field1'):buffer-value
            view-as alert-box.
    end method.
end class.
