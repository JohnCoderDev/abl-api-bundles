block-level on error undo, throw.
using classes.APIBundles.* from propath.
using classes.APIBundles.Errors.* from propath.

class classes.APIBundles.APIDataConfiguration:
    define private temp-table buffers
        field id as character
        field bufferHandle as handle
        index idxId as primary unique id.
    
    define private temp-table ignoredFields
        field id as character
        field fieldName as character
        field extentPosition as integer
        index idUnique as primary unique id fieldName extentPosition
        index idxId id.
        
    method public APIDataConfiguration addBuffer(pBuffer as handle):
        return addBuffer(pBuffer:name, pBuffer).
    end method.
    
    method public APIDataConfiguration addBuffer(pId as character, pBuffer as handle):
        assertIdDoesNotExist(pId).
        create buffers.
        assign
            buffers.id = pId
            buffers.bufferHandle = pBuffer.
        
        return this-object.
    end method.
    
    method public APIDataConfiguration addIgnoredField(pId as character, pFieldName as character):
        return addIgnoredField(pId, pFieldName, 0).
    end method.
    
    method public APIDataConfiguration addIgnoredField(
        pId as character, 
        pFieldName as character, 
        pPosition as integer
    ):
        assertIdExists(pId).
        
        do on error undo, throw:
            buffers.bufferHandle:buffer-field(pFieldName).
            
            catch errorObject as Progress.Lang.Error:
                return error new FieldNotFoundInBuffer(pId, pFieldName).
            end catch.
        end.
        
        if not can-find(
            first ignoredFields
            where
                ignoredFields.id = pId
                and ignoredFields.fieldName = pFieldName
                and ignoredFields.extentPosition = pPosition
        ) then do:
            create ignoredFields.
            assign
                ignoredFields.id = pId
                ignoredFields.fieldName = pFieldName
                ignoredFields.extentPosition = pPosition.
        end.
        
        return this-object.
    end method.
    
    method public APIDataConfiguration copyToBuffer(pSourceBuffer as handle):
        return copyToBuffer(pSourceBuffer, pSourceBuffer:name).
    end method.
    
    
    method public APIDataConfiguration copyToBuffer(
        pSourceBuffer as handle,
        pTargetId as character
    ):
        return copyToBuffer(pSourceBuffer, pTargetId, false).
    end method.
    
    method public APIDataConfiguration copyToBuffer(
        pSourceBuffer as handle, 
        pTargetId as character, 
        pForceUpdate as logical
    ):
        return copyToBuffer(pSourceBuffer, pTargetId, pForceUpdate, true).
    end method.
    
    method public APIDataConfiguration copyToBuffer(
        pSourceBuffer as handle, 
        pTargetId as character, 
        pForceUpdate as logical, 
        pCheckForEmptyExtent as logical
    ):
        return copyToBuffer(pSourceBuffer, pTargetId, pForceUpdate, pCheckForEmptyExtent, true).
    end method.
    
    method public APIDataConfiguration copyToBuffer(
        pSourceBuffer as handle, 
        pTargetId as character, 
        pForceUpdate as logical, 
        pCheckForEmptyExtent as logical,
        pIgnoreEmptySource as logical
    ):
        return copyToBuffer(pSourceBuffer, pTargetId, pForceUpdate, pCheckForEmptyExtent, pIgnoreEmptySource, false).
    end method.
        
    method public APIDataConfiguration copyToBuffer(
        pSourceBuffer as handle, 
        pTargetId as character, 
        pForceUpdate as logical, 
        pCheckForEmptyExtent as logical,
        pIgnoreEmptySource as logical,
        pIgnoreErrors as logical
    ):
        assertIdExists(pTargetId).
        define variable idx as integer no-undo.
        define variable targetBuffer as handle no-undo.
        assign targetBuffer = buffers.bufferHandle.
                
        copyOneByOne(
            pSourceBuffer, 
            targetBuffer, 
            pForceUpdate, 
            pCheckForEmptyExtent, 
            pIgnoreEmptySource, 
            pIgnoreErrors
        ).
        return this-object.
    end method.
    
    method private void copyOneByOne(
        input-output pSourceBuffer as handle,
        input-output pTargetBuffer as handle,
        pForceUpdate as logical,
        pCheckForEmptyExtent as logical,
        pIgnoreEmptySource as logical,
        pIgnoreErrors as logical
    ):
        define variable idx as integer no-undo.
        define variable idy as integer no-undo.
        define variable sourceBufferField as handle no-undo.
        define variable targetBufferField as handle no-undo.
        
        do idx = 1 to pSourceBuffer:num-fields on error undo, next:
            assign
                sourceBufferField = pSourceBuffer:buffer-field(idx)
                targetBufferField = pTargetBuffer:buffer-field(sourceBufferField:name).
            
            copyFieldWithBestStrategy(
                sourceBufferField, 
                targetBufferField, 
                pForceUpdate,
                pCheckForEmptyExtent,
                pIgnoreEmptySource
            ).
            
            catch errorObject as Progress.Lang.Error:
                if not pIgnoreErrors then do:
                    return error errorObject.
                end.
            end catch.
        end.
    end method.
    
    method private void copyFieldWithBestStrategy(
        input-output pSourceBufferField as handle,
        input-output pTargetBufferField as handle,
        pForceUpdate as logical,
        pCheckForEmptyExtent as logical,
        pIgnoreEmptySource as logical
    ):
        define variable idx as integer no-undo.
        define variable minimumExtent as integer no-undo.
        define variable extentSourcePosition as integer no-undo.
        define variable extentTargetPosition as integer no-undo.
        define variable currentSourcePosition as integer no-undo.
        define variable availableExtents as integer extent no-undo.
        define variable filledExtents as integer extent no-undo.        
        
        
        if pSourceBufferField:extent = 0 and pTargetBufferField:extent = 0 then do:
            if pIgnoreEmptySource and bufferHasInitialValue(pSourceBufferField, 0) then return.
            if not pForceUpdate and bufferFieldIsIgnored(pTargetBufferField, 0) then return.
            assign pTargetBufferField:buffer-value = pSourceBufferField:buffer-value.
            return.
        end.
        
        if pSourceBufferField:extent = 0 and pTargetBufferField:extent > 0 then do:
            if pIgnoreEmptySource and bufferHasInitialValue(pSourceBufferField, 0) then return.
            if not pForceUpdate and bufferFieldIsIgnored(pTargetBufferField, 0) then return.
            
            assign availableExtents = getTargetExtents(pTargetBufferField, pCheckForEmptyExtent).
            
            if extent(availableExtents) = ? then do:
                assign availableExtents = getBufferFieldAllExtents(pTargetBufferField).
            end.
                
            assign
                extentTargetPosition = availableExtents[1] 
                pTargetBufferField:buffer-value[extentTargetPosition] = pSourceBufferField:buffer-value.
            return.    
        end.
        
        if pSourceBufferField:extent > 0 and pTargetBufferField:extent = 0 then do:
            if not pForceUpdate and bufferFieldIsIgnored(pTargetBufferField, 0) then return.
            assign filledExtents = getSourceExtents(pSourceBufferField, pIgnoreEmptySource).
            if extent(filledExtents) = ? then return.
            assign
                extentSourcePosition = filledExtents[1]
                pTargetBufferField:buffer-value = pSourceBufferField:buffer-value[extentSourcePosition].                
            return.    
        end.
        
        
        assign
            availableExtents = getTargetExtents(pTargetBufferField, pCheckForEmptyExtent)
            filledExtents = getSourceExtents(pSourceBufferField, pIgnoreEmptySource).
        
        if extent(filledExtents) = ? then return.
        if extent(availableExtents) = ? or extent(filledExtents) > extent(availableExtents) then do:
            assign availableExtents = getBufferFieldAllExtents(pTargetBufferField).
        end.
        
        assign 
            minimumExtent = minimum(extent(availableExtents), extent(filledExtents))
            currentSourcePosition = 1.
        
        do idx = 1 to minimumExtent:
            assign
                extentTargetPosition = availableExtents[idx]
                extentSourcePosition = filledExtents[currentSourcePosition].
            
            if (
                bufferFieldIsIgnored(pTargetBufferField, extentTargetPosition)
                and not pForceUpdate
            ) then next.
            
            assign 
                pTargetBufferField:buffer-value[extentTargetPosition] = pSourceBufferField:buffer-value[extentSourcePosition]
                currentSourcePosition = currentSourcePosition + 1.
        end.
    end method.
    
    method private integer extent getSourceExtents(pSourceBufferField as handle, pIgnoreEmpty as logical):
        if pIgnoreEmpty then return getSourceFilledExtents(pSourceBufferField).
        return getBufferFieldAllExtents(pSourceBufferField).
    end method.
    
    method private integer extent getTargetExtents(pTargetBufferField as handle, pOnlyEmpty as logical):
        if pOnlyEmpty then return getTargetAvailableExtents(pTargetBufferField).
        return getBufferFieldAllExtents(pTargetBufferField).
    end method.
    
    method private integer extent getSourceFilledExtents(pSourceBufferField as handle):
        return getBufferFieldExtents(pSourceBufferField, true).
    end method.
    
    method private integer extent getTargetAvailableExtents(pTargetBufferField as handle):
        return getBufferFieldExtents(pTargetBufferField, false).
    end method.
    
    method private integer extent getBufferFieldAllExtents(pBufferField as handle):
        define variable idx as integer no-undo.
        define variable resultExtents as integer extent no-undo.
        
        assign extent(resultExtents) = pBufferField:extent.
        do idx = 1 to pBufferField:extent:
            assign resultExtents[idx] = idx.
        end.
        return resultExtents.
    end method.
    
    method private integer extent getBufferFieldExtents(pBufferField as handle, pFilled as logical):
        define variable resultExtents as integer extent no-undo.
        define variable currentExtent as integer no-undo.
        define variable bufferIsAvailable as logical no-undo.
        define variable idx as integer no-undo.
        
        do idx = 1 to pBufferField:extent:
            assign bufferIsAvailable = bufferHasInitialValue(pBufferField, idx).
            if ((pFilled and bufferIsAvailable) or (not pFilled and not bufferIsAvailable)) then next.
            assign
                currentExtent = currentExtent + 1
                extent(resultExtents) = currentExtent
                resultExtents[currentExtent] = idx.
        end.
        
        return resultExtents.
    end method.
    
    method private logical bufferHasInitialValue(pTargetBufferField as handle, pPosition as integer):
        if pTargetBufferField:extent > 0 and pPosition = 0 then 
            return (
                string(pTargetBufferField:buffer-value[1]) = pTargetBufferField:initial
                or string(pTargetBufferField:buffer-value[1]) = ?
            ).
        else if pTargetBufferField:extent > 0 then
            return (
                string(pTargetBufferField:buffer-value[pPosition]) = pTargetBufferField:initial
                or string(pTargetBufferField:buffer-value[pPosition]) = ?
            ).
        
        return (
            string(pTargetBufferField:buffer-value) = pTargetBufferField:initial
            or string(pTargetBufferField:buffer-value) = ?
        ).
    end method.
    
    method private logical bufferFieldIsIgnored(pBufferField as handle, pPosition as integer):
        return can-find(
            first ignoredFields
            where
                ignoredFields.id = pBufferField:buffer-handle:name
                and ignoredFields.fieldName = pBufferField:name
                and (
                    ignoredFields.extentPosition = pPosition
                    or ignoredFields.extentPosition = 0
                )    
            ).    
    end method.
    
    method private void assertIdDoesNotExist(pId as character):
        if findBufferById(pId) then do:
            return error new BufferWithIdAlreadyExists(pId).
        end.
    end method.
    
    method private void assertIdExists(pId as character):
        if not findBufferById(pId) then do:
             return error new BufferWithIdDoesNotExist(pId).
        end.
    end method.
    
    method private logical findBufferById(pId as character):
        find first buffers
            where buffers.id = pId
            no-error.
        return available buffers.    
    end method.
end class.
