block-level on error undo, throw.

// this class is called before the validations to perform corrections
// in the buffer if necessary
class FlowClassExample.Corrections.CorrectorExample implements classes.APIBundles.Correction.Interfaces.Corrector:
    method public void correct(pBuffer as handle):
        message 'corrector is called' view-as alert-box.
        if pBuffer:buffer-field('field2'):buffer-value = 1234 then do:
            message 'value of field 2 already modified in the previous correction' view-as alert-box.
        end.
        else do:
            message 'modifying the buffer value' view-as alert-box.
        end.    
        pBuffer:buffer-field('field1'):buffer-value = 'test1234'.
        pBuffer:buffer-field('field2'):buffer-value = 1234.
    end method.
end class.
