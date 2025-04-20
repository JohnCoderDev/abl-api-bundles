class classes.APIBundles.Errors.FlowExecutorMethodNotFound inherits Progress.Lang.AppError:
    constructor FlowExecutorMethodNotFound(pMethod as character):
        addMessage('it was not possible to find a flow executor method named `' + pMethod + '`', -5682).
    end constructor.
end class.    
