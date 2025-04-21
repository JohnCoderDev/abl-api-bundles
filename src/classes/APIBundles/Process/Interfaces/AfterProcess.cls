using classes.APIBundles.* from propath.

interface classes.APIBundles.Process.Interfaces.AfterProcess:
    define public property nextProcesses as APIAfterProcess no-undo get. set.
    
    method public Progress.Lang.Object runProcess(pBuffer as handle).
end interface.
