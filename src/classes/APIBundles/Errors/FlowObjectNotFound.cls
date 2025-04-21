class classes.APIBundles.Errors.FlowObjectNotFound inherits Progress.Lang.AppError:
    constructor FlowObjectNotFound(pId as character):
        addMessage('it was not possible to find flow with id `' + pId + '`', -5685).
    end constructor.
end class.    
