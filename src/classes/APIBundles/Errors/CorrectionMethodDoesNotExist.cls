class classes.APIBundles.Errors.CorrectionMethodDoesNotExist inherits Progress.Lang.AppError:
    constructor CorrectionMethodDoesNotExist(pMethodName as character):
        addMessage('it was not possible to find a method with name `' + pMethodName + '`', -5660).
    end method.
end class.
