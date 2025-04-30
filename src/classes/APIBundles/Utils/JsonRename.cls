block-level on error undo, throw.
using Progress.Json.ObjectModel.* from propath.
using classes.APIBundles.Utils.* from propath.

class classes.APIBundles.Utils.JsonRename:
    define private temp-table renames
        field sourceName as character
        field targetName as character.

    method public JsonObject applyToJson(pJson as JsonObject):
        define variable jsonResult as JsonObject no-undo.
        assign jsonResult = new JsonObject().
    end method.

    method public JsonRename addRename(pFieldSource as character, pFieldTarget as character):
        if not findRename(pFieldSource) then do:
            create renames.
        end.
        assign
            renames.sourceName = pFieldSource
            renames.targetName = pFieldTarget.
        return this-object.
    end method.

    method private logical findRename(pFieldName as character):
        find first renames
            where renames.sourceName = pFieldName
            no-error.
        return available renames.
    end method.

end class.
