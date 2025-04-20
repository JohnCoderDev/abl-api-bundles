class classes.APIBundles.Errors.DataConfigurationNotSettled inherits Progress.Lang.AppError:
    constructor DataConfigurationNotSettled():
        addMessage('no data configuration was provided to this flow', -5680).
    end constructor.    
end class.
