class classes.APIBundles.Errors.ProcessTypeNotFound inherits Progress.Lang.AppError:
    constructor ProcessTypeNotFound(pType as character):
        addMessage('it was not possible to find process type with id `' + pType + '`', -5670).
    end constructor.
end class.
