class classes.APIBundles.Errors.BufferWithIdAlreadyExists inherits Progress.Lang.AppError:
    constructor BufferWithIdAlreadyExists(pId as character):
        addMessage('buffer with id `' + pId + '` already exists', -5650).
    end constructor.
end class.
