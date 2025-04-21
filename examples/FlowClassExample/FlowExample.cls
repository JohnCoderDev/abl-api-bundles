block-level on error undo, throw.
using classes.APIBundles.* from propath.

class FlowClassExample.FlowExample inherits APIFlow:
    define private temp-table tt-example
        field field1 as character
        field field2 as integer.
    
    constructor FlowExample():
        super().
        
        // adding a register to be modified by the corrector
        create tt-example.
        
        startDataConfiguration():addBuffer(
            temp-table tt-example:default-buffer-handle
        ).
        
        startValidator()
            :addValidator('FlowClassExample.Validators.ValidatorExample', 'class').
        
        startCorrector()
            :addCorrector('FlowClassExample.Corrections.CorrectorExample', 'class')
            :addCorrector('FlowClassExample.Corrections.CorrectorExample', 'class', 'field2', '<= 1234').
        
        startAfterProcess()
            :addProcess('FlowClassExample.AfterProcess.AfterProcessExample', 'class')
            :addProcess('FlowClassExample.AfterProcess.SecondAfterProcess', 'class').
        
        // programming this way, it could be better to have
        // only 1 method to do what you want to do. But if you
        // want to break in more methods, it is supported too.
        addFlow('flowMethod', 'method').
        addFlow('secondMethod', 'method').
    end constructor.    
    
    method public void flowMethod():
        message 'flowMethod works' view-as alert-box.
    end method.
    
    method public void secondMethod():
        message 'secondMethod works' view-as alert-box.
    end method.
end class.
