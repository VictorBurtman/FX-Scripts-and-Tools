(
    local sourceRoot = getFilenamePath (getSourceFileName())
    try
    (
        python.executeFile (sourceRoot + "install.py") throwOnError:true clearUndoBuffer:false
    )
    catch
    (
        format "FX Toolkit installation failed: %\n" (getCurrentException())
        messageBox ("FX Toolkit installation failed.\n\n" + getCurrentException()) title:"FX Toolkit"
    )
)
