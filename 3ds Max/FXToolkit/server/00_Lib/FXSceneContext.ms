/* FXSceneContext 1.1 - shared, UI-independent scene context service.
   Loading this file does not create directories or change the clipboard.
   No Python dependency. Configuration is data, never evaluated as MAXScript.
*/
global FXSceneContext
global FXSC_Production
global FXSC_Context
global FXSC_Service

struct FXSC_Production
(
    name, root, footageRoot = "", pipeline = "max_legacy", options = #(),
    fn getOption key defaultValue:undefined =
    (
        for pair in options where pair[1] == toLower key do return pair[2]
        defaultValue
    )
)

struct FXSC_Context
(
    production, productionRoot, footageRoot, pipeline, episode, shot,
    department = "fx", scenePath, cachePath, configPath, options,
    fn asArray = #(production, pipeline, episode, shot, cachePath)
)

struct FXSC_Service
(
    version = "1.1.0",
    libraryDirectory,

    fn clean value = trimLeft (trimRight value " \t\r\n") " \t\r\n",

    fn matches value pattern =
        (dotNetClass "System.Text.RegularExpressions.Regex").IsMatch value pattern,

    fn normalizePath value =
    (
        local p = substituteString (clean value) "/" "\\"
        if not (matches p @"^(?:[A-Za-z]:\x5c|\x5c\x5c[^\x5c]+\x5c[^\x5c]+(?:\x5c|$))") do
            throw ("An absolute drive or UNC path is required: " + p)
        local pathClass = dotNetClass "System.IO.Path"
        p = pathClass.GetFullPath p
        local volume = pathClass.GetPathRoot p
        while p.count > volume.count and (substring p p.count 1) == "\\" do
            p = substring p 1 (p.count - 1)
        p
    ),

    fn withSeparator path =
        if (substring path path.count 1) == "\\" then path else path + "\\",

    fn underRoot path root =
    (
        local prefix = toLower (withSeparator root)
        path.count > prefix.count and (substring (toLower path) 1 prefix.count) == prefix
    ),

    fn readRegistry configPath visited:#() =
    (
        local config = normalizePath configPath
        if findItem visited (toLower config) != 0 do throw ("Registry source cycle: " + config)
        if visited.count >= 8 do throw "Too many chained registry sources."
        if not doesFileExist config do throw ("Production registry unavailable: " + config)
        local lines = (dotNetClass "System.IO.File").ReadAllLines config
        local productions = #()
        local source = undefined
        local lineNumber = 0
        for rawLine in lines do
        (
            lineNumber += 1
            local line = clean rawLine
            if line.count == 0 or (substring line 1 1) == "#" do continue
            if matchPattern line pattern:"source:*" ignoreCase:true then
            (
                if source != undefined do throw ("Multiple registry sources in " + config)
                source = clean (substring line 8 -1)
                if source == "" do throw ("Empty registry source in " + config)
            )
            else if matchPattern line pattern:"prod:*" ignoreCase:true then
            (
                local fields = filterString (substring line 6 -1) "|" splitEmptyTokens:true
                if fields.count == 0 do throw ("Missing production name/root at " + config + ":" + (lineNumber as string))
                local label = clean fields[1]
                local positional = #()
                local options = #()
                local pipeline = "max_legacy"
                for i = 2 to fields.count do
                (
                    local field = clean fields[i]
                    local equal = findString field "="
                    if equal == undefined then append positional field
                    else
                    (
                        local key = toLower (clean (substring field 1 (equal - 1)))
                        local value = clean (substring field (equal + 1) -1)
                        for pair in options where pair[1] == key do
                            throw ("Duplicate option " + key + " in production " + label)
                        append options #(key, value)
                        if key == "pipeline" do pipeline = toLower value
                    )
                )
                if label == "" or positional.count < 1 or positional[1] == "" do
                    throw ("Missing production name/root at " + config + ":" + (lineNumber as string))
                local root = normalizePath positional[1]
                local footage = if positional.count >= 2 and positional[2] != "" then normalizePath positional[2] else ""
                if positional.count > 2 do throw ("Too many path fields for production " + label)
                for production in productions do
                (
                    if toLower production.name == toLower label do throw ("Duplicate production name: " + label)
                    if toLower production.root == toLower root do throw ("Duplicate production root: " + root)
                )
                append productions (FXSC_Production name:label root:root footageRoot:footage pipeline:pipeline options:options)
            )
            -- Other PrepFX settings are intentionally ignored.
        )
        if source != undefined then
        (
            if productions.count > 0 do throw "Use either source: or prod: records in a registry, not both."
            if not (dotNetClass "System.IO.Path").IsPathRooted source do
                source = (getFilenamePath config) + source
            readRegistry source visited:(visited + #(toLower config))
        )
        else
        (
            if productions.count == 0 do throw ("No productions found in " + config)
            #(productions, config)
        )
    ),

    fn loadProductions configPath:undefined =
    (
        if configPath == undefined do configPath = libraryDirectory + "productions.cfg"
        (readRegistry configPath)[1]
    ),

    fn buildCachePath root pipeline episode shot =
    (
        case pipeline of
        (
            "max_legacy": (withSeparator root) + episode + "\\fx\\3D_Sources\\" + shot
            "maya_shots": (withSeparator root) + episode + "\\" + shot + "\\fx\\wip\\3d\\datas"
            default: throw ("Unsupported production pipeline: " + pipeline)
        )
    ),

    fn resolve scenePath configPath:undefined =
    (
        if scenePath == undefined or (clean scenePath) == "" do
            throw "Save the scene in a configured production before requesting its cache path."
        local scene = normalizePath scenePath
        if toLower (getFilenameType scene) != ".max" do throw "Expected a full .max scene file path."
        if configPath == undefined do configPath = libraryDirectory + "productions.cfg"
        local registry = readRegistry configPath
        local selected = undefined
        -- The most specific root wins; a sibling with the same prefix cannot match.
        for production in registry[1] where underRoot scene production.root do
            if selected == undefined or production.root.count > selected.root.count do selected = production
        if selected == undefined do throw ("Scene is outside the configured production roots: " + scene)
        local relativePath = substring scene ((withSeparator selected.root).count + 1) -1
        local parts = filterString relativePath "\\"
        if parts.count < 2 or not (matches parts[1] @"(?i)^e[0-9]+$") do
            throw "The episode must be an e<number> directory immediately below the production root."
        local episode = toLower parts[1]
        local shot = undefined
        case selected.pipeline of
        (
            "maya_shots":
            (
                if parts.count < 3 or not (matches parts[2] @"(?i)^s[0-9]+[a-z0-9]*$") do
                    throw "Maya shots require <root>\\<episode>\\<shot>\\...\\scene.max."
                shot = toLower parts[2]
            )
            "max_legacy":
            (
                for i = 2 to (parts.count - 1) where matches parts[i] @"(?i)^s[0-9]+[a-z0-9]*$" do
                (
                    local candidate = toLower parts[i]
                    if shot != undefined and shot != candidate do throw "Ambiguous shot directories in the scene path."
                    shot = candidate
                )
            )
            default: throw ("Unsupported production pipeline: " + selected.pipeline)
        )
        -- Support PrepFX's e313sfx0010, animation/layout/render names, and
        -- Maya e204s0940_fx_v001. A recognized name must agree with folders.
        local regex = dotNetObject "System.Text.RegularExpressions.Regex" @"(?i)(?<![a-z0-9])(e[0-9]+)s(?:fx|a|l|r)?([0-9]+[a-z0-9]*)(?=$|[^a-z0-9])"
        local found = regex.Matches (getFilenameFile scene)
        for i = 0 to (found.Count - 1) do
        (
            local item = found.Item[i]
            local nameEpisode = toLower item.Groups.Item[1].Value
            local nameShot = "s" + toLower item.Groups.Item[2].Value
            if nameEpisode != episode do throw "The scene filename and episode directory disagree."
            if shot != undefined and shot != nameShot do throw "The scene filename and shot directory disagree."
            shot = nameShot
        )
        if shot == undefined do throw "Cannot identify the shot from the directories or scene filename."
        local cache = buildCachePath selected.root selected.pipeline episode shot
        FXSC_Context production:selected.name productionRoot:selected.root footageRoot:selected.footageRoot \
            pipeline:selected.pipeline episode:episode shot:shot scenePath:scene cachePath:cache \
            configPath:registry[2] options:selected.options
    ),

    fn current configPath:undefined =
    (
        if maxFilePath == "" or maxFileName == "" do throw "Save the scene before requesting its cache path."
        resolve (maxFilePath + maxFileName) configPath:configPath
    ),

    fn ensureCacheDirectory context =
    (
        local directories = dotNetClass "System.IO.Directory"
        local episodeRoot = (withSeparator context.productionRoot) + context.episode
        -- Never fabricate a missing production/episode when a drive is offline.
        if not (directories.Exists context.productionRoot) do
            throw ("Production root unavailable: " + context.productionRoot)
        if not (directories.Exists episodeRoot) do throw ("Episode folder unavailable: " + episodeRoot)
        if context.pipeline == "maya_shots" and not (directories.Exists (episodeRoot + "\\" + context.shot)) do
            throw "The Maya shot directory is unavailable."
        directories.CreateDirectory context.cachePath
        if not (directories.Exists context.cachePath) do throw ("Cannot create cache directory: " + context.cachePath)
        context.cachePath
    ),

    fn getCachePath scenePath configPath:undefined create:false =
    (
        local context = resolve scenePath configPath:configPath
        if create do ensureCacheDirectory context
        context.cachePath
    ),

    fn buildFootagesPath context =
    (
        -- Return the shot footage folder; Maya versions live below this path.
        local root = if context.footageRoot == "" then context.productionRoot else context.footageRoot
        local base = (withSeparator root) + context.episode + "\\"
        case context.pipeline of
        (
            "max_legacy":
                base + "rendu-compo\\" + context.shot + "\\" + context.episode + "sr" + (substring context.shot 2 -1) + "_FX"
            "maya_shots":
                base + context.shot + "\\fx\\wip\\fx3d"
            default: throw ("Unsupported production pipeline: " + context.pipeline)
        )
    ),

    fn getFootagesPath scenePath configPath:undefined =
        buildFootagesPath (resolve scenePath configPath:configPath),

    fn copyCurrentFootagesPath configPath:undefined =
    (
        local path = buildFootagesPath (current configPath:configPath)
        if not (setClipboardText path) do throw "Cannot write to the clipboard."
        path
    ),

    fn copyCachePath scenePath configPath:undefined =
    (
        local context = resolve scenePath configPath:configPath
        ensureCacheDirectory context
        if not (setClipboardText context.cachePath) do throw "Cannot write to the clipboard."
        context.cachePath
    ),

    fn copyCurrentCachePath configPath:undefined =
    (
        local context = current configPath:configPath
        ensureCacheDirectory context
        if not (setClipboardText context.cachePath) do throw "Cannot write to the clipboard."
        context.cachePath
    )
)

FXSceneContext = FXSC_Service libraryDirectory:(getFilenamePath (getSourceFileName()))
