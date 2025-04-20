class classes.APIBundles.Process.ProcessError inherits Progress.Lang.AppError:
    constructor ProcessError(pMessage as character):
        addMessage(pMessage, -5700).
    end constructor.
    
    constructor ProcessError(pMessage as character, pCode as integer):
        addMessage(pMessage, pCode).
    end constructor.    
end class.
