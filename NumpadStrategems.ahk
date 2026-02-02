#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
#Warn All, Off
InstallKeybdHook
InstallMouseHook

; Set SendMode to Input for better key suppression in v2
SendMode("Input")

; Get script name without extension
global scriptNameNoExt := ""
SplitPath(A_ScriptFullPath, , , , &scriptNameNoExt)

; If running uncompiled, delete the appdata folder to start fresh
if (!A_IsCompiled) {
    global appDataDir := A_AppData "\" scriptNameNoExt
    if (DirExist(appDataDir)) {
        try {
            DirDelete(appDataDir, 1)  ; 1 = recursive delete
        } catch {
            ; Continue even if deletion fails
        }
    }
}

; Initialize AppData directory for resources and settings - use script name dynamically
global appDataDir := A_AppData "\" scriptNameNoExt
if (!DirExist(appDataDir)) {
    try {
        DirCreate(appDataDir)
    } catch {
        MsgBox("Failed to create AppData directory: " appDataDir)
        ExitApp
    }
}

; Set tray/taskbar icon to SOS Beacon
sosIconPath := appDataDir "\icons\Yellow\SOS Beacon.png"
if (FileExist(sosIconPath))
    TraySetIcon(sosIconPath)

; Settings file - dynamically named based on script
global settingsFile := appDataDir "\" scriptNameNoExt ".ini"
global autoCloseTimer := 0  ; Initialize to 0 instead of empty string
global shouldAutoClose := false  ; Guard flag to prevent auto-close if unchecked
global initSuccess := false  ; Track if initialization completed without errors
global assignmentsFile := appDataDir "\assignments.ini"  ; Numpad assignments file

; Create default settings file if it doesn't exist
if (!FileExist(settingsFile)) {
    ; Settings section
    IniWrite(1, settingsFile, "Settings", "AutoClose")
    IniWrite(67, settingsFile, "Settings", "KeyDelayMS")
    IniWrite(0, settingsFile, "Settings", "TestMode")
    
    ; Numpad section
    IniWrite(0, settingsFile, "Numpad", "AlwaysOnTop")
    IniWrite(1, settingsFile, "Numpad", "ArrowKeys")
    
    ; GUI section - leave empty, positions are saved when windows are moved
}

global keyDelayMS := IniRead(settingsFile, "Settings", "KeyDelayMS", 67)  ; Default 67ms (0.067 seconds)
global testMode := IniRead(settingsFile, "Settings", "TestMode", 0)

; Numpad hotkeys - only trigger when Control is held
$^Numpad0:: NumpadHotkeyPressed("0")
$^Numpad1:: NumpadHotkeyPressed("1")
$^Numpad2:: NumpadHotkeyPressed("2")
$^Numpad3:: NumpadHotkeyPressed("3")
$^Numpad4:: NumpadHotkeyPressed("4")
$^Numpad5:: NumpadHotkeyPressed("5")
$^Numpad6:: NumpadHotkeyPressed("6")
$^Numpad7:: NumpadHotkeyPressed("7")
$^Numpad8:: NumpadHotkeyPressed("8")
$^Numpad9:: NumpadHotkeyPressed("9")

$^NumpadDot:: NumpadHotkeyPressed(".")
$^NumpadDiv:: NumpadHotkeyPressed("/")
$^NumpadMult:: NumpadHotkeyPressed("*")
$^NumpadSub:: NumpadHotkeyPressed("-")
$^NumpadAdd:: NumpadHotkeyPressed("+")
$^NumpadEnter:: NumpadHotkeyPressed("Enter")

$^NumpadIns:: NumpadHotkeyPressed("0")
$^NumpadEnd:: NumpadHotkeyPressed("1")
$^NumpadDown:: NumpadHotkeyPressed("2")
$^NumpadPgDn:: NumpadHotkeyPressed("3")
$^NumpadLeft:: NumpadHotkeyPressed("4")
$^NumpadClear:: NumpadHotkeyPressed("5")
$^NumpadRight:: NumpadHotkeyPressed("6")
$^NumpadHome:: NumpadHotkeyPressed("7")
$^NumpadUp:: NumpadHotkeyPressed("8")
$^NumpadPgUp:: NumpadHotkeyPressed("9")

; Create status GUI
global statusGui := Gui("+AlwaysOnTop", "Parsing Strategems")
statusGui.SetFont("s10")
global htmlProgress := statusGui.Add("Text", "w320", "HTML Download: Checking...")
global iniProgress := statusGui.Add("Text", "w320 y+5", "DB Generation: Waiting...")
global iconProgress := statusGui.Add("Text", "w320 y+5", "Placeholder Generation: Waiting...")
global downloadProgress := statusGui.Add("Text", "w320 y+5", "Icon Download: Waiting...")
global autoCloseCheck := statusGui.Add("Checkbox", "w185 y+10", "Auto-close when complete")
autoCloseCheck.Value := IniRead(settingsFile, "Settings", "AutoClose", 1)
autoCloseCheck.OnEvent("Click", AutoCloseChanged)
global dismissBtn := statusGui.Add("Button", "w125 x+10 yp", "Dismiss")
dismissBtn.OnEvent("Click", DismissPressed)
statusGui.OnEvent("Close", StatusGuiClose)

; Restore saved position or show centered
statusX := IniRead(settingsFile, "GUI", "StatusX", "")
statusY := IniRead(settingsFile, "GUI", "StatusY", "")
if (statusX != "" && statusY != "")
    statusGui.Show("x" statusX " y" statusY)
else
    statusGui.Show()

; Monitor WM_MOVE message to save position
OnMessage(0x0003, (*) => SaveGuiPositions())

StatusGuiClose(*) {
    global statusGui, autoCloseTimer, shouldAutoClose
    
    ; Stop auto-close timer to prevent double GUI creation
    if (autoCloseTimer) {
        SetTimer(autoCloseTimer, 0)
        autoCloseTimer := 0
    }
    shouldAutoClose := false
    
    statusGui.Destroy()
    CreateNumpadGUI()
}

DismissPressed(*) {
    global statusGui, autoCloseTimer, shouldAutoClose
    
    ; Stop auto-close timer to prevent double GUI creation
    if (autoCloseTimer) {
        SetTimer(autoCloseTimer, 0)
        autoCloseTimer := 0
    }
    shouldAutoClose := false
    
    statusGui.Destroy()
    CreateNumpadGUI()
}

SaveGuiPositions() {
    global statusGui, numpadGui, settingsFile
    try {
        if (IsSet(statusGui)) {
            statusGui.GetPos(&x, &y)
            IniWrite(x, settingsFile, "GUI", "StatusX")
            IniWrite(y, settingsFile, "GUI", "StatusY")
        }
    }
    try {
        if (IsSet(numpadGui)) {
            numpadGui.GetPos(&x, &y)
            IniWrite(x, settingsFile, "GUI", "NumpadX")
            IniWrite(y, settingsFile, "GUI", "NumpadY")
        }
    }
}

OnError(ErrorObject) {
    global statusGui, iniProgress
    if (statusGui) {
        try {
            iniProgress.Text := "ERROR: " ErrorObject.What
            statusGui.Show()
        }
    }
    MsgBox(ErrorObject.What " `n`nLine: " ErrorObject.Extra,, "0x30")
    ExitApp()
}

; Don't start timer here - wait until initialization completes
; Just record the user's preference
if (autoCloseCheck.Value) {
    shouldAutoClose := true
}

AutoCloseChanged(*) {
    global autoCloseCheck, settingsFile, autoCloseTimer, shouldAutoClose, initSuccess
    IniWrite(autoCloseCheck.Value, settingsFile, "Settings", "AutoClose")
    
    ; Stop any existing timer
    if (autoCloseTimer) {
        SetTimer(autoCloseTimer, 0)
        autoCloseTimer := 0
    }
    
    shouldAutoClose := autoCloseCheck.Value
    
    ; Only start timer if init already completed successfully
    if (shouldAutoClose && initSuccess) {
        autoCloseTimer := SetTimer(DoAutoClose, 3000, 1)
    }
}

DoAutoClose() {
    global statusGui, autoCloseTimer, shouldAutoClose, initSuccess
    if (!shouldAutoClose || !initSuccess) {
        return  ; Don't close if unchecked or init failed
    }
    autoCloseTimer := 0
    shouldAutoClose := false
    statusGui.Destroy()
    CreateNumpadGUI()
}

; grab https://steamcommunity.com/sharedfiles/filedetails/?id=3161075951 and save as StrategmsRaw.html in the same folder as this script if its more than a week old
wasDownloaded := GrabHtml()

if (wasDownloaded || !FileExist(appDataDir "\Strategems.ini")) {
    ; parse the html and download icons
    ; Stop any pending auto-close timer during operations
    global autoCloseTimer
    if (autoCloseTimer) {
        autoCloseTimer.Stop()
        autoCloseTimer := 0
    }
    
    try {
        ParseStrategems()
        
        ; Create placeholder images for buttons during initialization
        try {
            iconProgress.Text := "Placeholder Generation: Creating images..."
            global placeholderImagePath := CreatePlaceholderImage()
            iconProgress.Text := "Placeholder Generation: Complete"
        } catch Error as err {
            iconProgress.Text := "Placeholder Generation: ERROR - " err.What
            downloadProgress.Text := "Line: " err.Extra
        }
        
        ; Check if all icons are already organized in color folders
        if (!AllIconsOrganized()) {
            DownloadIcons()
            DetectIconColors()
            OrganizeIconsByColor()
        } else {
            downloadProgress.Text := "Icon Download: Complete (all icons already organized)"
        }
    } catch Error as err {
        try {
            iniProgress.Text := "ERROR: " err.What
            downloadProgress.Text := "Line: " err.Extra
        }
        ; Don't return - allow script to continue and show GUI even with errors
        ; User can still use previously cached data
    }
}

; Set skipped status when using cached HTML
if (!wasDownloaded) {
    iniProgress.Text := "DB Generation: Skipped"
}

; Always check for missing icons regardless of HTML/INI state
try {
    CheckAndDownloadMissingIcons()
} catch Error as err {
    downloadProgress.Text := "Icon Check: Error - " err.What
    ; Continue anyway - missing icons shouldn't prevent GUI from showing
}

; Mark initialization as complete (even with minor errors, GUI should show)
initSuccess := true

; Now start auto-close timer if checkbox is checked
if (autoCloseCheck.Value && shouldAutoClose) {
    autoCloseTimer := SetTimer(DoAutoClose, 3000, 1)
} else {
    ; If auto-close is disabled, user needs to manually dismiss
    ; Status GUI will remain visible until they click Dismiss button
}

; functions

; parse html for tables, save as .ini files and grab icons and store them in an "icons" subfolder
; for the code part of the table, store the arrows as U L D R respectively
;save icon files as the same name as the name of the strategem
; e.g. "Orbital Strike" strategem will have an icon file named "Orbital Strike.png"
ParseStrategems() {
    global iniProgress
    iniProgress.Text := "DB Generation: Reading HTML..."
    
    local html := FileRead(appDataDir "\StrategmsRaw.html")
    if (html = "") {
        iniProgress.Text := "DB Generation: Failed to read HTML"
        return
    }

    ; Map for code images to letters
    local codeMap := Map()
    ; codeMap["https://images.steamusercontent.com/ugc/2502382292978627056/A30A455C1EF5BF8740045A7604D79FFD2AC4E32C/"] := "U"
    ; codeMap["https://images.steamusercontent.com/ugc/2502382292978626563/2BC55527EC20C05D73CBEC9F3EA3659C099D4AB8/"] := "D"
    ; codeMap["https://images.steamusercontent.com/ugc/2502382292978625471/9BB08C279B93D1ECD6E7387386FFFC22B90A8BFC/"] := "L"
    ; codeMap["https://images.steamusercontent.com/ugc/2502382292978625466/31B94090BCCDC70ADACDEBED9E684B25EA9DCD9E/"] := "R"

    codeMap["https://images.steamusercontent.com/ugc/2502382292978626563/2BC55527EC20C05D73CBEC9F3EA3659C099D4AB8/"] := "U"
    codeMap["https://images.steamusercontent.com/ugc/2502382292978627056/A30A455C1EF5BF8740045A7604D79FFD2AC4E32C/"] := "D"
    codeMap["https://images.steamusercontent.com/ugc/2502382292978625466/31B94090BCCDC70ADACDEBED9E684B25EA9DCD9E/"] := "L"
    codeMap["https://images.steamusercontent.com/ugc/2502382292978625471/9BB08C279B93D1ECD6E7387386FFFC22B90A8BFC/"] := "R"


    ; INI file
    local iniFile := appDataDir "\Strategems.ini"
    local strategemCount := 0
    global strategemData := []  ; Store for icon download
    cells := []
    local currentCategory := "General"  ; Track current section

    ; Regex to find table rows
    local rowRegex := '(?s)<div class="bb_table_tr">((?:<div class="bb_table_td">.*?</div>)*)</div>'
    local sectionRegex := '(?s)<div class="subSectionTitle">\s*(.*?)\s*</div>'
    local pos := 1
    iniProgress.Text := "DB Generation: Parsing..."
    
    ; Find all sections and their positions
    local sectionMap := Map()
    local sectionSearchPos := 1
    while (sectionSearchPos := RegExMatch(html, sectionRegex, &sectionMatch, sectionSearchPos)) {
        local sectionTitle := Trim(sectionMatch[1])
        if (sectionTitle != "" && sectionTitle != "Intro" && sectionTitle != "Overview" && sectionTitle != "Credits" && sectionTitle != "Log")
            sectionMap[sectionSearchPos] := sectionTitle
        sectionSearchPos += StrLen(sectionMatch[0])
    }
    
    while (pos := RegExMatch(html, rowRegex, &match, pos)) {
        ; Update category based on section position
        for (sectionPos, sectionTitle in sectionMap) {
            if (sectionPos < pos)
                currentCategory := sectionTitle
            else
                break
        }
        
        local row := match[1]
        
        ; Skip empty rows
        if (StrLen(Trim(row)) == 0) {
            pos += StrLen(match[0])
            continue
        }
        
        ; Skip header rows
        if (InStr(row, '<div class="bb_table_th">')) {
            pos += StrLen(match[0])
            continue
        }

        ; Extract cells
        cells := []
        local tdRegex := '(?s)<div class="bb_table_td">(.*?)</div>'
        local tdPos := 1
        local tdCount := 0
        local previousPos := 0
        while (tdPos := RegExMatch(row, tdRegex, &tdMatch, tdPos)) {
            if (tdPos == previousPos)
                break
            previousPos := tdPos
            if (StrLen(tdMatch[0]) > 0)
                cells.Push(tdMatch[1])
            tdPos += StrLen(tdMatch[0]) > 0 ? StrLen(tdMatch[0]) : 1
            tdCount++
            if (tdCount > 20)
                break
        }
        if (cells.Length < 3) {
            pos += StrLen(match[0])
            continue
        }

        ; Cell 2: Name
        local name := cells[2]

        ; Cell 1: Icon URL (extract from href in first cell - the actual icon URL is in the link, not an img tag)
        local iconUrl := ""
        if (RegExMatch(cells[1], '<a href="([^"]+)"', &iconMatch))
            iconUrl := iconMatch[1]

        ; Cell 3: Code images
        local code := ""
        local imgPos := 1
        while (imgPos := RegExMatch(cells[3], '<img src="([^"]+)"', &imgMatch, imgPos)) {
            local imgUrl := imgMatch[1]
            if (codeMap.Has(imgUrl))
                code .= codeMap[imgUrl]
            imgPos += StrLen(imgMatch[0])
        }

        ; Save to INI with category
        IniWrite(code, iniFile, name, "Code")
        IniWrite(currentCategory, iniFile, name, "Warbond")
        strategemCount++
        
        ; Store for icon download
        strategemData.Push({name: name, iconUrl: iconUrl})
        
        if (Mod(strategemCount, 10) == 0)
            iniProgress.Text := "DB Generation: " strategemCount " strategems..."

        pos += StrLen(match[0])
    }

    iniProgress.Text := "DB Generation: Complete (" strategemCount " strategems)"
    
    ; Write count to temp file
    try {
        FileDelete(appDataDir "\debug.txt")
    }
    FileAppend("Found " strategemCount " strategems`n", appDataDir "\debug.txt")
}

DownloadIcons() {
    global strategemData, downloadProgress
    
    try {
        downloadProgress.Text := "Icon Download: Creating directory..."
        local iconDir := appDataDir "\icons"
        if (!DirExist(iconDir))
            DirCreate(iconDir)
        
        ; Download arrow direction images from Steam
        local arrowDir := iconDir "\arrows"
        if (!DirExist(arrowDir))
            DirCreate(arrowDir)
        
        local arrows := Map(
            "up", "https://images.steamusercontent.com/ugc/2502382292978626563/2BC55527EC20C05D73CBEC9F3EA3659C099D4AB8/",
            "down", "https://images.steamusercontent.com/ugc/2502382292978627056/A30A455C1EF5BF8740045A7604D79FFD2AC4E32C/",
            "left", "https://images.steamusercontent.com/ugc/2502382292978625466/31B94090BCCDC70ADACDEBED9E684B25EA9DCD9E/",
            "right", "https://images.steamusercontent.com/ugc/2502382292978625471/9BB08C279B93D1ECD6E7387386FFFC22B90A8BFC/"
        )
        
        for name, url in arrows {
            local arrowPath := arrowDir "\" name ".png"
            if (!FileExist(arrowPath)) {
                downloadProgress.Text := "Icon Download: Downloading " name " arrow..."
                URLDownloadToFile(url, arrowPath)
            }
        }
        
        local total := strategemData.Length
        local downloaded := 0
        local skipped := 0
        
        downloadProgress.Text := "Icon Download: 0/" total " (0 skipped)"
        
        for index, item in strategemData {
            if (item.iconUrl == "") {
                skipped++
                continue
            }
            
            ; Clean filename
            local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
            local filePath := iconDir "\" fileName
            
            ; Check if icon exists in color folder
            local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
            local colorPath := iconDir "\" color "\" fileName
            
            ; Skip if already exists in either location
            if (FileExist(filePath) || FileExist(colorPath)) {
                skipped++
                downloadProgress.Text := "Icon Download: " downloaded "/" total " (" skipped " skipped)"
                continue
            }
            
            ; Download icon
            if (URLDownloadToFile(item.iconUrl, filePath))
                downloaded++
            else
                skipped++
                
            downloadProgress.Text := "Icon Download: " downloaded "/" total " (" skipped " skipped)"
        }
        
        downloadProgress.Text := "Icon Download: Complete (" downloaded " downloaded, " skipped " skipped)"
    } catch Error as err {
        downloadProgress.Text := "ERROR: " err.What
        throw err
    }
}

DetectIconColors() {
    global strategemData, iconProgress
    
    try {
        downloadProgress.Text := "Color Detection: Initializing GDI+..."
        
        ; Initialize GDI+
        local pToken := 0
        local si := Buffer(24, 0)
        NumPut("UInt", 1, si, 0)
        local result := DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)
        
        if (result != 0 || !pToken) {
            downloadProgress.Text := "Color Detection: Failed to initialize GDI+"
            return
        }
        
        local iconDir := appDataDir "\icons"
        local total := strategemData.Length
        local processed := 0
        
        for index, item in strategemData {
            local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_")
            local filePath := iconDir "\" fileName ".png"
            
            if (!FileExist(filePath)) {
                processed++
                continue
            }
            
            try {
                ; Detect color
                local color := DetectColor(filePath, pToken)
                
                ; Write to INI
                if (color != "")
                    IniWrite(color, appDataDir "\Strategems.ini", item.name, "Color")
            } catch {
                ; Skip icons that cause errors
            }
            
            processed++
            if (Mod(processed, 10) == 0)
                downloadProgress.Text := "Color Detection: " processed "/" total
        }
        
        downloadProgress.Text := "Color Detection: Complete (" processed " icons)"
        
        ; Shutdown GDI+
        if (pToken) {
            DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
        }
        
    } catch {
        ; Suppress GDI+ errors - color detection is optional
    }
}

DetectColor(filePath, pToken) {
    try {
        local pBitmap := 0
        
        ; Load image
        DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", filePath, "Ptr*", &pBitmap)
        if (!pBitmap)
            return "Yellow"
        
        ; Get dimensions
        local width := 0, height := 0
        DllCall("gdiplus\GdipGetImageWidth", "Ptr", pBitmap, "UInt*", &width)
        DllCall("gdiplus\GdipGetImageHeight", "Ptr", pBitmap, "UInt*", &height)
        
        if (width == 0 || height == 0) {
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
            return "Yellow"
        }
        
        ; Sample pixels - use a grid
        local stepX := Max(1, width // 10)
        local stepY := Max(1, height // 10)
        
        local greenPixels := 0
        local bluePixels := 0
        local redPixels := 0
        local yellowPixels := 0
        local totalPixels := 0
        
        ; Sample pixels across the image
        local y := 0
        while (y < height) {
            local x := 0
            while (x < width) {
                try {
                    local argb := 0
                    DllCall("gdiplus\GdipBitmapGetPixel", "Ptr", pBitmap, "Int", x, "Int", y, "UInt*", &argb)
                    
                    ; Extract RGB components
                    local alpha := (argb >> 24) & 0xFF
                    local red := (argb >> 16) & 0xFF
                    local green := (argb >> 8) & 0xFF
                    local blue := argb & 0xFF
                    
                    ; Skip transparent pixels
                    if (alpha < 128) {
                        x += stepX
                        continue
                    }
                    
                    ; Skip very dark pixels (shadows/outlines)
                    local maxComponent := Max(red, green, blue)
                    if (maxComponent < 50) {
                        x += stepX
                        continue
                    }
                    
                    ; Skip white/very light pixels
                    if (red > 200 && green > 200 && blue > 200) {
                        x += stepX
                        continue
                    }
                    
                    ; Calculate color differences from hex codes
                    ; Green: #669351 (RGB: 102, 147, 81)
                    local greenDiff := Abs(red - 102) + Abs(green - 147) + Abs(blue - 81)
                    ; Blue: #48ABC7 (RGB: 72, 171, 199)
                    local blueDiff := Abs(red - 72) + Abs(green - 171) + Abs(blue - 199)
                    ; Red: #DC7A6B (RGB: 220, 122, 107)
                    local redDiff := Abs(red - 220) + Abs(green - 122) + Abs(blue - 107)
                    
                    ; Find closest match (tolerance: 60)
                    local minDiff := Min(greenDiff, blueDiff, redDiff)
                    
                    if (minDiff < 60) {
                        if (minDiff == greenDiff) {
                            greenPixels++
                        } else if (minDiff == blueDiff) {
                            bluePixels++
                        } else if (minDiff == redDiff) {
                            redPixels++
                        }
                    } else {
                        ; No match - count as yellow
                        yellowPixels++
                    }
                    
                    totalPixels++
                } catch {
                    ; Skip pixels that cause errors
                }
                x += stepX
            }
            y += stepY
        }
        
        ; Dispose bitmap
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        
        ; Determine dominant color
        if (totalPixels == 0)
            return "Yellow"
        
        local maxCount := Max(redPixels, greenPixels, bluePixels, yellowPixels)
        
        if (maxCount == 0)
            return "Yellow"
        else if (maxCount == redPixels)
            return "Red"
        else if (maxCount == greenPixels)
            return "Green"
        else if (maxCount == bluePixels)
            return "Blue"
        else
            return "Yellow"
        
    } catch {
        return "Yellow"
    }
}

OrganizeIconsByColor() {
    global strategemData, iconProgress
    
    try {
        downloadProgress.Text := "Organizing: Creating color directories..."
        
        local iconDir := appDataDir "\icons"
        local colorDirs := ["Yellow", "Red", "Green", "Blue"]
        
        ; Create color subdirectories if they don't exist
        for colorName in colorDirs {
            local colorPath := iconDir "\" colorName
            if (!DirExist(colorPath))
                DirCreate(colorPath)
        }
        
        downloadProgress.Text := "Organizing: Copying icon files by color..."
        
        local organized := 0
        for index, item in strategemData {
            local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
            local sourceFile := iconDir "\" fileName
            
            if (!FileExist(sourceFile))
                continue
            
            ; Get color from INI
            local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
            local destDir := iconDir "\" color
            local destFile := destDir "\" fileName
            
            ; Copy file if not already there
            if (!FileExist(destFile)) {
                FileCopy(sourceFile, destFile)
            }
            
            ; Delete original to avoid duplicate copies
            if (FileExist(sourceFile)) {
                FileDelete(sourceFile)
            }
            organized++
        }
        
        downloadProgress.Text := "Organizing: Complete (" organized " organized)"
        
    } catch {
        ; Suppress errors
    }
}

AllIconsOrganized() {
    global strategemData
    
    local iconDir := appDataDir "\icons"
    local colorDirs := ["Yellow", "Red", "Green", "Blue"]
    
    ; Check if all color directories exist
    for colorName in colorDirs {
        if (!DirExist(iconDir "\" colorName))
            return false
    }
    
    ; Check if all strategems have their icons in their assigned color folders
    for index, item in strategemData {
        local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
        local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
        local colorPath := iconDir "\" color "\" fileName
        
        if (!FileExist(colorPath))
            return false
    }
    
    return true
}

CheckAndDownloadMissingIcons() {
    global downloadProgress
    
    downloadProgress.Text := "Icon Check: Verifying..."
    
    local iconDir := appDataDir "\icons"
    local colorDirs := ["Yellow", "Red", "Green", "Blue"]
    
    ; Ensure icon directory exists
    if (!DirExist(iconDir))
        DirCreate(iconDir)
    
    ; Ensure color subdirectories exist
    for colorName in colorDirs {
        local colorPath := iconDir "\" colorName
        if (!DirExist(colorPath))
            DirCreate(colorPath)
    }
    
    ; Check if INI exists
    if (!FileExist(appDataDir "\Strategems.ini")) {
        downloadProgress.Text := "Icon Check: Skipped (no INI)"
        return
    }
    
    ; Load strategem data if not already loaded
    global strategemData
    if (!IsSet(strategemData) || strategemData.Length == 0) {
        strategemData := []
        local iniFile := appDataDir "\Strategems.ini"
        local fileContent := FileRead(iniFile)
        local sectionRegex := '(?m)^\[([^\]]+)\]'
        local sectionPos := 1
        while (sectionPos := RegExMatch(fileContent, sectionRegex, &match, sectionPos)) {
            local sectionName := match[1]
            ; Skip the special __None__ strategem
            if (sectionName != "__None__") {
                strategemData.Push({name: sectionName, iconUrl: ""})
            }
            sectionPos += StrLen(match[0])
        }
    }
    
    ; Check for missing icons
    local missingIcons := []
    for index, item in strategemData {
        local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
        local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
        local colorPath := iconDir "\" color "\" fileName
        
        if (!FileExist(colorPath)) {
            missingIcons.Push(item)
        }
    }
    
    if (missingIcons.Length == 0) {
        downloadProgress.Text := "Icon Check: Complete (all icons present)"
        return
    }
    
    ; Try to download missing icons
    downloadProgress.Text := "Icon Check: " missingIcons.Length " missing, downloading..."
    local downloaded := 0
    local failed := 0
    
    ; Load HTML to get icon URLs
    local htmlFile := appDataDir "\StrategmsRaw.html"
    if (!FileExist(htmlFile)) {
        downloadProgress.Text := "Icon Check: " missingIcons.Length " missing (no HTML to download)"
        return
    }
    
    local html := FileRead(htmlFile)
    
    for index, item in missingIcons {
        ; Try to find icon URL in HTML
        local searchName := item.name
        local iconUrl := ""
        
        ; Search for the strategem in HTML and extract icon URL
        local rowRegex := '(?s)<div class="bb_table_tr">((?:<div class="bb_table_td">.*?' searchName '.*?</div>)*)</div>'
        if (RegExMatch(html, rowRegex, &match)) {
            if (RegExMatch(match[1], '<img src="([^"]+)"', &iconMatch))
                iconUrl := iconMatch[1]
        }
        
        if (iconUrl == "") {
            failed++
            continue
        }
        
        ; Download to temp location first
        local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
        local tempPath := iconDir "\" fileName
        
        if (URLDownloadToFile(iconUrl, tempPath)) {
            ; Move to color folder
            local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
            local colorPath := iconDir "\" color "\" fileName
            
            try {
                FileCopy(tempPath, colorPath, 1)
                FileDelete(tempPath)
                downloaded++
            } catch {
                failed++
            }
        } else {
            failed++
        }
        
        if (Mod(index, 5) == 0)
            downloadProgress.Text := "Icon Check: Downloading " index "/" missingIcons.Length
    }
    
    local remaining := missingIcons.Length - downloaded
    if (remaining > 0) {
        downloadProgress.Text := "Icon Check: " remaining " missing (" downloaded " downloaded, " failed " failed)"
    } else {
        downloadProgress.Text := "Icon Check: Complete (" downloaded " downloaded)"
    }
}

GrabHtml() {
    global htmlProgress
    local file := appDataDir "\StrategmsRaw.html"
    if (!FileExist(file) || A_Now - FileGetTime(file, "M") > 7 * 24 * 60 * 60) {
        htmlProgress.Text := "HTML Download: Downloading from Steam..."
        local url := "https://steamcommunity.com/sharedfiles/filedetails/?id=3161075951"
        if (!URLDownloadToFile(url, file)) {
            htmlProgress.Text := "HTML Download: Failed"
            return false
        }
        htmlProgress.Text := "HTML Download: Complete"
        return true  ; Was downloaded
    }
    htmlProgress.Text := "HTML Download: Using cached version"
    return false  ; Using cached version
}

URLDownloadToFile(url, file) {
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.SetTimeouts(10000, 10000, 10000, 10000)  ; 10 seconds timeouts
        whr.Open("GET", url)
        whr.Send()
        if (whr.Status != 200)
            return false
        
        stream := ComObject("ADODB.Stream")
        stream.Type := 1  ; Binary
        stream.Open()
        stream.Write(whr.ResponseBody)
        stream.SaveToFile(file, 2)  ; Overwrite
        stream.Close()
        return true
    } catch {
        return false
    }
}

; Create and show numpad GUI
CreateNumpadGUI() {
    global numpadGui := Gui("-AlwaysOnTop -MaximizeBox", "Stratagem Numpad")
    
    ; Close handler for numpad GUI - exit app when it closes
    numpadGui.OnEvent("Close", NumpadGuiClose)
    
    ; Set tooltip delay to 0 (no delay)
    A_TooltipDelay := 0
    
    ; Dark mode colors
    numpadGui.BackColor := "1e1e1e"
    numpadGui.SetFont("s14 cFFFFFF", "Segoe UI")
    
    ; Create placeholder image for unassigned buttons
    global placeholderImagePath := CreatePlaceholderImage()
    
    ; Create "None" strategem entry that uses the placeholder image
    if (placeholderImagePath != "") {
        IniWrite("None", appDataDir "\Strategems.ini", "__None__", "Code")
        IniWrite("None", appDataDir "\Strategems.ini", "__None__", "Warbond")
        IniWrite("None", appDataDir "\Strategems.ini", "__None__", "Color")
    }
    
    ; Assignment tracking
    global selectedStrategem := ""
    global selectedNumpadBtn := ""
    global strategemButtons := Map()
    global numpadButtons := Map()
    global numpadLabels := Map()
    global assignmentsFile  ; Reference the global, don't redefine
    
    ; Load strategems from ini
    local strategems := []
    local iniFile := appDataDir "\Strategems.ini"
    if (FileExist(iniFile)) {
        local fileContent := FileRead(iniFile)
        local sectionRegex := '(?m)^\[([^\]]+)\]'
        local sectionPos := 1
        while (sectionPos := RegExMatch(fileContent, sectionRegex, &match, sectionPos)) {
            local sectionName := match[1]
            ; Skip the special __None__ strategem
            if (sectionName != "__None__") {
                strategems.Push({name: sectionName, iconUrl: ""})
            }
            sectionPos += StrLen(match[0])
        }
    }
    
    ; Sort strategems by color priority
    strategems := SortStrategemesByColor(strategems)
    
    ; Layout dimensions
    local btnWidth := 50
    local btnHeight := 50
    local spacing := 5
    local leftX := 10
    local iconDir := appDataDir "\icons"
    local itemsPerRow := 15  ; Number of items per row (increased from 12 to 15)
    
    ; Group strategems by color
    local colorGroups := Map()
    colorGroups["Yellow"] := []
    colorGroups["Red"] := []
    colorGroups["Green"] := []
    colorGroups["Blue"] := []
    
    for item in strategems {
        local itemColor := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
        colorGroups[itemColor].Push(item)
    }
    
    ; Sort Blue group: Exosuits/Vehicles first, then Packs/Guard Dogs/Shields, then others
    if (colorGroups["Blue"].Length > 0) {
        local blueItems := colorGroups["Blue"]
        local vehicleItems := []
        local priorityItems := []
        local otherItems := []
        
        local topPriorityItems := []
        
        for item in blueItems {
            if (InStr(item.name, "Exosuit") || InStr(item.name, "Vehicule") || InStr(item.name, "Vehicle")) {
                vehicleItems.Push(item)
            } else if (InStr(item.name, "Hover") || InStr(item.name, "Jump") || InStr(item.name, "Warp")) {
                topPriorityItems.Push(item)
            } else if (InStr(item.name, "Guard Dog") || InStr(item.name, "Pack") || InStr(item.name, "Shield") || InStr(item.name, "Hellbomb")) {
                priorityItems.Push(item)
            } else {
                otherItems.Push(item)
            }
        }
        
        ; Rebuild Blue group with vehicles first, then hover/jump/warp, then shields/packs/guard dogs/hellbomb, then others
        colorGroups["Blue"] := []
        for item in vehicleItems {
            colorGroups["Blue"].Push(item)
        }
        for item in topPriorityItems {
            colorGroups["Blue"].Push(item)
        }
        for item in priorityItems {
            colorGroups["Blue"].Push(item)
        }
        for item in otherItems {
            colorGroups["Blue"].Push(item)
        }
    }
    
    ; Layout strategems in rows, grouped by color
    local x := leftX
    local y := 10
    local itemsInCurrentRow := 0
    
    ; Process each color group in order
    for colorName in ["Yellow", "Red", "Green", "Blue"] {
        local colorItems := colorGroups[colorName]
        if (colorItems.Length == 0)
            continue
        
        ; Start new row for each color group (unless at the very beginning)
        if (itemsInCurrentRow > 0) {
            x := leftX
            y += btnHeight + spacing
            itemsInCurrentRow := 0
        }
        
        ; Add items in this color group
        for item in colorItems {
            local itemName := item.name
            local itemColor := IniRead(appDataDir "\Strategems.ini", itemName, "Color", "Yellow")
            local itemIconPath := iconDir "\" itemColor "\" RegExReplace(itemName, '[<>:"/\\|?*]', "_") ".png"
            local btnOpt := "w" btnWidth " h" btnHeight " x" x " y" y
            
            if (FileExist(itemIconPath)) {
                local btn := numpadGui.Add("Pic", btnOpt " +Border", itemIconPath)
                btn.OnEvent("Click", CreateStrategemClickHandler(itemName, itemIconPath))
                strategemButtons[itemName] := btn
            } else {
                local btn := numpadGui.Add("Button", btnOpt, "?")
                btn.OnEvent("Click", CreateStrategemClickHandler(itemName, ""))
                strategemButtons[itemName] := btn
            }
            
            ; Move to next position
            x += btnWidth + spacing
            itemsInCurrentRow++
            
            ; Start new row if we've filled this one
            if (itemsInCurrentRow >= itemsPerRow) {
                x := leftX
                y += btnHeight + spacing
                itemsInCurrentRow := 0
            }
        }
    }
    
    ; Calculate numpad position based on row width (add spacing column)
    local numpadX := leftX + (itemsPerRow * (btnWidth + spacing)) + (btnWidth + spacing)
    
    ; Row 1: NumLock / * -
    global numLockBtn := numpadGui.Add("Picture", "w50 h50 x" numpadX " y10 +Border")
    global numLockLbl := numpadGui.Add("Text", "w50 h50 x" numpadX " y10 BackgroundTrans Center +0x200", "NL")
    global divideBtn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global divideLbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "/")
    global multiplyBtn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global multiplyLbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "*")
    global minusBtn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global minusLbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "-")
    
    ; Row 2: 7 8 9
    global num7Btn := numpadGui.Add("Picture", "w50 h50 x" numpadX " y+5 +Border")
    global num7Lbl := numpadGui.Add("Text", "w50 h50 x" numpadX " yp BackgroundTrans Center +0x200", "7")
    global num8Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global num8Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "8")
    global num9Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global num9Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "9")
    global plusBtn := numpadGui.Add("Picture", "w50 h104 x+5 yp +Border")
    global plusLbl := numpadGui.Add("Text", "w50 h104 xp yp BackgroundTrans Center +0x200", "+")
    
    ; Row 3: 4 5 6
    global num4Btn := numpadGui.Add("Picture", "w50 h50 x" numpadX " y120 +Border")
    global num4Lbl := numpadGui.Add("Text", "w50 h50 x" numpadX " yp BackgroundTrans Center +0x200", "4")
    global num5Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global num5Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "5")
    global num6Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global num6Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "6")
    
    ; Row 4: 1 2 3 Enter (tall)
    global num1Btn := numpadGui.Add("Picture", "w50 h50 x" numpadX " y175 +Border")
    global num1Lbl := numpadGui.Add("Text", "w50 h50 x" numpadX " yp BackgroundTrans Center +0x200", "1")
    global num2Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global num2Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "2")
    global num3Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global num3Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "3")
    global enterBtn := numpadGui.Add("Picture", "w50 h104 x+5 yp +Border")
    global enterLbl := numpadGui.Add("Text", "w50 h104 xp yp BackgroundTrans Center +0x200", "Enter")
    
    ; Row 5: 0 (double width) . 
    global num0Btn := numpadGui.Add("Picture", "w105 h50 x" numpadX " y230 +Border")
    global num0Lbl := numpadGui.Add("Text", "w105 h50 x" numpadX " yp BackgroundTrans Center +0x200", "0")
    global periodBtn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
    global periodLbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", ".")
    
    ; Store numpad buttons and labels in maps
    numpadButtons["NumLock"] := numLockBtn
    numpadLabels["NumLock"] := numLockLbl
    numpadButtons["/"] := divideBtn
    numpadLabels["/"] := divideLbl
    numpadButtons["*"] := multiplyBtn
    numpadLabels["*"] := multiplyLbl
    numpadButtons["-"] := minusBtn
    numpadLabels["-"] := minusLbl
    numpadButtons["7"] := num7Btn
    numpadLabels["7"] := num7Lbl
    numpadButtons["8"] := num8Btn
    numpadLabels["8"] := num8Lbl
    numpadButtons["9"] := num9Btn
    numpadLabels["9"] := num9Lbl
    numpadButtons["+"] := plusBtn
    numpadLabels["+"] := plusLbl
    numpadButtons["4"] := num4Btn
    numpadLabels["4"] := num4Lbl
    numpadButtons["5"] := num5Btn
    numpadLabels["5"] := num5Lbl
    numpadButtons["6"] := num6Btn
    numpadLabels["6"] := num6Lbl
    numpadButtons["1"] := num1Btn
    numpadLabels["1"] := num1Lbl
    numpadButtons["2"] := num2Btn
    numpadLabels["2"] := num2Lbl
    numpadButtons["3"] := num3Btn
    numpadLabels["3"] := num3Lbl
    numpadButtons["Enter"] := enterBtn
    numpadLabels["Enter"] := enterLbl
    numpadButtons["0"] := num0Btn
    numpadLabels["0"] := num0Lbl
    numpadButtons["."] := periodBtn
    numpadLabels["."] := periodLbl
    
    ; Attach click handlers to both pictures and labels
    for key, btn in numpadButtons {
        btn.OnEvent("Click", NumpadClicked.Bind(key))
        numpadLabels[key].OnEvent("Click", NumpadClicked.Bind(key))
        btn.OnEvent("ContextMenu", NumpadRightClicked.Bind(key))
        numpadLabels[key].OnEvent("ContextMenu", NumpadRightClicked.Bind(key))
    }
    
    ; Add checkboxes below the numpad
    global alwaysOnTopCheck := numpadGui.Add("Checkbox", "x" numpadX " y290", "Always on Top")
    global arrowKeysCheck := numpadGui.Add("Checkbox", "x" numpadX " y310", "Arrow Keys")
    
    ; Add strategem name display at bottom right (below checkboxes) - three separate controls for different font sizes
    global strategemNameDisplay_Line1 := numpadGui.Add("Text", "x" (numpadX - 50) " y345 w260 h30 Center", "")
    strategemNameDisplay_Line1.SetFont("s16")
    global strategemNameDisplay_Line2 := numpadGui.Add("Text", "x" (numpadX - 50) " y375 w260 h25 Center", "")
    strategemNameDisplay_Line2.SetFont("s12")
    global strategemNameDisplay_Line3 := numpadGui.Add("Text", "x" (numpadX - 50) " y400 w260 h25 Center", "")
    strategemNameDisplay_Line3.SetFont("s12")
    ; Container for arrow code images (up to 6 arrows at 22px each = 132px total, centered in 260px width)
    global arrowCodePics := []
    global currentArrowCode := ""  ; Track current code to prevent flickering
    local startX := numpadX + 2  ; Center in 260px space (numpadX-50 is left edge, +52 to center)
    loop 6 {
        arrowCodePics.Push(numpadGui.Add("Picture", "x" (startX + (A_Index-1)*22) " y427 w20 h20 Hidden", ""))
    }
    
    ; Load checkbox states from settings file (use global settingsFile)
    global settingsFile
    alwaysOnTopCheck.Value := IniRead(settingsFile, "Numpad", "AlwaysOnTop", 0)
    arrowKeysCheck.Value := IniRead(settingsFile, "Numpad", "ArrowKeys", 1)
    
    ; Set up event handlers
    alwaysOnTopCheck.OnEvent("Click", AlwaysOnTopChanged)
    arrowKeysCheck.OnEvent("Click", ArrowKeysChanged)
    
    ; Apply Always on Top setting
    if (alwaysOnTopCheck.Value) {
        numpadGui.Opt("+AlwaysOnTop")
    }
    
    ; Load saved assignments
    LoadAssignments()
    
    ; Start hover detection timer
    SetTimer(UpdateStrategemHoverDisplay, 50)
    
    ; Calculate window size based on strategem layout
    local numRows := Ceil(y / (btnHeight + spacing)) + 1
    local winHeight := y + btnHeight + 20  ; Current Y position + button height + padding
    local winWidth := numpadX + 250  ; strategems + numpad + padding
    
    ; Ensure minimum height for numpad controls
    if (winHeight < 450)
        winHeight := 450
    
    ; Restore saved position or show centered
    local numpadX_pos := IniRead(settingsFile, "GUI", "NumpadX", "")
    local numpadY_pos := IniRead(settingsFile, "GUI", "NumpadY", "")
    if (numpadX_pos != "" && numpadY_pos != "")
        numpadGui.Show("x" numpadX_pos " y" numpadY_pos " w" winWidth " h" winHeight)
    else
        numpadGui.Show("w" winWidth " h" winHeight)
}

AlwaysOnTopChanged(*) {
    global numpadGui, alwaysOnTopCheck, settingsFile
    IniWrite(alwaysOnTopCheck.Value, settingsFile, "Numpad", "AlwaysOnTop")
    if (alwaysOnTopCheck.Value) {
        numpadGui.Opt("+AlwaysOnTop")
    } else {
        numpadGui.Opt("-AlwaysOnTop")
    }
}

CreatePlaceholderImage() {
    local iconDir := appDataDir "\icons"
    
    ; Ensure icons directory exists
    if (!DirExist(iconDir)) {
        try {
            DirCreate(iconDir)
        } catch {
            return ""
        }
    }
    
    local placeholderPath := iconDir "\placeholder.png"
    
    ; Create standard 50x50 placeholder
    if (!FileExist(placeholderPath)) {
        CreatePlaceholderWithSize(50, 50, placeholderPath)
    }
    
    ; Create wide 105x50 placeholder for 0 button
    CreatePlaceholderWithSize(105, 50, iconDir "\placeholder_wide.png")
    
    ; Create tall 50x104 placeholder for + and Enter buttons
    CreatePlaceholderWithSize(50, 104, iconDir "\placeholder_tall.png")
    
    return placeholderPath
}

CreatePlaceholderWithSize(width, height, filePath) {
    try {
        ; Initialize GDI+
        local pToken := 0
        local si := Buffer(24, 0)
        NumPut("UInt", 1, si, 0)
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)
        
        if (!pToken) {
            return false
        }
        
        ; Create bitmap
        local pBitmap := 0
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", width, "Int", height, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pBitmap)
        
        if (!pBitmap) {
            DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
            return false
        }
        
        ; Get graphics from bitmap
        local pGraphics := 0
        DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &pGraphics)
        
        ; Clear with background color #1e1e1e (ARGB: 0xFF1E1E1E)
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0xFF1E1E1E)
        
        ; Release graphics
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
        
        ; Get PNG encoder CLSID (manually set)
        ; PNG CLSID: {557CF406-1A04-11D3-9A73-0000F81EF32E}
        local clsid := Buffer(16, 0)
        DllCall("ole32\CLSIDFromString", "WStr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", clsid)
        
        ; Save to file
        DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", filePath, "Ptr", clsid, "Ptr", 0)
        
        ; Cleanup
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
        
        return true
    } catch {
        return false
    }
}

CreateScaledStrategemIcon(strategemName, buttonKey) {
    try {
        local iconDir := appDataDir "\icons"
        local color := IniRead(appDataDir "\Strategems.ini", strategemName, "Color", "Yellow")
        local sourceIcon := iconDir "\" color "\" RegExReplace(strategemName, '[<>:"/\\|?*]', "_") ".png"
        
        ; Determine target dimensions based on button key
        local targetWidth := 50
        local targetHeight := 50
        if (buttonKey = "0") {
            targetWidth := 105
            targetHeight := 50
        } else if (buttonKey = "+" || buttonKey = "Enter") {
            targetWidth := 50
            targetHeight := 104
        }
        
        ; Check if source icon exists
        if (!FileExist(sourceIcon)) {
            return sourceIcon  ; Return original if scaling not needed
        }
        
        ; Create scaled icon path in temp folder
        local scaledIconPath := iconDir "\scaled\" RegExReplace(strategemName, '[<>:"/\\|?*]', "_") "_" targetWidth "x" targetHeight ".png"
        
        ; Create scaled folder if needed
        if (!DirExist(iconDir "\scaled")) {
            DirCreate(iconDir "\scaled")
        }
        
        ; Return existing scaled icon if already created
        if (FileExist(scaledIconPath)) {
            return scaledIconPath
        }
        
        ; Initialize GDI+
        local pToken := 0
        local si := Buffer(24, 0)
        NumPut("UInt", 1, si, 0)
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)
        
        if (!pToken) {
            return sourceIcon
        }
        
        ; Load source bitmap
        local pSourceBitmap := 0
        DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", sourceIcon, "Ptr*", &pSourceBitmap)
        
        if (!pSourceBitmap) {
            DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
            return sourceIcon
        }
        
        ; Create target bitmap with background color
        local pTargetBitmap := 0
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", targetWidth, "Int", targetHeight, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pTargetBitmap)
        
        if (!pTargetBitmap) {
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pSourceBitmap)
            DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
            return sourceIcon
        }
        
        ; Get target graphics and clear with background
        local pGraphics := 0
        DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pTargetBitmap, "Ptr*", &pGraphics)
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0xFF1E1E1E)
        
        ; Calculate letterbox dimensions (maintain aspect ratio)
        local sourceWidth := 0, sourceHeight := 0
        DllCall("gdiplus\GdipGetImageWidth", "Ptr", pSourceBitmap, "UInt*", &sourceWidth)
        DllCall("gdiplus\GdipGetImageHeight", "Ptr", pSourceBitmap, "UInt*", &sourceHeight)
        
        ; Calculate scaled dimensions
        local scaleX := (targetWidth - 4) / sourceWidth
        local scaleY := (targetHeight - 4) / sourceHeight
        local scale := Min(scaleX, scaleY)
        
        local scaledWidth := sourceWidth * scale
        local scaledHeight := sourceHeight * scale
        local offsetX := (targetWidth - scaledWidth) / 2
        local offsetY := (targetHeight - scaledHeight) / 2
        
        ; Draw scaled image centered (with dark border around it)
        DllCall("gdiplus\GdipDrawImageRectI", "Ptr", pGraphics, "Ptr", pSourceBitmap, "Int", offsetX, "Int", offsetY, "Int", scaledWidth, "Int", scaledHeight)
        
        ; Cleanup graphics
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
        
        ; Save target bitmap as PNG
        local clsid := Buffer(16, 0)
        DllCall("ole32\CLSIDFromString", "WStr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", clsid)
        DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pTargetBitmap, "WStr", scaledIconPath, "Ptr", clsid, "Ptr", 0)
        
        ; Cleanup
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pSourceBitmap)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pTargetBitmap)
        DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
        
        return scaledIconPath
    } catch {
        return sourceIcon
    }
}

ArrowKeysChanged(*) {
    global arrowKeysCheck, settingsFile
    IniWrite(arrowKeysCheck.Value, settingsFile, "Numpad", "ArrowKeys")
}

; Execute a strategem code sequence
ExecuteStrategemCode(code) {
    global arrowKeysCheck, keyDelayMS
    
    if (code == "")
        return
    
    ; Check settings
    local useArrowKeys := arrowKeysCheck.Value
    
    ; Send each direction in the code
    local codeLength := StrLen(code)
    loop codeLength {
        ; Check if Control is still held - if not, cancel execution
        if (!GetKeyState("LCtrl") && !GetKeyState("RCtrl")) {
            ; Control was released - cancel execution
            return
        }
        
        local char := SubStr(code, A_Index, 1)
        local key := ""
        
        if (useArrowKeys) {
            ; Use arrow keys
            switch char {
                case "U": key := "Up"
                case "D": key := "Down"
                case "L": key := "Left"
                case "R": key := "Right"
            }
        } else {
            ; Use WASD
            switch char {
                case "U": key := "w"
                case "D": key := "s"
                case "L": key := "a"
                case "R": key := "d"
            }
        }
        
        if (key != "") {
            Send("{Blind}{" key " Down}")
            Sleep(keyDelayMS)
            Send("{Blind}{" key " Up}")
            Sleep(keyDelayMS)
        }
    }
}

; Handle numpad key press - look up assigned strategem and execute
NumpadHotkeyPressed(buttonKey) {
    global assignmentsFile
    
    ; Check if assignments file exists
    if (!FileExist(assignmentsFile))
        return
    
    ; Get the assigned strategem for this button
    local strategemName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
    if (strategemName == "" || strategemName == "__None__")
        return
    
    ; Get the strategem code from the strategems INI
    local code := IniRead(appDataDir "\Strategems.ini", strategemName, "Code", "")
    if (code == "")
        return
    
    ; Execute the code
    ExecuteStrategemCode(code)
}

CreateStrategemClickHandler(strategemName, strategemIconPath) {
    return StrategemClicked.Bind(strategemName, strategemIconPath)
}

StrategemClicked(strategemName, iconPath, *) {
    global selectedStrategem, selectedNumpadBtn, assignmentsFile
    
    if (selectedNumpadBtn != "") {
        ; Numpad button was already selected, make assignment
        AssignStrategemToButton(strategemName, iconPath, selectedNumpadBtn)
        selectedStrategem := ""
        selectedNumpadBtn := ""
    } else {
        ; Select this strategem
        selectedStrategem := strategemName
    }
}

NumpadClicked(buttonKey, *) {
    global selectedStrategem, selectedNumpadBtn
    
    if (selectedStrategem != "") {
        ; Strategem was already selected, make assignment
        local color := IniRead(appDataDir "\Strategems.ini", selectedStrategem, "Color", "Yellow")
        local iconPath := appDataDir "\icons\" color "\" RegExReplace(selectedStrategem, '[<>:"/\\|?*]', "_") ".png"
        AssignStrategemToButton(selectedStrategem, iconPath, buttonKey)
        selectedStrategem := ""
        selectedNumpadBtn := ""
    } else {
        ; Select this numpad button
        selectedNumpadBtn := buttonKey
    }
}

NumpadRightClicked(buttonKey, *) {
    global numpadButtons, numpadLabels, assignmentsFile, placeholderImagePath
    
    ; Check if there's an assignment for this button
    if (FileExist(assignmentsFile)) {
        local strategemName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
        if (strategemName != "" && strategemName != "__None__") {
            ; Assign "None" to unassign - this shows the placeholder
            IniWrite("__None__", assignmentsFile, "Assignments", buttonKey)
            
            ; Immediately update the button display with appropriate placeholder
            local btn := numpadButtons[buttonKey]
            local iconDir := appDataDir "\icons"
            
            ; Choose appropriate placeholder based on button size
            local placeholderPath := ""
            if (buttonKey = "0") {
                ; Wide button - use placeholder_wide.png
                placeholderPath := iconDir "\placeholder_wide.png"
            } else if (buttonKey = "+" || buttonKey = "Enter") {
                ; Tall buttons - use placeholder_tall.png
                placeholderPath := iconDir "\placeholder_tall.png"
            } else {
                ; Standard button - use placeholder.png
                placeholderPath := iconDir "\placeholder.png"
            }
            
            if (placeholderPath != "" && FileExist(placeholderPath)) {
                ; Directly set placeholder without clearing
                btn.Value := placeholderPath
            }
        }
    }
}

AssignStrategemToButton(strategemName, iconPath, buttonKey) {
    global numpadButtons, numpadLabels, assignmentsFile
    
    local btn := numpadButtons[buttonKey]
    local lbl := numpadLabels[buttonKey]
    
    ; Update picture control to show strategem icon
    if (FileExist(iconPath)) {
        ; Check if button is double-sized and needs scaling
        if (buttonKey = "0" || buttonKey = "+" || buttonKey = "Enter") {
            ; Use scaled icon with letterboxing to prevent stretching
            local scaledIcon := CreateScaledStrategemIcon(strategemName, buttonKey)
            local newValue := FileExist(scaledIcon) ? scaledIcon : iconPath
            btn.Value := newValue
        } else {
            ; Standard button - use icon as-is
            btn.Value := iconPath
        }
        ; Keep label text overlaid on icon
    } else {
        ; Icon doesn't exist, show question mark
        lbl.Text := "?"
    }
    
    ; Save assignment
    IniWrite(strategemName, assignmentsFile, "Assignments", buttonKey)
}

LoadAssignments() {
    global assignmentsFile, numpadButtons, numpadLabels
    
    if (!FileExist(assignmentsFile)) {
        return
    }
    
    local iconDir := appDataDir "\icons"
    
    ; Read all assignments
    for buttonKey, btn in numpadButtons {
        local strategemName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
        if (strategemName != "") {
            ; Check if this is the "None" placeholder
            if (strategemName == "__None__") {
                ; Choose appropriate placeholder based on button size
                local placeholderPath := ""
                if (buttonKey = "0") {
                    ; Wide button - use placeholder_wide.png
                    placeholderPath := iconDir "\placeholder_wide.png"
                } else if (buttonKey = "+" || buttonKey = "Enter") {
                    ; Tall buttons - use placeholder_tall.png
                    placeholderPath := iconDir "\placeholder_tall.png"
                } else {
                    ; Standard button - use placeholder.png
                    placeholderPath := iconDir "\placeholder.png"
                }
                
                if (FileExist(placeholderPath)) {
                    btn.Value := placeholderPath
                }
            } else {
                local color := IniRead(appDataDir "\Strategems.ini", strategemName, "Color", "Yellow")
                local iconPath := appDataDir "\icons\" color "\" RegExReplace(strategemName, '[<>:"/\\|?*]', "_") ".png"
                if (FileExist(iconPath)) {
                    ; Check if button is double-sized and needs scaling
                    if (buttonKey = "0" || buttonKey = "+" || buttonKey = "Enter") {
                        ; Use scaled icon with letterboxing to prevent stretching
                        local scaledIcon := CreateScaledStrategemIcon(strategemName, buttonKey)
                        btn.Value := scaledIcon
                    } else {
                        ; Standard button - use icon as-is
                        btn.Value := iconPath
                    }
                    ; Keep label text overlaid on icon
                } else {
                    ; Icon doesn't exist, show question mark
                    numpadLabels[buttonKey].Text := "?"
                }
            }
        }
    }
}

SortStrategemesByColor(strategemArray) {
    ; Sort strategems by color priority: Yellow (1), Red (2), Green (3), Blue (4)
    local colorPriority := Map("Yellow", 1, "Red", 2, "Green", 3, "Blue", 4)
    
    ; Create sorted array
    local sorted := []
    
    ; Add in priority order
    for priority in [1, 2, 3, 4] {
        if (priority == 2) {
            ; Special handling for red strategems - put Eagle Rearm first, then other eagles, then regular
            local eagleRearm := []
            local redEagle := []
            local redRegular := []
            
            for item in strategemArray {
                local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
                if (colorPriority[color] == priority) {
                    ; Check if name is Eagle Rearm
                    if (InStr(item.name, "Eagle Rearm")) {
                        eagleRearm.Push(item)
                    } else if (InStr(item.name, "Eagle")) {
                        redEagle.Push(item)
                    } else {
                        redRegular.Push(item)
                    }
                }
            }
            
            ; Add Eagle Rearm first, then other eagles, then regular red strategems
            for item in eagleRearm {
                sorted.Push(item)
            }
            for item in redEagle {
                sorted.Push(item)
            }
            for item in redRegular {
                sorted.Push(item)
            }
        } else if (priority == 3) {
            ; Special handling for green strategems - put sentries/emplacements last
            local greenRegular := []
            local greenSentry := []
            
            for item in strategemArray {
                local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
                if (colorPriority[color] == priority) {
                    ; Check if name contains "sentry" or "emplacement" (case-insensitive)
                    if (InStr(item.name, "Sentry") || InStr(item.name, "Emplacement")) {
                        greenSentry.Push(item)
                    } else {
                        greenRegular.Push(item)
                    }
                }
            }
            
            ; Add regular green strategems first, then sentry/emplacement ones
            for item in greenRegular {
                sorted.Push(item)
            }
            for item in greenSentry {
                sorted.Push(item)
            }
        } else {
            for item in strategemArray {
                local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
                if (colorPriority[color] == priority) {
                    sorted.Push(item)
                }
            }
        }
    }
    
    return sorted
}

UpdateStrategemHoverDisplay() {
    global strategemButtons, numpadButtons, strategemNameDisplay_Line1, strategemNameDisplay_Line2, strategemNameDisplay_Line3, arrowCodePics, assignmentsFile
    
    MouseGetPos(&mouseX, &mouseY)
    
    ; Check each strategem button
    for strategemName, btn in strategemButtons {
        try {
            local btnPos := btn.GetPos(&x, &y, &w, &h)
            
            ; Check if mouse is over this button
            if (mouseX >= x && mouseX < x + w && mouseY >= y && mouseY < y + h) {
                ; Get the warbond type from INI
                local warbond := IniRead(appDataDir "\Strategems.ini", strategemName, "Warbond", "General")
                
                ; Find assignment for this strategem by checking all numpad buttons
                local assignment := ""
                if (FileExist(assignmentsFile)) {
                    ; Check each possible numpad button
                    local buttons := ["NumLock", "/", "*", "-", "7", "8", "9", "+", "4", "5", "6", "1", "2", "3", "Enter", "0", "."]
                    for buttonKey in buttons {
                        local assignedName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
                        if (assignedName = strategemName) {
                            assignment := buttonKey
                            break
                        }
                    }
                }
                
                ; Set line 1: strategem name (large font)
                strategemNameDisplay_Line1.Value := strategemName
                
                ; Set line 2: warbond if not "General", otherwise empty
                if (warbond != "General") {
                    strategemNameDisplay_Line2.Value := warbond
                } else {
                    strategemNameDisplay_Line2.Value := ""
                }
                
                ; Set line 3: assignment if exists, otherwise empty
                if (assignment != "") {
                    strategemNameDisplay_Line3.Value := "Numpad " assignment
                } else {
                    strategemNameDisplay_Line3.Value := ""
                }

                ; Set code line: arrow images
                local code := IniRead(appDataDir "\Strategems.ini", strategemName, "Code", "")
                DisplayArrowCode(code)
                
                return
            }
        } catch {
            ; Skip buttons that fail position detection
        }
    }
    
    ; Check each numpad button
    for buttonKey, btn in numpadButtons {
        try {
            local btnPos := btn.GetPos(&x, &y, &w, &h)
            
            ; Check if mouse is over this button
            if (mouseX >= x && mouseX < x + w && mouseY >= y && mouseY < y + h) {
                ; Look up what strategem is assigned to this button
                local strategemName := ""
                if (FileExist(assignmentsFile)) {
                    strategemName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
                }
                
                if (strategemName != "" && strategemName != "__None__") {
                    ; Get the warbond type from INI
                    local warbond := IniRead(appDataDir "\Strategems.ini", strategemName, "Warbond", "General")
                    
                    ; Set line 1: strategem name (large font)
                    strategemNameDisplay_Line1.Value := strategemName
                    
                    ; Set line 2: warbond if not "General", otherwise empty
                    if (warbond != "General") {
                        strategemNameDisplay_Line2.Value := warbond
                    } else {
                        strategemNameDisplay_Line2.Value := ""
                    }
                    
                    ; Set line 3: button assignment
                    strategemNameDisplay_Line3.Value := "Numpad " buttonKey

                    ; Set code line: arrow images
                    local code := IniRead(appDataDir "\Strategems.ini", strategemName, "Code", "")
                    DisplayArrowCode(code)
                } else {
                    ; No assignment for this button or unassigned
                    strategemNameDisplay_Line1.Value := "Numpad " buttonKey
                    strategemNameDisplay_Line2.Value := ""
                    strategemNameDisplay_Line3.Value := "Not assigned"
                    ClearArrowCode()
                }
                
                return
            }
        } catch {
            ; Skip buttons that fail position detection
        }
    }
    
    ; Mouse is not over any button - clear all lines
    strategemNameDisplay_Line1.Value := ""
    strategemNameDisplay_Line2.Value := ""
    strategemNameDisplay_Line3.Value := ""
    ClearArrowCode()
}

DisplayArrowCode(code) {
    global arrowCodePics, appDataDir, currentArrowCode
    
    ; Only update if code has changed (prevent flickering)
    if (code == currentArrowCode)
        return
    
    currentArrowCode := code
    
    ; Clear all arrow pictures first
    loop 6 {
        arrowCodePics[A_Index].Value := ""
        arrowCodePics[A_Index].Visible := false
    }
    
    if (code == "")
        return
    
    ; Map direction letters to arrow icon filenames
    local arrowFiles := Map()
    arrowFiles["U"] := appDataDir "\icons\arrows\up.png"
    arrowFiles["D"] := appDataDir "\icons\arrows\down.png"
    arrowFiles["L"] := appDataDir "\icons\arrows\left.png"
    arrowFiles["R"] := appDataDir "\icons\arrows\right.png"
    
    ; Get the first text box position to align with it
    global strategemNameDisplay_Line1
    local textPos := strategemNameDisplay_Line1.GetPos(&tx, &ty, &tw, &th)
    
    ; Calculate centered starting position based on actual code length
    local codeLen := Min(StrLen(code), 6)
    local totalWidth := codeLen * 22  ; 22px per arrow (20px width + 2px spacing)
    local startX := tx + (tw - totalWidth) // 2  ; Center arrows in same width as text boxes
    
    ; Display each arrow at calculated positions
    loop codeLen {
        local ch := SubStr(code, A_Index, 1)
        if (arrowFiles.Has(ch) && FileExist(arrowFiles[ch])) {
            ; Move picture to new position
            arrowCodePics[A_Index].Move(startX + (A_Index-1)*22, 427)
            ; Use *w20 *h20 prefix to force image to resize to 20x20
            arrowCodePics[A_Index].Value := "*w20 *h20 " arrowFiles[ch]
            arrowCodePics[A_Index].Visible := true
        }
    }
}

; Handler for closing the numpad GUI - exit the entire application
NumpadGuiClose(*) {
    ExitApp
}

ClearArrowCode() {
    global arrowCodePics, currentArrowCode
    
    ; Only update if not already empty (prevent flickering)
    if (currentArrowCode == "")
        return
    
    currentArrowCode := ""
    loop 6 {
        arrowCodePics[A_Index].Value := ""
        arrowCodePics[A_Index].Visible := false
    }
}



