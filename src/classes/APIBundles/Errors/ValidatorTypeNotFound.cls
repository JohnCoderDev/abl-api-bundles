class classes.APIBundles.Errors.ValidatorTypeNotFound inherits Progress.Lang.AppError:
    constructor ValidatorTypeNotFound(pValidatorType as character):
        addMessage('validator type `' + pValidatorType + '` was not found', -5654).
    end constructor.
end class.
