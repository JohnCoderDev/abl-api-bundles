block-level on error undo, throw.
using Progress.Json.ObjectModel.* from propath.
using classes.APIBundles.Utils.JsonToBuffer from propath.

class classes.APIBundles.Utils.SJsonToBuffer:
    method public static handle parseJson(pJson as JsonObject):
        return parseJson(pJson, ?).
    end method.
    
    method public static handle parseJson(
        pJson as JsonObject, 
        pReferenceBuffer as handle
    ):
        return parseJson(pJson, pReferenceBuffer, true).
    end method.

    method public static handle parseJson(
        pJson as JsonObject, 
        pReferenceBuffer as handle,
        pTryConvertion as logical
    ):
        return parseJson(pJson, pReferenceBuffer, pTryConvertion, true).
    end method.
    
    method public static handle parseJson(
        pJson as JsonObject, 
        pReferenceBuffer as handle,
        pTryConvertion as logical,
        pIgnoreErrors as logical
    ):
        return parseJson(pJson, pReferenceBuffer, pTryConvertion, pIgnoreErrors, true).
    end method.

    method public static handle parseJson(
        pJson as JsonObject, 
        pReferenceBuffer as handle,
        pTryConvertion as logical,
        pIgnoreErrors as logical,
        pIgnoreNulls as logical
    ):
        return parseJson(pJson, pReferenceBuffer, pTryConvertion, pIgnoreErrors, pIgnoreNulls, true).
    end method.
    
    method public static handle parseJson(
        pJson as JsonObject, 
        pReferenceBuffer as handle,
        pTryConvertion as logical,
        pIgnoreErrors as logical,
        pIgnoreNulls as logical,
        pIgnoreBlanks as logical
    ):
        define variable bufferHandle as handle no-undo.
        define variable jsonTransformer as JsonToBuffer no-undo.
        
        assign jsonTransformer = new JsonToBuffer().
        if pTryConvertion then jsonTransformer:convertionOn(). else jsonTransformer:convertionOff().
        if pIgnoreErrors then jsonTransformer:ignoreErrorsOn(). else jsonTransformer:ignoreErrorsOff().
        if pIgnoreNulls then jsonTransformer:ignoreNullsOn(). else jsonTransformer:ignoreNullsOff().
        if pIgnoreBlanks then jsonTransformer:ignoreBlanksOn(). else jsonTransformer:ignoreBlanksOff().
        
        assign bufferHandle = jsonTransformer:parseJson(pJson, pReferenceBuffer).
        delete object jsonTransformer.
        return bufferHandle.
    end method.
end class.
