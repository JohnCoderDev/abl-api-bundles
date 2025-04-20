class classes.APIBundles.Errors.ProcessMethodNotFound inherits Progress.Lang.AppError:
    constructor ProcessMethodNotFound(pMethod as character):
        addMessage('it was not possible to find process method with name`' + pMethod + '`', -5671).
    end constructor.
end class.
