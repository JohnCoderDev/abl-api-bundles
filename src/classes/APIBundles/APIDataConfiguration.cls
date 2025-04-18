block-level on error undo, throw.
using classes.APIBundles.* from propath.

class classes.APIBundles.APIDataConfiguration:
    define private temp-table buffers
        field id as character
        field bufferHandle as handle
        index idxId as primary unique id.
    
    define private temp-table nonUpdatableFields
        field id as character
        field fieldName as character
        field extentPosition as integer
        index idUnique as primary unique id fieldName extentPosition
        index idxId id.
        
    method public APIDataConfiguration addBuffer(pId as character, pHandle as handle):
        if can-find(first buffers where buffers.id = pId) then do:
            return error new classes.APIBundles.Errors.BufferWithIdAlreadyExists(pId).
        end.
        
        create buffers.
        assign
            buffers.id = pId
            buffers.bufferHandle = pHandle.
        
        return this-object.
    end method.
    
    method public APIDataConfiguration addNonUpdatableField(pId as character, pFieldName as character):
        return addNonUpdatableField(pId, pFieldName, 0).
    end method.
    
    method public APIDataConfiguration addNonUpdatableField(pId as character, pFieldName as character, pPosition as integer):
        find first buffers no-lock
            where buffers.id = pId
            no-error.
            
        if not available buffers then do:
            return error new classes.APIBundles.Errors.BufferWithIdDoesNotExist(pId).
        end.
        
        do on error undo, throw:
            buffers.bufferHandle:buffer-field(pFieldName).
            
            catch errorObject as Progress.Lang.Error:
                return error new classes.APIBundles.Errors.FieldNotFoundInBuffer(pId, pFieldName).
            end catch.
        end.
        
        if not can-find(
            first nonUpdatableFields
            where
                nonUpdatableFields.id = pId
                and nonUpdatableFields.fieldName = pFieldName
                and nonUpdatableFields.extentPosition = pposition
        ) then do:
            create nonUpdatableFields.
            assign
                nonUpdatableFields.id = pId
                nonUpdatableFields.fieldName = pFieldName
                nonUpdatableFields.extentPosition = pPosition.
        end.
        
        return this-object.
    end method.
end class.
