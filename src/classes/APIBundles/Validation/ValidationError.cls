block-level on error undo, throw.
using classes.APIBundles.Validation.ValidationError from propath.

class classes.APIBundles.Validation.ValidationError inherits Progress.Lang.AppError:
    define public property originalClass as character 
        initial "classes.APIBundles.Validation.ValidationError" no-undo get. private set.
    
    constructor ValidationError():
    end constructor.
    
    constructor ValidationError(pMessage as character):
        addMessage(pMessage, -5700).
    end constructor.
    
    constructor ValidationError(pMessage as character, pCode as integer):
        addMessage(pMessage, pCode).
    end constructor.
    
    constructor ValidationError(pMessage as character, pCode as integer, pOriginalClass as character):
        addMessage(pMessage, pCode).
        assign originalClass = pOriginalClass.
    end constructor.
    
    method public void appendValidationError(pError as ValidationError):
        addMessage(pError:getMessage(1) + '(' + pError:originalClass + ')', pError:getMessageNum(1)).
    end method.
end class.
