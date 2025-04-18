class classes.APIBundles.Errors.FieldNotFoundInBuffer inherits Progress.Lang.AppError:
    constructor FieldNotFoundInBuffer(pBufferId as character, pFieldName as character):
        addMessage(
            'it was not possible to find field with name `' + pFieldName
            + '` in buffer with id `' + pBufferId + '`',
            -5652
        ).
    end constructor.
end class.
