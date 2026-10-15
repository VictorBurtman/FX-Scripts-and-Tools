-- Network entry point: copy the current scene's footage output folder.
(
    global FXSceneContext
    local libraryPath = @"Q:\fx\fx_tools\3dsMax\00_Lib\FXSceneContext.ms"
    if not doesFileExist libraryPath do throw ("Shared FX library unavailable: " + libraryPath)
    fileIn libraryPath
    FXSceneContext.copyCurrentFootagesPath()
)
