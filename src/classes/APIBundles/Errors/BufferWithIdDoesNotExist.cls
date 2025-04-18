class classes.APIBundles.Errors.BufferWithIdDoesNotExist inherits Progress.Lang.AppError:
    constructor BufferWithIdDoesNotExist(pId as character):
        addMessage('it was not possible to find buffer with id `' + pId + '`', -5651).
    end constructor.
end class.
