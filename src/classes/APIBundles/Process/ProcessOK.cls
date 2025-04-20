class classes.APIBundles.ProcessOK:
    define public property processMessage as character no-undo get. private set.
    
    constructor ProcessOK():
        assign processMessage = 'process ok'.
    end constructor.
    
    constructor ProcessOK(pMessage as character):
        assign processMessage = pMessage.
    end constructor.    
end class.
