block-level on error undo, throw.
using classes.APIBundles.Utils.* from propath.

class classes.APIBundles.Utils.SafeBufferCopy:
    define public property ignoreErrors as logical initial true no-undo get. private set.
    
    define private temp-table fieldToCopy
        field fieldName as character.
    
    method public SafeBufferCopy copyOnlySpecifiedFields(pBufferSource as handle, pBufferTarget as handle):
        for each fieldToCopy no-lock:
            pBufferTarget:buffer-field(fieldToCopy.fieldName):buffer-value = 
                pBufferSource:buffer-field(fieldToCopy.fieldName):buffer-value.
        end.
        return this-object.
    end method.
    
    method public SafeBufferCopy copyToEmptyFields(pBufferSource as handle, pBufferTarget as handle):
        define variable idx as integer no-undo.
        define variable idy as integer no-undo.
        define variable currentSourcePosition as integer no-undo.
        define variable sourceBufferField as handle no-undo.
        define variable targetBufferField as handle no-undo.
        
        do idx = 1 to pBufferTarget:num-fields on error undo, next:
            assign
                targetBufferField = pBufferTarget:buffer-field(idx)
                sourceBufferField = pBufferSource:buffer-field(targetBufferField:name).
            
            if targetBufferField:extent > 0 then do:
                assign currentSourcePosition = 1.
                do idy = 1 to targetBufferField:extent:
                    if hasInitialValue(targetBufferField, idy) then do:
                        assign
                            targetBufferField:buffer-value[idy] = sourceBufferField:buffer-value[currentSourcePosition]
                            currentSourcePosition = currentSourcePosition + 1.    
                    end.
                end.
            end.
            else do:
                if hasInitialValue(targetBufferField, 0) then do:
                    assign
                        targetBufferField:buffer-value = sourceBufferField:buffer-value.
                end.
            end.
            
            catch errorObject as Progress.Lang.Error:
                if not ignoreErrors then do:
                    return error errorObject.
                end.
            end catch.    
        end.
    end method.
    
    method private logical hasInitialValue(pBufferField as handle, pExtent as integer):
        if pBufferField:buffer-value = ? then
            return true.
        
        if pBufferField:extent > 0 then
            return 
                string(pBufferField:buffer-value[pExtent]) = pBufferField:initial
                or pBufferField:buffer-value[pExtent] = ?.
            
        return string(pBufferField:buffer-value) = pBufferField:initial.
    end method.
    
    method public SafeBufferCopy addFieldToCopy(pFieldName as character):
        if not findFieldToCopy(pFieldName) then create fieldToCopy.
        assign fieldToCopy.fieldName = pFieldName.
        return this-object.
    end method.
    
    method private logical findFieldToCopy(pFieldName as character):
        find first fieldToCopy
            where fieldToCopy.fieldName = pFieldName
            no-error.
        return available fieldToCopy.    
    end method.
    
    method public SafeBufferCopy ignoreErrorsOn():
        assign ignoreErrors = true.
        return this-object.
    end method.
    
    method public SafeBufferCopy ignoreErrorsOff():
        assign ignoreErrors = false.
        return this-object.
    end method.    
end class.
