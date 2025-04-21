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
        field executorMethod as character
        index idxType as primary unique correctorType.
        
    constructor APICorrector():
        assign correctorArgument = new ParameterList(1).
        correctorArgument:setParameter(1, 'handle', 'input', ?).    
        addCorrectionType('procedure', 'procedureCorrection').
        addCorrectionType('class', 'classCorrection').
    end constructor.
    
    method protected void procedureCorrection(pBuffer as handle):
        run value(corrections.corrector) (input pBuffer).    
    end method.
    
    method protected void classCorrection(pBuffer as handle):
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
   
   
    method public void applyCorrections(pBuffer as handle):
        applyCorrections(pBuffer, true).
    end method.
    
    method public void applyCorrections(pBuffer as handle, pIgnoreErrors as logical):
        applyCorrections(pBuffer, pIgnoreErrors, ?).
    end method.
    
    method public void applyCorrections(pBuffer as handle, pIgnoreErrors as logical, pGroup as character):
        define variable operator as CorrectorOperator no-undo.
        define variable currentField as handle no-undo.
        assign 
            operator = new CorrectorOperator()
            pGroup = if pGroup = ? then '*' else pGroup.
        
        
        for each corrections no-lock where pGroup matches corrections.correctorGroup:
            do on error undo, next:
                assign currentField = if corrections.targetField = ''
                    then ?
                    else pBuffer:buffer-field(corrections.targetField).
                    
                if not operator:applyOperation(currentField, corrections.whenPhrase) then next.
                
                find correctionType 
                    where correctionType.correctorType = corrections.correctorType.
                    
                correctorArgument:setParameter(1, 'handle', 'input', pBuffer).
                
                this-object
                    :getClass()
                    :Invoke(this-object, correctionType.executorMethod, correctorArgument).
                    
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
        pExecuterMethod as character
    ):
        do on error undo, throw:
            this-object
                :getClass()
                :getMethod(pExecuterMethod, correctorArgument).
            
            catch errorObject as Progress.Lang.Error:
                return error new CorrectionMethodDoesNotExist(pExecuterMethod).
            end catch.
        end.
        
        if not findCorrectionTypeById(pCorrectionType) then do:
            create correctionType.
        end.
        
        assign
            correctionType.correctorType = pCorrectionType
            correctionType.executorMethod = pExecuterMethod.
            
        return this-object.    
    end method.
    
    method public APICorrector addCorrector(
        pCorrector as character,
        pCorrectorType as character
    ):
        return addCorrector(pCorrector, pCorrectorType, ?).
    end method.
    
    method public APICorrector addCorrector(
        pCorrector as character,
        pCorrectorType as character,
        pGroup as character
    ):
        return addCorrector(pCorrector, pCorrectorType, pGroup, '', 'always').
    end method.
    
    method public APICorrector addCorrector(
        pCorrector as character,
        pCorrectorType as character,
        pTargetField as character,
        pWhen as character
    ):
        return addCorrector(pCorrector, pCorrectorType, ? , pTargetField, pWhen).
    end method.
    
    method public APICorrector addCorrector(
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
