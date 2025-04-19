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
        addReplacement('ª', '').
        addReplacement('º', '').
        addReplacement('°', '').
        addReplacement(':', '').
        addReplacement(';', '').
        addReplacement('/', '').
        addReplacement('?', '').
        addReplacement('.', '').
        addReplacement(',', '').
        addReplacement('=', '').
        addReplacement('+', '').
        addReplacement('§', '').
        addReplacement('*', '').
        addReplacement('&', '').
        addReplacement('¨', '').
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
        addReplacement('¹', '').
        addReplacement('²', '').
        addReplacement('³', '').
        addReplacement('£', '').
        addReplacement('¬', '').
        addReplacement('á', 'a').
        addReplacement('à', 'a').
        addReplacement('ã', 'a').
        addReplacement('ä', 'a').
        addReplacement('â', 'a').
        addReplacement('é', 'e').
        addReplacement('è', 'e').
        addReplacement('ê', 'e').
        addReplacement('ë', 'e').
        addReplacement('í', 'i').
        addReplacement('ì', 'i').
        addReplacement('î', 'i').
        addReplacement('ï', 'i').
        addReplacement('õ', 'o').
        addReplacement('ó', 'o').
        addReplacement('ò', 'o').
        addReplacement('ô', 'o').
        addReplacement('ö', 'o').
        addReplacement('ú', 'u').
        addReplacement('ù', 'u').
        addReplacement('û', 'u').
        addReplacement('ü', 'u').
        addReplacement('ñ', 'n').
        addReplacement('ç', 'c').
        addReplacement('ý', 'y').
        addReplacement('ÿ', 'y').
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
