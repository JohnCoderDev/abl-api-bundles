block-level on error undo, throw.
using classes.APIBundles.* from propath.

class FlowClassExample.AfterProcess.APIAfterProcessesChild inherits APIAfterProcess:
    constructor APIAfterProcessesChild():
        super().
        addProcess('FlowClassExample.AfterProcess.AnotherAfterProcess', 'class').
    end constructor.
end class.
