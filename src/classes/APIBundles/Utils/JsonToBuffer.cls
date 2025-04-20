block-level on error undo, throw.
using Progress.Json.ObjectModel.* from propath.
using classes.APIBundles.Utils.* from propath.

class classes.APIBundles.Utils.JsonToBuffer:
    define private property tryToConvert as logical initial true no-undo get. set.
    define private property ignoreErrors as logical initial true no-undo get. set.
    define private property ignoreNulls as logical initial true no-undo get. set.
    define private property ignoreBlanks as logical initial true no-undo get. set.
    
    method public handle parseJson(pJson as JsonObject):
        define variable resultTable as handle no-undo.
        define variable jsonKeys as character extent no-undo.
        define variable currentKey as character no-undo.
        define variable correctedName as character no-undo.
        define variable currentArray as JsonArray no-undo.
        define variable idx as integer no-undo.
        
        create temp-table resultTable.
        assign jsonKeys = pJson:getNames().
        
        do idx = 1 to extent(jsonKeys):
            assign 
                currentKey = jsonKeys[idx]
                correctedName = BufferNameCorrector:correctName(currentKey).
            
            case pJson:getType(currentKey):
                when JsonDataType:string then do:
                    if pJson:getCharacter(currentKey) = '' and ignoreBlanks then next.
                    resultTable:add-new-field(correctedName, 'character').
                end.
                when JsonDataType:number then do:
                    resultTable:add-new-field(correctedName, 'decimal').
                end.
                when JsonDataType:boolean then do:
                    resultTable:add-new-field(correctedName, 'logical').
                end.
                when JsonDataType:array then do:
                    assign currentArray = pJson:getJsonArray(currentKey).
                    if currentArray:length = 0 then next.
                    
                    case currentArray:getType(1):
                        when JsonDataType:string then do:
                            resultTable:add-new-field(correctedName, 'character', currentArray:length).
                        end.
                        when JsonDataType:number then do:
                            resultTable:add-new-field(correctedName, 'decimal', currentArray:length).
                        end.
                        when JsonDataType:boolean then do:
                            resultTable:add-new-field(correctedName, 'logical', currentArray:length).
                        end.
                        when JsonDataType:null then do:
                            if ignoreNulls then next.
                            resultTable:add-new-field(correctedName, 'character', currentArray:length).
                        end.
                    end.
                end.
                when JsonDataType:null then do:
                    if ignoreNulls then next.
                    resultTable:add-new-field(correctedName, 'character').
                end.
            end.
        end.
        
        resultTable:temp-table-prepare('result').
        return parseJson(pJson, resultTable:default-buffer-handle).
    end method.
    
    method public handle parseJson(
        pJson as JsonObject, 
        pReferenceBuffer as handle
    ):
        if pReferenceBuffer = ? then return parseJson(pJson).
        define variable resultTable as handle no-undo.
        define variable defaultBuffer as handle no-undo.
        define variable currentField as handle no-undo.
        define variable jsonKeys as character extent no-undo.
        define variable currentKey as character no-undo.
        define variable correctedName as character no-undo.
        define variable idx as integer no-undo.
        
        create temp-table resultTable.
        resultTable:create-like(pReferenceBuffer).
        resultTable:temp-table-prepare('result').
        
        assign 
            defaultBuffer = resultTable:default-buffer-handle
            jsonKeys = pJson:getNames().
        
        do idx = 1 to extent(jsonKeys) on error undo, next:
            assign 
                currentKey = jsonKeys[idx]
                correctedName = BufferNameCorrector:correctName(currentKey)
                currentField = defaultBuffer:buffer-field(correctedName).
            
            copyFromJsonToField(currentField, pJson, currentKey).
            
            catch errorObject as Progress.Lang.Error:
                if not ignoreErrors then do:
                    return error errorObject.
                end.
            end catch.
        end.
        
        return defaultBuffer.
    end method.
    
    method private void copyFromJsonToField(input-output pBufferField as handle, pJson as JsonObject, pJsonKey as character):
        if pBufferField:extent > 0 then
            copyWithExtent(pBufferField, pJson, pJsonKey).
        else    
            copySingle(pBufferField, pJson, pJsonKey).    
    end method.
    
    method private void copySingle(input-output pBufferField as handle, pJson as JsonObject, pJsonKey as character):
        case pJson:getType(pJsonKey):
            when JsonDataType:string then do:
                case pBufferField:data-type:
                    when 'character' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        assign pBufferField:buffer-value = pJson:getCharacter(pJsonKey).
                    end.
                    when 'logical' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = logical(pJson:getCharacter(pJsonKey)).
                    end.
                    when 'integer' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = int(pJson:getCharacter(pJsonKey)).
                    end.
                    when 'int64' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = int64(pJson:getCharacter(pJsonKey)).
                    end.
                    when 'decimal' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = dec(pJson:getCharacter(pJsonKey)).
                    end.
                    when 'date' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        assign pBufferField:buffer-value = pJson:getDate(pJsonKey).
                    end.
                    when 'datetime' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        assign pBufferField:buffer-value = pJson:getDatetime(pJsonKey).
                    end.
                    when 'datetime-tz' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        assign pBufferField:buffer-value = pJson:getDatetimeTZ(pJsonKey).
                    end.
                end case.
            end.
            when JsonDataType:number then do:
                case pBufferField:data-type:
                    when 'character' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = string(pJson:getDecimal(pJsonKey)).
                    end.
                    when 'logical' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = logical(pJson:getDecimal(pJsonKey)).
                    end.
                    when 'integer' then do:
                        assign pBufferField:buffer-value = pJson:getInteger(pJsonKey).
                    end.
                    when 'int64' then do:
                        assign pBufferField:buffer-value = pJson:getInt64(pJsonKey).
                    end.
                    when 'decimal' then do:
                        assign pBufferField:buffer-value = pJson:getDecimal(pJsonKey).
                    end.
                    when 'date' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = date(pJson:getInteger(pJsonKey)).
                    end.
                end case.
            end.
            when JsonDataType:boolean then do:
                case pBufferField:data-type:
                    when 'character' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = string(pJson:getLogical(pJsonKey)).
                    end.
                    when 'logical' then do:
                        assign pBufferField:buffer-value = pJson:getLogical(pJsonKey).
                    end.
                    when 'integer' or when 'int64' or when 'decimal' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value = int(pJson:getLogical(pJsonKey)).
                    end.
                end case.
            end.
            when JsonDataType:null then do:
                case pBufferField:data-type:
                    when 'character' then do:
                        if ignoreNulls then return.
                        assign pBufferField:buffer-value = if tryToConvert then '' else ?.
                    end.
                    when 'logical' then do:
                        if ignoreNulls then return.
                        assign pBufferField:buffer-value = if tryToConvert then false else ?.
                    end.
                    when 'integer' or when 'int64' or when 'decimal' then do:
                        if ignoreNulls then return.
                        assign pBufferField:buffer-value = if tryToConvert then 0 else ?.
                    end.
                end case.
            end.
            when JsonDataType:array then do:
                define variable currentArray as JsonArray no-undo.
                define variable idx as integer no-undo.
                
                assign currentArray = pJson:getJsonArray(pJsonKey).
                do idx = 1 to currentArray:length:
                    case currentArray:getType(idx):
                        when JsonDataType:string then do:
                            case pBufferField:data-type:
                                when 'character' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    assign pBufferField:buffer-value = currentArray:getCharacter(idx).
                                    leave.
                                end.
                                when 'logical' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = logical(currentArray:getCharacter(idx)).
                                    leave.
                                end.
                                when 'integer' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = int(currentArray:getCharacter(idx)).
                                    leave.
                                end.
                                when 'int64' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = int64(currentArray:getCharacter(idx)).
                                    leave.
                                end.
                                when 'decimal' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = dec(currentArray:getCharacter(idx)).
                                    leave.
                                end.
                                when 'date' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    assign pBufferField:buffer-value = currentArray:getDate(idx).
                                    leave.
                                end.
                                when 'datetime' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    assign pBufferField:buffer-value = currentArray:getDatetime(idx).
                                    leave.
                                end.
                                when 'datetime-tz' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    assign pBufferField:buffer-value = currentArray:getDatetimeTZ(idx).
                                    leave.
                                end.
                            end case.
                        end.
                        when JsonDataType:number then do:
                            case pBufferField:data-type:
                                when 'character' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = string(currentArray:getDecimal(idx)).
                                    leave.
                                end.
                                when 'logical' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = logical(currentArray:getDecimal(idx)).
                                    leave.
                                end.
                                when 'integer' then do:
                                    assign pBufferField:buffer-value = currentArray:getInteger(idx).
                                    leave.
                                end.
                                when 'int64' then do:
                                    assign pBufferField:buffer-value = currentArray:getInt64(idx).
                                    leave.
                                end.
                                when 'decimal' then do:
                                    assign pBufferField:buffer-value = currentArray:getDecimal(idx).
                                    leave.
                                end.
                                when 'date' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = date(currentArray:getInteger(idx)).
                                    leave.
                                end.
                            end case.
                        end.
                        when JsonDataType:boolean then do:
                            case pBufferField:data-type:
                                when 'character' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = string(currentArray:getLogical(idx)).
                                    leave.
                                end.
                                when 'logical' then do:
                                    assign pBufferField:buffer-value = currentArray:getLogical(idx).
                                    leave.
                                end.
                                when 'integer' or when 'int64' or when 'decimal' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value = int(currentArray:getLogical(idx)).
                                    leave.
                                end.
                            end case.
                        end.
                        when JsonDataType:null then do:
                            case pBufferField:data-type:
                                when 'character' then do:
                                    if ignoreNulls then next.
                                    assign pBufferField:buffer-value = if tryToConvert then '' else ?.
                                    leave.
                                end.
                                when 'logical' then do:
                                    if ignoreNulls then next.
                                    assign pBufferField:buffer-value = if tryToConvert then false else ?.
                                    leave.
                                end.
                                when 'integer' or when 'int64' or when 'decimal' then do:
                                    if ignoreNulls then next.
                                    assign pBufferField:buffer-value = if tryToConvert then 0 else ?.
                                    leave.
                                end.
                            end case.
                        end.
                    end.    
                end.    
            end.
        end case.
    end method.
    
    method private void copyWithExtent(input-output pBufferField as handle, pJson as JsonObject, pJsonKey as character):
        case pJson:getType(pJsonKey):
            when JsonDataType:string then do:
                case pBufferField:data-type:
                    when 'character' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        assign pBufferField:buffer-value[1] = pJson:getCharacter(pJsonKey).
                    end.
                    when 'logical' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = logical(pJson:getCharacter(pJsonKey)).
                    end.
                    when 'integer' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = int(pJson:getCharacter(pJsonKey)).
                    end.
                    when 'int64' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = int64(pJson:getCharacter(pJsonKey)).
                    end.
                    when 'decimal' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = dec(pJson:getCharacter(pJsonKey)).
                    end.
                    when 'date' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        assign pBufferField:buffer-value[1] = pJson:getDate(pJsonKey).
                    end.
                    when 'datetime' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        assign pBufferField:buffer-value[1] = pJson:getDatetime(pJsonKey).
                    end.
                    when 'datetime-tz' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        assign pBufferField:buffer-value[1] = pJson:getDatetimeTZ(pJsonKey).
                    end.
                end case.
            end.
            when JsonDataType:number then do:
                case pBufferField:data-type:
                    when 'character' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = string(pJson:getDecimal(pJsonKey)).
                    end.
                    when 'logical' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = logical(pJson:getDecimal(pJsonKey)).
                    end.
                    when 'integer' then do:
                        assign pBufferField:buffer-value[1] = pJson:getInteger(pJsonKey).
                    end.
                    when 'int64' then do:
                        assign pBufferField:buffer-value[1] = pJson:getInt64(pJsonKey).
                    end.
                    when 'decimal' then do:
                        assign pBufferField:buffer-value[1] = pJson:getDecimal(pJsonKey).
                    end.
                    when 'date' then do:
                        if ignoreBlanks and pJson:getCharacter(pJsonKey) = '' then return.
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = date(pJson:getInteger(pJsonKey)).
                    end.
                end case.
            end.
            when JsonDataType:boolean then do:
                case pBufferField:data-type:
                    when 'character' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = string(pJson:getLogical(pJsonKey)).
                    end.
                    when 'logical' then do:
                        assign pBufferField:buffer-value[1] = pJson:getLogical(pJsonKey).
                    end.
                    when 'integer' or when 'int64' or when 'decimal' then do:
                        if not tryToConvert then return.
                        assign pBufferField:buffer-value[1] = int(pJson:getLogical(pJsonKey)).
                    end.
                end case.
            end.
            when JsonDataType:null then do:
                case pBufferField:data-type:
                    when 'character' then do:
                        if ignoreNulls then return.
                        assign pBufferField:buffer-value[1] = if tryToConvert then '' else ?.
                    end.
                    when 'logical' then do:
                        if ignoreNulls then return.
                        assign pBufferField:buffer-value[1] = if tryToConvert then false else ?.
                    end.
                    when 'integer' or when 'int64' or when 'decimal' then do:
                        if ignoreNulls then return.
                        assign pBufferField:buffer-value[1] = if tryToConvert then 0 else ?.
                    end.
                end case.
            end.
            when JsonDataType:array then do:
                define variable currentArray as JsonArray no-undo.
                define variable currentFieldPosition as integer initial 1 no-undo.
                define variable idx as integer no-undo.
                
                assign currentArray = pJson:getJsonArray(pJsonKey).
                do idx = 1 to currentArray:length:
                    if currentFieldPosition > extent(pBufferField) then leave.
                    case currentArray:getType(idx):
                        when JsonDataType:string then do:
                            case pBufferField:data-type:
                                when 'character' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = currentArray:getCharacter(idx).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'logical' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = logical(currentArray:getCharacter(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'integer' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = int(currentArray:getCharacter(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'int64' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = int64(currentArray:getCharacter(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'decimal' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = dec(currentArray:getCharacter(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'date' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = currentArray:getDate(idx).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'datetime' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = currentArray:getDatetime(idx).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'datetime-tz' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = currentArray:getDatetimeTZ(idx).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                            end case.
                        end.
                        when JsonDataType:number then do:
                            case pBufferField:data-type:
                                when 'character' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = string(currentArray:getDecimal(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'logical' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = logical(currentArray:getDecimal(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'integer' then do:
                                    assign pBufferField:buffer-value[currentFieldPosition] = currentArray:getInteger(idx).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'int64' then do:
                                    assign pBufferField:buffer-value[currentFieldPosition] = currentArray:getInt64(idx).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'decimal' then do:
                                    assign pBufferField:buffer-value[currentFieldPosition] = currentArray:getDecimal(idx).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'date' then do:
                                    if ignoreBlanks and currentArray:getCharacter(idx) = '' then next.
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = date(currentArray:getInteger(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                            end case.
                        end.
                        when JsonDataType:boolean then do:
                            case pBufferField:data-type:
                                when 'character' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = string(currentArray:getLogical(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'logical' then do:
                                    assign pBufferField:buffer-value[currentFieldPosition] = currentArray:getLogical(idx).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'integer' or when 'int64' or when 'decimal' then do:
                                    if not tryToConvert then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = int(currentArray:getLogical(idx)).
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                            end case.
                        end.
                        when JsonDataType:null then do:
                            case pBufferField:data-type:
                                when 'character' then do:
                                    if ignoreNulls then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = if tryToConvert then '' else ?.
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'logical' then do:
                                    if ignoreNulls then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = if tryToConvert then false else ?.
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                                when 'integer' or when 'int64' or when 'decimal' then do:
                                    if ignoreNulls then next.
                                    assign pBufferField:buffer-value[currentFieldPosition] = if tryToConvert then 0 else ?.
                                    currentFieldPosition = currentFieldPosition + 1.
                                end.
                            end case.
                        end.
                    end.    
                end.    
            end.
        end case.
    end method.

    method public JsonToBuffer convertionOn():
        assign tryToConvert = true.
        return this-object.
    end method.
    
    method public JsonToBuffer convertionOff():
        assign tryToConvert = false.
        return this-object.
    end method.
    
    method public JsonToBuffer ignoreErrorsOn():
        assign ignoreErrors = true.
        return this-object.
    end method.
    
    method public JsonToBuffer ignoreErrorsOff():
        assign ignoreErrors = false.
        return this-object.
    end method.
    
    method public JsonToBuffer ignoreNullsOn():
        assign ignoreNulls = true.
        return this-object.
    end method.
    
    method public JsonToBuffer ignoreNullsOff():
        assign ignoreNulls = false.
        return this-object.
    end method.
    
    method public JsonToBuffer ignoreBlanksOn():
        assign ignoreBlanks = true.
        return this-object.
    end method.
    
    method public JsonToBuffer ignoreBlanksOff():
        assign ignoreBlanks = false.
        return this-object.
    end method.
end class.
