class classes.APIBundles.Errors.CorrectionTypeNotFound inherits Progress.Lang.AppError:
    constructor CorrectionTypeNotFound(pType as character):
        addMessage('it was not possible to find correction type `' + pType + '`', -5661).
    end method.
end class.
