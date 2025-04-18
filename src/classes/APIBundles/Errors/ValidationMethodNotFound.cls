class classes.APIBundles.Errors.ValidationMethodNotFound inherits Progress.Lang.AppError:
    constructor ValidationMethodNotFound(pMethod as character):
        addMessage('it was not possible to find validation method `' + pMethod + '`', -5655).
    end constructor.    
end class.
