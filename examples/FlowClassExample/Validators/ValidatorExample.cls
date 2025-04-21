block-level on error undo, throw.
using classes.APIBundles.Validation.* from propath.

// validators are used to stop the flow case something is wrong with
// the input data
class FlowClassExample.Validators.ValidatorExample implements classes.APIBundles.Validation.Interfaces.Validator:
    method public Progress.Lang.Object validate(pBuffer as handle):
        message 'validator is called' view-as alert-box.
        
        // not mandatory to return ValidationOK, but it could be
        // a good practice
        return new ValidationOK().
        
        // returning ValidationError stops the processing of the flow
        // return new ValidationError('test validation error').
    end method.
end class.
