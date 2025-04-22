block-level on error undo, throw.
using classes.APIBundles.Utils.* from propath.

class classes.APIBundles.Utils.BufferReplicate:
    define private temp-table replicates
        field fieldSource as character
        field fieldTarget as character
        field extentPosition as integer.
        
    method public void applyToBuffer(pBuffer as handle):
        define variable sourceField as handle no-undo.
        define variable targetField as handle no-undo.
        
        for each replicates no-lock:
            do on error undo, next:
                assign 
                    sourceField = pBuffer:buffer-field(replicates.fieldSource)
                    targetField = pBuffer:buffer-field(replicates.fieldTarget).
                
                if (
                    not sourceField:data-type = targetField:data-type 
                    or not sourceField:extent = targetField:extent
                ) then next.
                
                if replicates.extentPosition = 0 then do:
                    assign targetField:buffer-value = sourceField:buffer-value.
                end.
                else do:
                    assign targetField:buffer-value[replicates.extentPosition] = sourceField:buffer-value[replicates.extentPosition].
                end.
                catch errorObject as Progress.Lang.Error: end catch.
            end.    
        end.
    end method.
    
    method public BufferReplicate addReplicate(pFieldSource as character, pFieldTarget as character):
        return addReplicate(pFieldSource, pFieldTarget, 0).
    end method.
    
    method public BufferReplicate addReplicate(pFieldSource as character, pFieldTarget as character, pExtent as integer):
        create replicates.
        assign 
            replicates.fieldSource = pFieldSource
            replicates.fieldTarget = pFieldTarget
            replicates.extentPosition = pExtent.
        return this-object.
    end method.
end class.
