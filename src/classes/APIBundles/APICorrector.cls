block-level on error undo, throw.
using Progress.Lang.ParameterList from propath.
using Progress.Json.ObjectModel.* from propath.
using classes.APIBundles.APICorrector from propath.
using classes.APIBundles.Correction.* from propath.
using classes.APIBundles.Correction.Interfaces.* from propath.
using classes.APIBundles.Errors.* from propath.
using classes.APIBundles.Utils.SJsonToBuffer from propath.


class classes.APIBundles.APICorrector:
    define protected property correctorArgument as ParameterList no-undo get. set.
    
    define private temp-table corrections
        field correctorGroup as character initial '*'
        field corrector as character    
        field correctorType as character
        field targetField as character 
        field whenPhrase as character 
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
   
    method public handle applyCorrections(pJson as JsonObject):
        return applyCorrections(pJson, true).
    end method.
    
    method public handle applyCorrections(pJson as JsonObject, pIgnoreErrors as logical):
        return applyCorrections(pJson, pIgnoreErrors, ?).
    end method.
    
    method public handle applyCorrections(pJson as JsonObject, pIgnoreErrors as logical, pGroup as character):
        return applyCorrections(pJson, pIgnoreErrors, pGroup, ?).
    end method.
   
    method public handle applyCorrections(
        pJson as JsonObject, 
        pIgnoreErrors as logical, 
        pGroup as character,
        pReferenceBuffer as handle
    ):
        define variable bufferHandle as handle no-undo.
        assign bufferHandle = SJsonToBuffer:parseJson(pJson, pReferenceBuffer).
        applyCorrections(bufferHandle, pIgnoreErrors).
        return bufferHandle.
    end method.
   
   
    method public void applyCorrections(input-output pBuffer as handle):
        applyCorrections(pBuffer, true).
    end method.
    
    method public void applyCorrections(input-output pBuffer as handle, pIgnoreErrors as logical):
        applyCorrections(pBuffer, pIgnoreErrors, ?).
    end method.
    
    method public void applyCorrections(input-output pBuffer as handle, pIgnoreErrors as logical, pGroup as character):
        define variable operator as CorrectorOperator no-undo.
        define variable currentField as handle no-undo.
        assign 
            operator = new CorrectorOperator()
            pGroup = if pGroup = ? then '*' else pGroup.
        
        for each corrections no-lock where corrections.correctorGroup matches pGroup:
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
        pCorrector as character,
        pCorrectorType as character
    ):
        return addCorrection(pCorrector, pCorrectorType, ?).
    end method.
    
    method public APICorrector addCorrection(
        pCorrector as character,
        pCorrectorType as character,
        pGroup as character
    ):
        return addCorrection(pCorrector, pCorrectorType, pGroup, '', 'always').
    end method.
    
    method public APICorrector addCorrection(
        pCorrector as character,
        pCorrectorType as character,
        pGroup as character,
        pTargetField as character,
        pWhen as character
    ):
        assertCorrectionTypeExist(pCorrectorType).
        create corrections.
        assign
            corrections.targetField = pTargetField
            corrections.whenPhrase = pWhen
            corrections.correctorGroup = if pGroup = ? then '*' else pGroup
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
