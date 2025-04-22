block-level on error undo, throw.
using classes.APIBundles.Utils.* from propath.

class classes.APIBundles.Utils.BufferToLowerCase:
    define private temp-table fieldNames
        field fieldName as character.
        
    method public void applyToBuffer(pBuffer as handle):
        define variable currentField as handle no-undo.
        for each fieldNames no-lock:
            do on error undo, next:
                assign currentField = pBuffer:buffer-field(fieldNames.fieldName).
                if not currentField:data-type = 'character' then next.
                assign currentField:buffer-value = lower(currentField:buffer-value).
                catch errorObject as Progress.Lang.Error: end catch.
            end.    
        end.
    end method.
    
    method public BufferToLowerCase addField(pField as character):
        if not findField(pField) then do:
            create fieldNames.
        end.
        assign fieldNames.fieldName = pField.
        return this-object.
    end method.
    
    method private logical findField(pField as character):
        find first fieldNames
            where fieldNames.fieldName = pField
            no-error.
        return available fieldNames.    
    end method.
end class.
