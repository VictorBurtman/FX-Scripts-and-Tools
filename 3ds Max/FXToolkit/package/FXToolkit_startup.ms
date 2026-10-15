(
    local boot = (getDir #userScripts) + "\\FXToolkit\\bootstrap.py"
    if doesFileExist boot do
    (
        try (python.executeFile boot throwOnError:true clearUndoBuffer:false)
        catch (format "FX Toolkit startup: %\n" (getCurrentException()))
    )
)
