class classes.APIBundles.Errors.FlowTypeNotFound inherits Progress.Lang.AppError:
    constructor FlowTypeNotFound(pType as character):
        addMessage('it was not possible to find a flow type named `' + pType + '`', -5683).
    end constructor.    
end class.
