class classes.APIBundles.Errors.OperatorMatchNotFound inherits Progress.Lang.AppError:
    constructor OperatorMatchNotFound(pMatch as character):
        addMessage('it was not possible to find an operator that matches `' + pMatch + '`', -5665).
    end method.
end class.
