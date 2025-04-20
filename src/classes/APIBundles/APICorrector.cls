block-level on error undo, throw.
using Progress.Lang.ParameterList from propath.
using classes.APIBundles.APICorrector from propath.
using classes.APIBundles.Correction.* from propath.
using classes.APIBundles.Correction.Interfaces.* from propath.
using classes.APIBundles.Errors.* from propath.


class classes.APIBundles.APICorrector:
    define protected property correctorArgument as ParameterList no-undo get. set.
    
    define private temp-table corrections
        field targetField as character 
        field whenPhrase as character 
        field corrector as character    
        field correctorType as character
        index idxType correctorType.
    
    define private temp-table correctionType
        field correctorType as character
        field internalMethod as character
        index idxType as primary unique correctorType.
        
    constructor APICorrector():
        assign correctorArgument = new ParameterList(1).
        addCorrectionType('procedure', 'procedureCorrection').
        addCorrectionType('class', 'classCorrection').
    end constructor.
    
    method protected void procedureCorrection(input-output pBuffer as handle):
        run value(corrections.corrector) (input-output pBuffer).    
    end method.
    
    method protected void classCorrection(input-output pBuffer as handle):
        define variable correctorObject as Corrector no-undo.
        assign correctorObject = cast(Progress.Lang.Class:getClass(corrections.corrector):new(), Corrector).
        correctorObject:correct(pBuffer).
        delete object correctorObject.
    end method.
    
    method public void applyCorrections(pBuffer as handle):
        applyCorrections(pBuffer, true).
    end method.
    
    method public void applyCorrections(pBuffer as handle, pIgnoreErrors as logical):
        define variable operator as CorrectorOperator no-undo.
        define variable currentField as handle no-undo.
        assign operator = new CorrectorOperator().
        
        for each corrections:
            do on error undo, next:
                assign currentField = pBuffer:buffer-field(corrections.targetField).
                
                if not operator:applyOperation(currentField, corrections.whenPhrase) then next.
                
                find correctionType of corrections.
                correctorArgument:setParameter(1, 'handle', 'input-output', pBuffer).
                this-object
                    :getClass()
                    :getMethod(correctionType.internalMethod, correctorArgument)
                    :Invoke(correctorArgument).
                    
                catch errorObject as Progress.Lang.Error:
                    if not pIgnoreErrors then do:
                        return error errorObject.
                    end.
                end catch.
            end.
        end.
        
        delete object operator.
    end method.
    
    method public APICorrector addCorrectionType(
        pCorrectionType as character,
        pInternalMethod as character
    ):
        do on error undo, throw:
            this-object:getClass():getMethod(pInternalMethod, correctorArgument).
            
            catch errorObject as Progress.Lang.Error:
                return error new CorrectionMethodDoesNotExist(pInternalMethod).
            end catch.
        end.
        
        if not findCorrectionTypeById(pCorrectionType) then do:
            create correctionType.
        end.
        
        assign
            correctionType.correctorType = pCorrectionType
            correctionType.internalMethod = pInternalMethod.
            
        return this-object.    
    end method.
    
    method public APICorrector addCorrection(
        pTargetField as character,
        pWhen as character,
        pCorrector as character,
        pCorrectorType as character
    ):
        assertCorrectionTypeExist(pCorrectorType).
        create corrections.
        assign
            corrections.targetField = pTargetField
            corrections.whenPhrase = pWhen
            corrections.corrector = pCorrector
            corrections.correctorType = pCorrectorType.
        return this-object.        
    end method.
    
    
    method private void assertCorrectionTypeExist(pId as character):
        if not findCorrectionTypeById(pId) then do:
            return error new CorrectionTypeNotFound(pId).
        end.
    end method.
    
    method private logical findCorrectionTypeById(pId as character):
        find first correctionType
            where correctionType.correctorType = pId
            no-error.
        
        return available correctionType.    
    end method.
end class.
