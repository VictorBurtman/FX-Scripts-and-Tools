-- Network entry point: create missing cache folders and copy the current path.
(
    global FXSceneContext
    local libraryPath = @"Q:\fx\fx_tools\3dsMax\00_Lib\FXSceneContext.ms"
    if not doesFileExist libraryPath do throw ("Shared FX library unavailable: " + libraryPath)
    fileIn libraryPath
    FXSceneContext.copyCurrentCachePath()
)
