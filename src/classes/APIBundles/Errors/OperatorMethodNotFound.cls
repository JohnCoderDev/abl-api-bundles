class classes.APIBundles.Errors.OperatorMethodNotFound inherits Progress.Lang.AppError:
    constructor OperatorMethodNotFound(pMethod as character):
        addMessage('it was not possible to find a method with name `' + pMethod + '`', -5663).
    end method.
end class.
