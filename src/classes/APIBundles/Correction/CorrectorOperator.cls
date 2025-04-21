block-level on error undo, throw.
using Progress.Lang.ParameterList from propath.
using classes.APIBundles.Correction.* from propath.
using classes.APIBundles.Errors.* from propath.

class classes.APIBundles.Correction.CorrectorOperator:
    define private property operatorArguments as ParameterList no-undo get. set.
    
    define private temp-table operators
        field operatorMatch as character
        field operatorArgument as character
        field associatedMethod as character.
        
    constructor CorrectorOperator():
        assign operatorArguments = new ParameterList(2).
        operatorArguments:setParameter(1, 'handle', 'input', ?).
        operatorArguments:setParameter(2, 'character', 'input', '').
        addOperator('= *', 'equal').
        addOperator('eq *', 'equal').
        addOperator('equal *', 'equal').
        addOperator('<> *', 'notEqual').
        addOperator('neq *', 'notEqual').
        addOperator('not-equal *', 'notEqual').
        addOperator('> *', 'greater').
        addOperator('gt *', 'greater').
        addOperator('greater *', 'greater').
        addOperator('greater-than *', 'greater').
        addOperator('< *', 'lower').
        addOperator('lt *', 'lower').
        addOperator('lower *', 'lower').
        addOperator('lower-than *', 'lower').
        addOperator('>= *', 'greaterEqual').
        addOperator('gte *', 'greaterEqual').
        addOperator('greater-equal *', 'greaterEqual').
        addOperator('greater-equal-than *', 'greaterEqual').
        addOperator('<= *', 'lowerEqual').
        addOperator('lte *', 'lowerEqual').
        addOperator('lower-equal *', 'lowerEqual').
        addOperator('lower-equal-than *', 'lowerEqual').
        addOperator('always', 'always').
    end constructor.
    
    method protected logical equal(pBufferField as handle, pArgument as character):
        case pBufferField:data-type:
            when 'character' then return pBufferField:buffer-value = pArgument.
            when 'integer' then return pBufferField:buffer-value = int(pArgument).
            when 'int64' then return pBufferField:buffer-value = int64(pArgument).
            when 'decimal' then return pBufferField:buffer-value = dec(pArgument).
            when 'date' then return pBufferField:buffer-value = date(pArgument).
            when 'datetime' then return pBufferField:buffer-value = datetime(pArgument).
            when 'datetime-tz' then return pBufferField:buffer-value = datetime-tz(pArgument).
            when 'logical' then return pBufferField:buffer-value = logical(pArgument).
        end case.
    end method.
    
    method protected logical notEqual(pBufferField as handle, pArgument as character):
        case pBufferField:data-type:
            when 'character' then return pBufferField:buffer-value <> pArgument.
            when 'integer' then return pBufferField:buffer-value <> int(pArgument).
            when 'int64' then return pBufferField:buffer-value <> int64(pArgument).
            when 'decimal' then return pBufferField:buffer-value <> dec(pArgument).
            when 'date' then return pBufferField:buffer-value <> date(pArgument).
            when 'datetime' then return pBufferField:buffer-value <> datetime(pArgument).
            when 'datetime-tz' then return pBufferField:buffer-value <> datetime-tz(pArgument).
            when 'logical' then return pBufferField:buffer-value <> logical(pArgument).
        end case.
    end method.
    
    method protected logical greater(pBufferField as handle, pArgument as character):
        case pBufferField:data-type:
            when 'character' then return pBufferField:buffer-value > pArgument.
            when 'integer' then return pBufferField:buffer-value > int(pArgument).
            when 'int64' then return pBufferField:buffer-value > int64(pArgument).
            when 'decimal' then return pBufferField:buffer-value > dec(pArgument).
            when 'date' then return pBufferField:buffer-value > date(pArgument).
            when 'datetime' then return pBufferField:buffer-value > datetime(pArgument).
            when 'datetime-tz' then return pBufferField:buffer-value > datetime-tz(pArgument).
            when 'logical' then return pBufferField:buffer-value > logical(pArgument).
        end case.
    end method.
    
    method protected logical greaterEqual(pBufferField as handle, pArgument as character):
        case pBufferField:data-type:
            when 'character' then return pBufferField:buffer-value >= pArgument.
            when 'integer' then return pBufferField:buffer-value >= int(pArgument).
            when 'int64' then return pBufferField:buffer-value >= int64(pArgument).
            when 'decimal' then return pBufferField:buffer-value >= dec(pArgument).
            when 'date' then return pBufferField:buffer-value >= date(pArgument).
            when 'datetime' then return pBufferField:buffer-value >= datetime(pArgument).
            when 'datetime-tz' then return pBufferField:buffer-value >= datetime-tz(pArgument).
            when 'logical' then return pBufferField:buffer-value >= logical(pArgument).
        end case.
    end method.
    
    method protected logical lower(pBufferField as handle, pArgument as character):
        case pBufferField:data-type:
            when 'character' then return pBufferField:buffer-value < pArgument.
            when 'integer' then return pBufferField:buffer-value < int(pArgument).
            when 'int64' then return pBufferField:buffer-value < int64(pArgument).
            when 'decimal' then return pBufferField:buffer-value < dec(pArgument).
            when 'date' then return pBufferField:buffer-value < date(pArgument).
            when 'datetime' then return pBufferField:buffer-value < datetime(pArgument).
            when 'datetime-tz' then return pBufferField:buffer-value < datetime-tz(pArgument).
            when 'logical' then return pBufferField:buffer-value < logical(pArgument).
        end case.
    end method.
    
    method protected logical lowerEqual(pBufferField as handle, pArgument as character):
        case pBufferField:data-type:
            when 'character' then return pBufferField:buffer-value <= pArgument.
            when 'integer' then return pBufferField:buffer-value <= int(pArgument).
            when 'int64' then return pBufferField:buffer-value <= int64(pArgument).
            when 'decimal' then return pBufferField:buffer-value <= dec(pArgument).
            when 'date' then return pBufferField:buffer-value <= date(pArgument).
            when 'datetime' then return pBufferField:buffer-value <= datetime(pArgument).
            when 'datetime-tz' then return pBufferField:buffer-value <= datetime-tz(pArgument).
            when 'logical' then return pBufferField:buffer-value <= logical(pArgument).
        end case.
    end method.
    
    method protected logical always(pBufferField as handle, pMatch as character):
        return true.
    end method.
    
    method public logical applyOperation(pBufferField as handle, pMatch as character):
        assertOperatorExistsByMatch(pMatch).
        define variable argument as character no-undo.
        assign argument = shiftOperator(pMatch).
        
        operatorArguments:setParameter(1, 'handle', 'input', pBufferField).
        operatorArguments:setParameter(2, 'character', 'input', argument).
        
        return this-object
            :getClass()
            :Invoke(this-object, operators.associatedMethod, operatorArguments).
    end method.
        
    method public CorrectorOperator addOperator(pMatch as character, pMethod as character):
        do on error undo, throw:
            this-object:getClass():getMethod(pMethod, operatorArguments).
            
            catch errorObject as Progress.Lang.Error:
                return error new OperatorMethodNotFound(pMethod).
            end catch.
        end.
        
        if not findOperatorByMatch(pMatch) then do:
            create operators.
        end.
        assign
            operators.operatorMatch = pMatch
            operators.operatorArgument = shiftOperator(pMatch)
            operators.associatedMethod = pMethod.
            
        return this-object.    
    end method.
    
    method private character shiftOperator(pMatch as character):
        if index(pMatch, ' ') = 0 then return ''.
        return substring(pMatch, index(pMatch, ' ') + 1).
    end method.
    
    
    method private logical assertOperatorExistsByMatch(pMatch as character):
        if not findOperatorByMatch(pMatch) then do:
            return error new OperatorMatchNotFound(pMatch).
        end.
    end method.
    
    method private logical findOperatorByMatch(pMatch as character):
        find first operators 
            where pMatch matches operators.operatorMatch
            no-error.
        return available operators.    
    end method.
end class.
