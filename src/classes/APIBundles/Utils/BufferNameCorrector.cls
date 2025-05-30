block-level on error undo, throw.

class classes.APIBundles.Utils.BufferNameCorrector:
    constructor static BufferNameCorrector():
        addReplacement('(', '').
        addReplacement(')', '').
        addReplacement('~{', '').
        addReplacement('~}', '').
        addReplacement('[', '').
        addReplacement(']', '').
        addReplacement('`', '').
        addReplacement('�', '').
        addReplacement('�', '').
        addReplacement('�', '').
        addReplacement(':', '').
        addReplacement(';', '').
        addReplacement('/', '').
        addReplacement('?', '').
        addReplacement('.', '').
        addReplacement(',', '').
        addReplacement('=', '').
        addReplacement('+', '').
        addReplacement('�', '').
        addReplacement('*', '').
        addReplacement('&', '').
        addReplacement('�', '').
        addReplacement('$', '').
        addReplacement('#', '').
        addReplacement('@', '').
        addReplacement('!', '').
        addReplacement('~'', '').
        addReplacement('~~', '').
        addReplacement('"', '').
        addReplacement('\', '').
        addReplacement('|', '').
        addReplacement('<', '').
        addReplacement('>', '').
        addReplacement('�', '').
        addReplacement('�', '').
        addReplacement('�', '').
        addReplacement('�', '').
        addReplacement('�', '').
        addReplacement('�', 'a').
        addReplacement('�', 'a').
        addReplacement('�', 'a').
        addReplacement('�', 'a').
        addReplacement('�', 'a').
        addReplacement('�', 'e').
        addReplacement('�', 'e').
        addReplacement('�', 'e').
        addReplacement('�', 'e').
        addReplacement('�', 'i').
        addReplacement('�', 'i').
        addReplacement('�', 'i').
        addReplacement('�', 'i').
        addReplacement('�', 'o').
        addReplacement('�', 'o').
        addReplacement('�', 'o').
        addReplacement('�', 'o').
        addReplacement('�', 'o').
        addReplacement('�', 'u').
        addReplacement('�', 'u').
        addReplacement('�', 'u').
        addReplacement('�', 'u').
        addReplacement('�', 'n').
        addReplacement('�', 'c').
        addReplacement('�', 'y').
        addReplacement('�', 'y').
    end constructor.
    
    define private static temp-table replacements
        field source as character
        field replacement as character.
    
    method public static character correctName(pName as character):
        for each replacements:
            assign pName = replace(pName, replacements.source, replacements.replacement).
        end.
        return pName.
    end method.
    
    method public static void addReplacement(pSource as character, pReplacement as character):
        find first replacements
            where replacements.source = pSource
            no-error.
        
        if not available replacements then
            create replacements.
        
        assign
            replacements.source = pSource
            replacements.replacement = pReplacement.
    end method.
end class.
