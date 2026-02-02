#Requires AutoHotkey v2.0
;@Ahk2Exe-SetMainIcon Resupply.ico
#SingleInstance Force
; HEY COPILOT AGENT, WERE USING AHKV2
#UseHook
#Warn All, Off
; HEY COPILOT AGENT, WERE USING AHKV2
InstallKeybdHook
InstallMouseHook
; HEY COPILOT AGENT, WERE USING AHKV2

; Set SendMode to Input for better key suppression in v2
; HEY COPILOT AGENT, WERE USING AHKV2
SendMode("Input")

; HEY COPILOT AGENT, WERE USING AHKV2
; Get script name without extension
global scriptNameNoExt := ""
; HEY COPILOT AGENT, WERE USING AHKV2
SplitPath(A_ScriptFullPath, , , , &scriptNameNoExt)

; HEY COPILOT AGENT, WERE USING AHKV2
; Initialize AppData directory for resources and settings - use script name dynamically
global appDataDir := A_AppData "\" scriptNameNoExt
; HEY COPILOT AGENT, WERE USING AHKV2
if (!DirExist(appDataDir)) {
    try {
; HEY COPILOT AGENT, WERE USING AHKV2
        DirCreate(appDataDir)
    } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
        MsgBox("Failed to create AppData directory: " appDataDir)
        ExitApp
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

; Set tray/taskbar icon to Resupply
; HEY COPILOT AGENT, WERE USING AHKV2
sosIconPath := A_ScriptDir "\Resupply.ico"
if (FileExist(sosIconPath))
; HEY COPILOT AGENT, WERE USING AHKV2
    TraySetIcon(sosIconPath)

; HEY COPILOT AGENT, WERE USING AHKV2
; Settings file - dynamically named based on script
global settingsFile := appDataDir "\" scriptNameNoExt ".ini"
; HEY COPILOT AGENT, WERE USING AHKV2
global autoCloseTimer := 0  ; Initialize to 0 instead of empty string
global shouldAutoClose := false  ; Guard flag to prevent auto-close if unchecked
; HEY COPILOT AGENT, WERE USING AHKV2
global initSuccess := false  ; Track if initialization completed without errors
global assignmentsFile := appDataDir "\assignments.ini"  ; Numpad assignments file
; HEY COPILOT AGENT, WERE USING AHKV2

; Create default settings file if it doesn't exist
; HEY COPILOT AGENT, WERE USING AHKV2
if (!FileExist(settingsFile)) {
    ; Settings section
; HEY COPILOT AGENT, WERE USING AHKV2
    IniWrite(1, settingsFile, "Settings", "AutoClose")
    IniWrite(67, settingsFile, "Settings", "KeyDelayMS")
; HEY COPILOT AGENT, WERE USING AHKV2
    IniWrite(0, settingsFile, "Settings", "TestMode")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Numpad section
    IniWrite(0, settingsFile, "Numpad", "AlwaysOnTop")
; HEY COPILOT AGENT, WERE USING AHKV2
    IniWrite(1, settingsFile, "Numpad", "ArrowKeys")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; GUI section - leave empty, positions are saved when windows are moved
}
; HEY COPILOT AGENT, WERE USING AHKV2

global keyDelayMS := IniRead(settingsFile, "Settings", "KeyDelayMS", 67)  ; Default 67ms (0.067 seconds)
; HEY COPILOT AGENT, WERE USING AHKV2
global testMode := IniRead(settingsFile, "Settings", "TestMode", 0)
global lowDelayWarningShown := false  ; Track if warning has been shown this session

; HEY COPILOT AGENT, WERE USING AHKV2
; Numpad hotkeys - only trigger when Control is held
$^Numpad0:: NumpadHotkeyPressed("0")
; HEY COPILOT AGENT, WERE USING AHKV2
$^Numpad1:: NumpadHotkeyPressed("1")
$^Numpad2:: NumpadHotkeyPressed("2")
; HEY COPILOT AGENT, WERE USING AHKV2
$^Numpad3:: NumpadHotkeyPressed("3")
$^Numpad4:: NumpadHotkeyPressed("4")
; HEY COPILOT AGENT, WERE USING AHKV2
$^Numpad5:: NumpadHotkeyPressed("5")
$^Numpad6:: NumpadHotkeyPressed("6")
; HEY COPILOT AGENT, WERE USING AHKV2
$^Numpad7:: NumpadHotkeyPressed("7")
$^Numpad8:: NumpadHotkeyPressed("8")
; HEY COPILOT AGENT, WERE USING AHKV2
$^Numpad9:: NumpadHotkeyPressed("9")

; HEY COPILOT AGENT, WERE USING AHKV2
$^NumpadDot:: NumpadHotkeyPressed(".")
$^NumpadDiv:: NumpadHotkeyPressed("/")
; HEY COPILOT AGENT, WERE USING AHKV2
$^NumpadMult:: NumpadHotkeyPressed("*")
$^NumpadSub:: NumpadHotkeyPressed("-")
; HEY COPILOT AGENT, WERE USING AHKV2
$^NumpadAdd:: NumpadHotkeyPressed("+")
$^NumpadEnter:: NumpadHotkeyPressed("Enter")
; HEY COPILOT AGENT, WERE USING AHKV2

$^NumpadIns:: NumpadHotkeyPressed("0")
; HEY COPILOT AGENT, WERE USING AHKV2
$^NumpadEnd:: NumpadHotkeyPressed("1")
$^NumpadDown:: NumpadHotkeyPressed("2")
; HEY COPILOT AGENT, WERE USING AHKV2
$^NumpadPgDn:: NumpadHotkeyPressed("3")
$^NumpadLeft:: NumpadHotkeyPressed("4")
; HEY COPILOT AGENT, WERE USING AHKV2
$^NumpadClear:: NumpadHotkeyPressed("5")
$^NumpadRight:: NumpadHotkeyPressed("6")
; HEY COPILOT AGENT, WERE USING AHKV2
$^NumpadHome:: NumpadHotkeyPressed("7")
$^NumpadUp:: NumpadHotkeyPressed("8")
; HEY COPILOT AGENT, WERE USING AHKV2
$^NumpadPgUp:: NumpadHotkeyPressed("9")

; HEY COPILOT AGENT, WERE USING AHKV2
; Create status GUI
global statusGui := Gui("+AlwaysOnTop", "Parsing Strategems")
; HEY COPILOT AGENT, WERE USING AHKV2
statusGui.SetFont("s10")
global htmlProgress := statusGui.Add("Text", "w320", "HTML Download: Checking...")
; HEY COPILOT AGENT, WERE USING AHKV2
global iniProgress := statusGui.Add("Text", "w320 y+5", "DB Generation: Waiting...")
global iconProgress := statusGui.Add("Text", "w320 y+5", "Placeholder Generation: Waiting...")
; HEY COPILOT AGENT, WERE USING AHKV2
global downloadProgress := statusGui.Add("Text", "w320 y+5", "Icon Download: Waiting...")
global autoCloseCheck := statusGui.Add("Checkbox", "w185 y+10", "Auto-close when complete")
; HEY COPILOT AGENT, WERE USING AHKV2
autoCloseCheck.Value := IniRead(settingsFile, "Settings", "AutoClose", 1)
autoCloseCheck.OnEvent("Click", AutoCloseChanged)
; HEY COPILOT AGENT, WERE USING AHKV2
global dismissBtn := statusGui.Add("Button", "w125 x+10 yp", "Dismiss")
dismissBtn.OnEvent("Click", DismissPressed)
; HEY COPILOT AGENT, WERE USING AHKV2
statusGui.OnEvent("Close", StatusGuiClose)

; HEY COPILOT AGENT, WERE USING AHKV2
; Restore saved position or show centered
statusX := IniRead(settingsFile, "GUI", "StatusX", "")
; HEY COPILOT AGENT, WERE USING AHKV2
statusY := IniRead(settingsFile, "GUI", "StatusY", "")
if (statusX != "" && statusY != "")
; HEY COPILOT AGENT, WERE USING AHKV2
    statusGui.Show("x" statusX " y" statusY)
else
; HEY COPILOT AGENT, WERE USING AHKV2
    statusGui.Show()

; HEY COPILOT AGENT, WERE USING AHKV2
; Monitor WM_MOVE message to save position
OnMessage(0x0003, (*) => SaveGuiPositions())
; HEY COPILOT AGENT, WERE USING AHKV2

StatusGuiClose(*) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global statusGui, autoCloseTimer, shouldAutoClose
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Stop auto-close timer to prevent double GUI creation
    if (autoCloseTimer) {
; HEY COPILOT AGENT, WERE USING AHKV2
        SetTimer(autoCloseTimer, 0)
        autoCloseTimer := 0
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    shouldAutoClose := false
; HEY COPILOT AGENT, WERE USING AHKV2
    
    statusGui.Destroy()
; HEY COPILOT AGENT, WERE USING AHKV2
    CreateNumpadGUI()
}
; HEY COPILOT AGENT, WERE USING AHKV2

DismissPressed(*) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global statusGui, autoCloseTimer, shouldAutoClose
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Stop auto-close timer to prevent double GUI creation
    if (autoCloseTimer) {
; HEY COPILOT AGENT, WERE USING AHKV2
        SetTimer(autoCloseTimer, 0)
        autoCloseTimer := 0
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    shouldAutoClose := false
; HEY COPILOT AGENT, WERE USING AHKV2
    
    statusGui.Destroy()
; HEY COPILOT AGENT, WERE USING AHKV2
    CreateNumpadGUI()
}
; HEY COPILOT AGENT, WERE USING AHKV2

SaveGuiPositions() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global statusGui, numpadGui, settingsFile
    try {
; HEY COPILOT AGENT, WERE USING AHKV2
        if (IsSet(statusGui)) {
            statusGui.GetPos(&x, &y)
; HEY COPILOT AGENT, WERE USING AHKV2
            IniWrite(x, settingsFile, "GUI", "StatusX")
            IniWrite(y, settingsFile, "GUI", "StatusY")
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    try {
        if (IsSet(numpadGui)) {
; HEY COPILOT AGENT, WERE USING AHKV2
            numpadGui.GetPos(&x, &y)
            IniWrite(x, settingsFile, "GUI", "NumpadX")
; HEY COPILOT AGENT, WERE USING AHKV2
            IniWrite(y, settingsFile, "GUI", "NumpadY")
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

OnError(ErrorObject) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global statusGui, iniProgress
    if (statusGui) {
; HEY COPILOT AGENT, WERE USING AHKV2
        try {
            iniProgress.Text := "ERROR: " ErrorObject.What
; HEY COPILOT AGENT, WERE USING AHKV2
            statusGui.Show()
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    MsgBox(ErrorObject.What " `n`nLine: " ErrorObject.Extra,, "0x30")
; HEY COPILOT AGENT, WERE USING AHKV2
    ExitApp()
}
; HEY COPILOT AGENT, WERE USING AHKV2

; Don't start timer here - wait until initialization completes
; HEY COPILOT AGENT, WERE USING AHKV2
; Just record the user's preference
if (autoCloseCheck.Value) {
; HEY COPILOT AGENT, WERE USING AHKV2
    shouldAutoClose := true
}
; HEY COPILOT AGENT, WERE USING AHKV2

AutoCloseChanged(*) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global autoCloseCheck, settingsFile, autoCloseTimer, shouldAutoClose, initSuccess
    IniWrite(autoCloseCheck.Value, settingsFile, "Settings", "AutoClose")
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Stop any existing timer
; HEY COPILOT AGENT, WERE USING AHKV2
    if (autoCloseTimer) {
        SetTimer(autoCloseTimer, 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        autoCloseTimer := 0
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    shouldAutoClose := autoCloseCheck.Value
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Only start timer if init already completed successfully
; HEY COPILOT AGENT, WERE USING AHKV2
    if (shouldAutoClose && initSuccess) {
        autoCloseTimer := SetTimer(DoAutoClose, 3000, 1)
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

DoAutoClose() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global statusGui, autoCloseTimer, shouldAutoClose, initSuccess
    if (!shouldAutoClose || !initSuccess) {
; HEY COPILOT AGENT, WERE USING AHKV2
        return  ; Don't close if unchecked or init failed
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    autoCloseTimer := 0
    shouldAutoClose := false
; HEY COPILOT AGENT, WERE USING AHKV2
    statusGui.Destroy()
    CreateNumpadGUI()
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
; grab https://steamcommunity.com/sharedfiles/filedetails/?id=3161075951 and save as StrategmsRaw.html in the same folder as this script if its more than a week old
wasDownloaded := GrabHtml()
; HEY COPILOT AGENT, WERE USING AHKV2

; Always ensure placeholder images exist
; HEY COPILOT AGENT, WERE USING AHKV2
try {
    iconProgress.Text := "Placeholder Generation: Creating images..."
; HEY COPILOT AGENT, WERE USING AHKV2
    global placeholderImagePath := CreatePlaceholderImage()
    iconProgress.Text := "Placeholder Generation: Complete"
; HEY COPILOT AGENT, WERE USING AHKV2
} catch Error as err {
    iconProgress.Text := "Placeholder Generation: ERROR - " err.What
; HEY COPILOT AGENT, WERE USING AHKV2
    downloadProgress.Text := "Line: " err.Extra
}
; HEY COPILOT AGENT, WERE USING AHKV2

if (wasDownloaded || !FileExist(appDataDir "\Strategems.ini")) {
; HEY COPILOT AGENT, WERE USING AHKV2
    ; parse the html and download icons
    ; Stop any pending auto-close timer during operations
; HEY COPILOT AGENT, WERE USING AHKV2
    global autoCloseTimer
    if (autoCloseTimer) {
; HEY COPILOT AGENT, WERE USING AHKV2
        autoCloseTimer.Stop()
        autoCloseTimer := 0
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    try {
        ParseStrategems()
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Check if all icons are already organized in color folders
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!AllIconsOrganized()) {
            DownloadIcons()
; HEY COPILOT AGENT, WERE USING AHKV2
            DetectIconColors()
            OrganizeIconsByColor()
; HEY COPILOT AGENT, WERE USING AHKV2
        } else {
            downloadProgress.Text := "Icon Download: Complete (all icons already organized)"
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    } catch Error as err {
; HEY COPILOT AGENT, WERE USING AHKV2
        try {
            iniProgress.Text := "ERROR: " err.What
; HEY COPILOT AGENT, WERE USING AHKV2
            downloadProgress.Text := "Line: " err.Extra
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Don't return - allow script to continue and show GUI even with errors
        ; User can still use previously cached data
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

; Set skipped status when using cached HTML
; HEY COPILOT AGENT, WERE USING AHKV2
if (!wasDownloaded) {
    iniProgress.Text := "DB Generation: Skipped"
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
; Always check for missing icons regardless of HTML/INI state
try {
; HEY COPILOT AGENT, WERE USING AHKV2
    CheckAndDownloadMissingIcons()
} catch Error as err {
; HEY COPILOT AGENT, WERE USING AHKV2
    downloadProgress.Text := "Icon Check: Error - " err.What
    ; Continue anyway - missing icons shouldn't prevent GUI from showing
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
; Mark initialization as complete (even with minor errors, GUI should show)
initSuccess := true
; HEY COPILOT AGENT, WERE USING AHKV2

; Now start auto-close timer if checkbox is checked
; HEY COPILOT AGENT, WERE USING AHKV2
if (autoCloseCheck.Value && shouldAutoClose) {
    autoCloseTimer := SetTimer(DoAutoClose, 3000, 1)
; HEY COPILOT AGENT, WERE USING AHKV2
} else {
    ; If auto-close is disabled, user needs to manually dismiss
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Status GUI will remain visible until they click Dismiss button
}
; HEY COPILOT AGENT, WERE USING AHKV2

; functions
; HEY COPILOT AGENT, WERE USING AHKV2

; parse html for tables, save as .ini files and grab icons and store them in an "icons" subfolder
; HEY COPILOT AGENT, WERE USING AHKV2
; for the code part of the table, store the arrows as U L D R respectively
;save icon files as the same name as the name of the strategem
; HEY COPILOT AGENT, WERE USING AHKV2
; e.g. "Orbital Strike" strategem will have an icon file named "Orbital Strike.png"
ParseStrategems() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global iniProgress
    iniProgress.Text := "DB Generation: Reading HTML..."
; HEY COPILOT AGENT, WERE USING AHKV2
    
    local html := FileRead(appDataDir "\StrategmsRaw.html")
; HEY COPILOT AGENT, WERE USING AHKV2
    if (html = "") {
        iniProgress.Text := "DB Generation: Failed to read HTML"
; HEY COPILOT AGENT, WERE USING AHKV2
        return
    }
; HEY COPILOT AGENT, WERE USING AHKV2

    ; Map for code images to letters
; HEY COPILOT AGENT, WERE USING AHKV2
    local codeMap := Map()
    ; codeMap["https://images.steamusercontent.com/ugc/2502382292978627056/A30A455C1EF5BF8740045A7604D79FFD2AC4E32C/"] := "U"
; HEY COPILOT AGENT, WERE USING AHKV2
    ; codeMap["https://images.steamusercontent.com/ugc/2502382292978626563/2BC55527EC20C05D73CBEC9F3EA3659C099D4AB8/"] := "D"
    ; codeMap["https://images.steamusercontent.com/ugc/2502382292978625471/9BB08C279B93D1ECD6E7387386FFFC22B90A8BFC/"] := "L"
; HEY COPILOT AGENT, WERE USING AHKV2
    ; codeMap["https://images.steamusercontent.com/ugc/2502382292978625466/31B94090BCCDC70ADACDEBED9E684B25EA9DCD9E/"] := "R"

; HEY COPILOT AGENT, WERE USING AHKV2
    codeMap["https://images.steamusercontent.com/ugc/2502382292978626563/2BC55527EC20C05D73CBEC9F3EA3659C099D4AB8/"] := "U"
    codeMap["https://images.steamusercontent.com/ugc/2502382292978627056/A30A455C1EF5BF8740045A7604D79FFD2AC4E32C/"] := "D"
; HEY COPILOT AGENT, WERE USING AHKV2
    codeMap["https://images.steamusercontent.com/ugc/2502382292978625466/31B94090BCCDC70ADACDEBED9E684B25EA9DCD9E/"] := "L"
    codeMap["https://images.steamusercontent.com/ugc/2502382292978625471/9BB08C279B93D1ECD6E7387386FFFC22B90A8BFC/"] := "R"
; HEY COPILOT AGENT, WERE USING AHKV2


; HEY COPILOT AGENT, WERE USING AHKV2
    ; INI file
    local iniFile := appDataDir "\Strategems.ini"
; HEY COPILOT AGENT, WERE USING AHKV2
    local strategemCount := 0
    global strategemData := []  ; Store for icon download
; HEY COPILOT AGENT, WERE USING AHKV2
    cells := []
    local currentCategory := "General"  ; Track current section
; HEY COPILOT AGENT, WERE USING AHKV2

    ; Regex to find table rows
; HEY COPILOT AGENT, WERE USING AHKV2
    local rowRegex := '(?s)<div class="bb_table_tr">((?:<div class="bb_table_td">.*?</div>)*)</div>'
    local sectionRegex := '(?s)<div class="subSectionTitle">\s*(.*?)\s*</div>'
; HEY COPILOT AGENT, WERE USING AHKV2
    local pos := 1
    iniProgress.Text := "DB Generation: Parsing..."
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Find all sections and their positions
; HEY COPILOT AGENT, WERE USING AHKV2
    local sectionMap := Map()
    local sectionSearchPos := 1
; HEY COPILOT AGENT, WERE USING AHKV2
    while (sectionSearchPos := RegExMatch(html, sectionRegex, &sectionMatch, sectionSearchPos)) {
        local sectionTitle := Trim(sectionMatch[1])
; HEY COPILOT AGENT, WERE USING AHKV2
        if (sectionTitle != "" && sectionTitle != "Intro" && sectionTitle != "Overview" && sectionTitle != "Credits" && sectionTitle != "Log")
            sectionMap[sectionSearchPos] := sectionTitle
; HEY COPILOT AGENT, WERE USING AHKV2
        sectionSearchPos += StrLen(sectionMatch[0])
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    while (pos := RegExMatch(html, rowRegex, &match, pos)) {
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Update category based on section position
        for (sectionPos, sectionTitle in sectionMap) {
; HEY COPILOT AGENT, WERE USING AHKV2
            if (sectionPos < pos)
                currentCategory := sectionTitle
; HEY COPILOT AGENT, WERE USING AHKV2
            else
                break
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        local row := match[1]
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Skip empty rows
        if (StrLen(Trim(row)) == 0) {
; HEY COPILOT AGENT, WERE USING AHKV2
            pos += StrLen(match[0])
            continue
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Skip header rows
        if (InStr(row, '<div class="bb_table_th">')) {
; HEY COPILOT AGENT, WERE USING AHKV2
            pos += StrLen(match[0])
            continue
; HEY COPILOT AGENT, WERE USING AHKV2
        }

; HEY COPILOT AGENT, WERE USING AHKV2
        ; Extract cells
        cells := []
; HEY COPILOT AGENT, WERE USING AHKV2
        local tdRegex := '(?s)<div class="bb_table_td">(.*?)</div>'
        local tdPos := 1
; HEY COPILOT AGENT, WERE USING AHKV2
        local tdCount := 0
        local previousPos := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        while (tdPos := RegExMatch(row, tdRegex, &tdMatch, tdPos)) {
            if (tdPos == previousPos)
; HEY COPILOT AGENT, WERE USING AHKV2
                break
            previousPos := tdPos
; HEY COPILOT AGENT, WERE USING AHKV2
            if (StrLen(tdMatch[0]) > 0)
                cells.Push(tdMatch[1])
; HEY COPILOT AGENT, WERE USING AHKV2
            tdPos += StrLen(tdMatch[0]) > 0 ? StrLen(tdMatch[0]) : 1
            tdCount++
; HEY COPILOT AGENT, WERE USING AHKV2
            if (tdCount > 20)
                break
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        if (cells.Length < 3) {
; HEY COPILOT AGENT, WERE USING AHKV2
            pos += StrLen(match[0])
            continue
; HEY COPILOT AGENT, WERE USING AHKV2
        }

; HEY COPILOT AGENT, WERE USING AHKV2
        ; Cell 2: Name
        local name := cells[2]
; HEY COPILOT AGENT, WERE USING AHKV2

        ; Cell 1: Icon URL (extract from href in first cell - the actual icon URL is in the link, not an img tag)
; HEY COPILOT AGENT, WERE USING AHKV2
        local iconUrl := ""
        if (RegExMatch(cells[1], '<a href="([^"]+)"', &iconMatch))
; HEY COPILOT AGENT, WERE USING AHKV2
            iconUrl := iconMatch[1]

; HEY COPILOT AGENT, WERE USING AHKV2
        ; Cell 3: Code images
        local code := ""
; HEY COPILOT AGENT, WERE USING AHKV2
        local imgPos := 1
        while (imgPos := RegExMatch(cells[3], '<img src="([^"]+)"', &imgMatch, imgPos)) {
; HEY COPILOT AGENT, WERE USING AHKV2
            local imgUrl := imgMatch[1]
            if (codeMap.Has(imgUrl))
; HEY COPILOT AGENT, WERE USING AHKV2
                code .= codeMap[imgUrl]
            imgPos += StrLen(imgMatch[0])
; HEY COPILOT AGENT, WERE USING AHKV2
        }

; HEY COPILOT AGENT, WERE USING AHKV2
        ; Save to INI with category
        IniWrite(code, iniFile, name, "Code")
; HEY COPILOT AGENT, WERE USING AHKV2
        IniWrite(currentCategory, iniFile, name, "Warbond")
        strategemCount++
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Store for icon download
; HEY COPILOT AGENT, WERE USING AHKV2
        strategemData.Push({name: name, iconUrl: iconUrl})
        
; HEY COPILOT AGENT, WERE USING AHKV2
        if (Mod(strategemCount, 10) == 0)
            iniProgress.Text := "DB Generation: " strategemCount " strategems..."
; HEY COPILOT AGENT, WERE USING AHKV2

        pos += StrLen(match[0])
; HEY COPILOT AGENT, WERE USING AHKV2
    }

; HEY COPILOT AGENT, WERE USING AHKV2
    iniProgress.Text := "DB Generation: Complete (" strategemCount " strategems)"
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Write count to temp file
    try {
; HEY COPILOT AGENT, WERE USING AHKV2
        FileDelete(appDataDir "\debug.txt")
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    FileAppend("Found " strategemCount " strategems`n", appDataDir "\debug.txt")
}
; HEY COPILOT AGENT, WERE USING AHKV2

DownloadIcons() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global strategemData, downloadProgress
    
; HEY COPILOT AGENT, WERE USING AHKV2
    try {
        downloadProgress.Text := "Icon Download: Creating directory..."
; HEY COPILOT AGENT, WERE USING AHKV2
        local iconDir := appDataDir "\icons"
        if (!DirExist(iconDir))
; HEY COPILOT AGENT, WERE USING AHKV2
            DirCreate(iconDir)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Download arrow direction images from Steam
        local arrowDir := iconDir "\arrows"
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!DirExist(arrowDir))
            DirCreate(arrowDir)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        local arrows := Map(
; HEY COPILOT AGENT, WERE USING AHKV2
            "up", "https://images.steamusercontent.com/ugc/2502382292978626563/2BC55527EC20C05D73CBEC9F3EA3659C099D4AB8/",
            "down", "https://images.steamusercontent.com/ugc/2502382292978627056/A30A455C1EF5BF8740045A7604D79FFD2AC4E32C/",
; HEY COPILOT AGENT, WERE USING AHKV2
            "left", "https://images.steamusercontent.com/ugc/2502382292978625466/31B94090BCCDC70ADACDEBED9E684B25EA9DCD9E/",
            "right", "https://images.steamusercontent.com/ugc/2502382292978625471/9BB08C279B93D1ECD6E7387386FFFC22B90A8BFC/"
; HEY COPILOT AGENT, WERE USING AHKV2
        )
        
; HEY COPILOT AGENT, WERE USING AHKV2
        for name, url in arrows {
            local arrowPath := arrowDir "\" name ".png"
; HEY COPILOT AGENT, WERE USING AHKV2
            if (!FileExist(arrowPath)) {
                downloadProgress.Text := "Icon Download: Downloading " name " arrow..."
; HEY COPILOT AGENT, WERE USING AHKV2
                URLDownloadToFile(url, arrowPath)
            }
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        local total := strategemData.Length
        local downloaded := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        local skipped := 0
        
; HEY COPILOT AGENT, WERE USING AHKV2
        downloadProgress.Text := "Icon Download: 0/" total " (0 skipped)"
        
; HEY COPILOT AGENT, WERE USING AHKV2
        for index, item in strategemData {
            if (item.iconUrl == "") {
; HEY COPILOT AGENT, WERE USING AHKV2
                skipped++
                continue
; HEY COPILOT AGENT, WERE USING AHKV2
            }
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Clean filename
            local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
; HEY COPILOT AGENT, WERE USING AHKV2
            local filePath := iconDir "\" fileName
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Check if icon exists in color folder
            local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
; HEY COPILOT AGENT, WERE USING AHKV2
            local colorPath := iconDir "\" color "\" fileName
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Skip if already exists in either location
            if (FileExist(filePath) || FileExist(colorPath)) {
; HEY COPILOT AGENT, WERE USING AHKV2
                skipped++
                downloadProgress.Text := "Icon Download: " downloaded "/" total " (" skipped " skipped)"
; HEY COPILOT AGENT, WERE USING AHKV2
                continue
            }
; HEY COPILOT AGENT, WERE USING AHKV2
            
            ; Download icon
; HEY COPILOT AGENT, WERE USING AHKV2
            if (URLDownloadToFile(item.iconUrl, filePath))
                downloaded++
; HEY COPILOT AGENT, WERE USING AHKV2
            else
                skipped++
; HEY COPILOT AGENT, WERE USING AHKV2
                
            downloadProgress.Text := "Icon Download: " downloaded "/" total " (" skipped " skipped)"
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        downloadProgress.Text := "Icon Download: Complete (" downloaded " downloaded, " skipped " skipped)"
    } catch Error as err {
; HEY COPILOT AGENT, WERE USING AHKV2
        downloadProgress.Text := "ERROR: " err.What
        throw err
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

DetectIconColors() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global strategemData, iconProgress
    
; HEY COPILOT AGENT, WERE USING AHKV2
    try {
        downloadProgress.Text := "Color Detection: Initializing GDI+..."
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Initialize GDI+
; HEY COPILOT AGENT, WERE USING AHKV2
        local pToken := 0
        local si := Buffer(24, 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        NumPut("UInt", 1, si, 0)
        local result := DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (result != 0 || !pToken) {
; HEY COPILOT AGENT, WERE USING AHKV2
            downloadProgress.Text := "Color Detection: Failed to initialize GDI+"
            return
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        local iconDir := appDataDir "\icons"
        local total := strategemData.Length
; HEY COPILOT AGENT, WERE USING AHKV2
        local processed := 0
        
; HEY COPILOT AGENT, WERE USING AHKV2
        for index, item in strategemData {
            local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_")
; HEY COPILOT AGENT, WERE USING AHKV2
            local filePath := iconDir "\" fileName ".png"
            
; HEY COPILOT AGENT, WERE USING AHKV2
            if (!FileExist(filePath)) {
                processed++
; HEY COPILOT AGENT, WERE USING AHKV2
                continue
            }
; HEY COPILOT AGENT, WERE USING AHKV2
            
            try {
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Detect color
                local color := DetectColor(filePath, pToken)
; HEY COPILOT AGENT, WERE USING AHKV2
                
                ; Write to INI
; HEY COPILOT AGENT, WERE USING AHKV2
                if (color != "")
                    IniWrite(color, appDataDir "\Strategems.ini", item.name, "Color")
; HEY COPILOT AGENT, WERE USING AHKV2
            } catch {
                ; Skip icons that cause errors
; HEY COPILOT AGENT, WERE USING AHKV2
            }
            
; HEY COPILOT AGENT, WERE USING AHKV2
            processed++
            if (Mod(processed, 10) == 0)
; HEY COPILOT AGENT, WERE USING AHKV2
                downloadProgress.Text := "Color Detection: " processed "/" total
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        downloadProgress.Text := "Color Detection: Complete (" processed " icons)"
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Shutdown GDI+
; HEY COPILOT AGENT, WERE USING AHKV2
        if (pToken) {
            DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
    } catch {
        ; Suppress GDI+ errors - color detection is optional
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

DetectColor(filePath, pToken) {
; HEY COPILOT AGENT, WERE USING AHKV2
    try {
        local pBitmap := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Load image
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", filePath, "Ptr*", &pBitmap)
        if (!pBitmap)
; HEY COPILOT AGENT, WERE USING AHKV2
            return "Yellow"
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Get dimensions
        local width := 0, height := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipGetImageWidth", "Ptr", pBitmap, "UInt*", &width)
        DllCall("gdiplus\GdipGetImageHeight", "Ptr", pBitmap, "UInt*", &height)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (width == 0 || height == 0) {
; HEY COPILOT AGENT, WERE USING AHKV2
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
            return "Yellow"
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Sample pixels - use a grid
        local stepX := Max(1, width // 10)
; HEY COPILOT AGENT, WERE USING AHKV2
        local stepY := Max(1, height // 10)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        local greenPixels := 0
        local bluePixels := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        local redPixels := 0
        local yellowPixels := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        local totalPixels := 0
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Sample pixels across the image
        local y := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        while (y < height) {
            local x := 0
; HEY COPILOT AGENT, WERE USING AHKV2
            while (x < width) {
                try {
; HEY COPILOT AGENT, WERE USING AHKV2
                    local argb := 0
                    DllCall("gdiplus\GdipBitmapGetPixel", "Ptr", pBitmap, "Int", x, "Int", y, "UInt*", &argb)
; HEY COPILOT AGENT, WERE USING AHKV2
                    
                    ; Extract RGB components
; HEY COPILOT AGENT, WERE USING AHKV2
                    local alpha := (argb >> 24) & 0xFF
                    local red := (argb >> 16) & 0xFF
; HEY COPILOT AGENT, WERE USING AHKV2
                    local green := (argb >> 8) & 0xFF
                    local blue := argb & 0xFF
; HEY COPILOT AGENT, WERE USING AHKV2
                    
                    ; Skip transparent pixels
; HEY COPILOT AGENT, WERE USING AHKV2
                    if (alpha < 128) {
                        x += stepX
; HEY COPILOT AGENT, WERE USING AHKV2
                        continue
                    }
; HEY COPILOT AGENT, WERE USING AHKV2
                    
                    ; Skip very dark pixels (shadows/outlines)
; HEY COPILOT AGENT, WERE USING AHKV2
                    local maxComponent := Max(red, green, blue)
                    if (maxComponent < 50) {
; HEY COPILOT AGENT, WERE USING AHKV2
                        x += stepX
                        continue
; HEY COPILOT AGENT, WERE USING AHKV2
                    }
                    
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Skip white/very light pixels
                    if (red > 200 && green > 200 && blue > 200) {
; HEY COPILOT AGENT, WERE USING AHKV2
                        x += stepX
                        continue
; HEY COPILOT AGENT, WERE USING AHKV2
                    }
                    
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Calculate color differences from hex codes
                    ; Green: #669351 (RGB: 102, 147, 81)
; HEY COPILOT AGENT, WERE USING AHKV2
                    local greenDiff := Abs(red - 102) + Abs(green - 147) + Abs(blue - 81)
                    ; Blue: #48ABC7 (RGB: 72, 171, 199)
; HEY COPILOT AGENT, WERE USING AHKV2
                    local blueDiff := Abs(red - 72) + Abs(green - 171) + Abs(blue - 199)
                    ; Red: #DC7A6B (RGB: 220, 122, 107)
; HEY COPILOT AGENT, WERE USING AHKV2
                    local redDiff := Abs(red - 220) + Abs(green - 122) + Abs(blue - 107)
                    
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Find closest match (tolerance: 60)
                    local minDiff := Min(greenDiff, blueDiff, redDiff)
; HEY COPILOT AGENT, WERE USING AHKV2
                    
                    if (minDiff < 60) {
; HEY COPILOT AGENT, WERE USING AHKV2
                        if (minDiff == greenDiff) {
                            greenPixels++
; HEY COPILOT AGENT, WERE USING AHKV2
                        } else if (minDiff == blueDiff) {
                            bluePixels++
; HEY COPILOT AGENT, WERE USING AHKV2
                        } else if (minDiff == redDiff) {
                            redPixels++
; HEY COPILOT AGENT, WERE USING AHKV2
                        }
                    } else {
; HEY COPILOT AGENT, WERE USING AHKV2
                        ; No match - count as yellow
                        yellowPixels++
; HEY COPILOT AGENT, WERE USING AHKV2
                    }
                    
; HEY COPILOT AGENT, WERE USING AHKV2
                    totalPixels++
                } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Skip pixels that cause errors
                }
; HEY COPILOT AGENT, WERE USING AHKV2
                x += stepX
            }
; HEY COPILOT AGENT, WERE USING AHKV2
            y += stepY
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Dispose bitmap
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Determine dominant color
        if (totalPixels == 0)
; HEY COPILOT AGENT, WERE USING AHKV2
            return "Yellow"
        
; HEY COPILOT AGENT, WERE USING AHKV2
        local maxCount := Max(redPixels, greenPixels, bluePixels, yellowPixels)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        if (maxCount == 0)
            return "Yellow"
; HEY COPILOT AGENT, WERE USING AHKV2
        else if (maxCount == redPixels)
            return "Red"
; HEY COPILOT AGENT, WERE USING AHKV2
        else if (maxCount == greenPixels)
            return "Green"
; HEY COPILOT AGENT, WERE USING AHKV2
        else if (maxCount == bluePixels)
            return "Blue"
; HEY COPILOT AGENT, WERE USING AHKV2
        else
            return "Yellow"
; HEY COPILOT AGENT, WERE USING AHKV2
        
    } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
        return "Yellow"
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
OrganizeIconsByColor() {
    global strategemData, iconProgress
; HEY COPILOT AGENT, WERE USING AHKV2
    
    try {
; HEY COPILOT AGENT, WERE USING AHKV2
        downloadProgress.Text := "Organizing: Creating color directories..."
        
; HEY COPILOT AGENT, WERE USING AHKV2
        local iconDir := appDataDir "\icons"
        local colorDirs := ["Yellow", "Red", "Green", "Blue"]
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Create color subdirectories if they don't exist
; HEY COPILOT AGENT, WERE USING AHKV2
        for colorName in colorDirs {
            local colorPath := iconDir "\" colorName
; HEY COPILOT AGENT, WERE USING AHKV2
            if (!DirExist(colorPath))
                DirCreate(colorPath)
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        downloadProgress.Text := "Organizing: Copying icon files by color..."
        
; HEY COPILOT AGENT, WERE USING AHKV2
        local organized := 0
        for index, item in strategemData {
; HEY COPILOT AGENT, WERE USING AHKV2
            local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
            local sourceFile := iconDir "\" fileName
; HEY COPILOT AGENT, WERE USING AHKV2
            
            if (!FileExist(sourceFile))
; HEY COPILOT AGENT, WERE USING AHKV2
                continue
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Get color from INI
            local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
; HEY COPILOT AGENT, WERE USING AHKV2
            local destDir := iconDir "\" color
            local destFile := destDir "\" fileName
; HEY COPILOT AGENT, WERE USING AHKV2
            
            ; Copy file if not already there
; HEY COPILOT AGENT, WERE USING AHKV2
            if (!FileExist(destFile)) {
                FileCopy(sourceFile, destFile)
; HEY COPILOT AGENT, WERE USING AHKV2
            }
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Delete original to avoid duplicate copies
            if (FileExist(sourceFile)) {
; HEY COPILOT AGENT, WERE USING AHKV2
                FileDelete(sourceFile)
            }
; HEY COPILOT AGENT, WERE USING AHKV2
            organized++
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        downloadProgress.Text := "Organizing: Complete (" organized " organized)"
; HEY COPILOT AGENT, WERE USING AHKV2
        
    } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Suppress errors
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
AllIconsOrganized() {
    global strategemData
; HEY COPILOT AGENT, WERE USING AHKV2
    
    local iconDir := appDataDir "\icons"
; HEY COPILOT AGENT, WERE USING AHKV2
    local colorDirs := ["Yellow", "Red", "Green", "Blue"]
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Check if all color directories exist
    for colorName in colorDirs {
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!DirExist(iconDir "\" colorName))
            return false
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Check if all strategems have their icons in their assigned color folders
    for index, item in strategemData {
; HEY COPILOT AGENT, WERE USING AHKV2
        local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
        local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
; HEY COPILOT AGENT, WERE USING AHKV2
        local colorPath := iconDir "\" color "\" fileName
        
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!FileExist(colorPath))
            return false
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    return true
}
; HEY COPILOT AGENT, WERE USING AHKV2

CheckAndDownloadMissingIcons() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global downloadProgress
    
; HEY COPILOT AGENT, WERE USING AHKV2
    downloadProgress.Text := "Icon Check: Verifying..."
    
; HEY COPILOT AGENT, WERE USING AHKV2
    local iconDir := appDataDir "\icons"
    local colorDirs := ["Yellow", "Red", "Green", "Blue"]
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Ensure icon directory exists
; HEY COPILOT AGENT, WERE USING AHKV2
    if (!DirExist(iconDir))
        DirCreate(iconDir)
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Ensure color subdirectories exist
; HEY COPILOT AGENT, WERE USING AHKV2
    for colorName in colorDirs {
        local colorPath := iconDir "\" colorName
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!DirExist(colorPath))
            DirCreate(colorPath)
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Check if INI exists
    if (!FileExist(appDataDir "\Strategems.ini")) {
; HEY COPILOT AGENT, WERE USING AHKV2
        downloadProgress.Text := "Icon Check: Skipped (no INI)"
        return
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Load strategem data if not already loaded
    global strategemData
; HEY COPILOT AGENT, WERE USING AHKV2
    if (!IsSet(strategemData) || strategemData.Length == 0) {
        strategemData := []
; HEY COPILOT AGENT, WERE USING AHKV2
        local iniFile := appDataDir "\Strategems.ini"
        local fileContent := FileRead(iniFile)
; HEY COPILOT AGENT, WERE USING AHKV2
        local sectionRegex := '(?m)^\[([^\]]+)\]'
        local sectionPos := 1
; HEY COPILOT AGENT, WERE USING AHKV2
        while (sectionPos := RegExMatch(fileContent, sectionRegex, &match, sectionPos)) {
            local sectionName := match[1]
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Skip the special __None__ strategem
            if (sectionName != "__None__") {
; HEY COPILOT AGENT, WERE USING AHKV2
                strategemData.Push({name: sectionName, iconUrl: ""})
            }
; HEY COPILOT AGENT, WERE USING AHKV2
            sectionPos += StrLen(match[0])
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Check for missing icons
    local missingIcons := []
; HEY COPILOT AGENT, WERE USING AHKV2
    for index, item in strategemData {
        local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
; HEY COPILOT AGENT, WERE USING AHKV2
        local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
        local colorPath := iconDir "\" color "\" fileName
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (!FileExist(colorPath)) {
; HEY COPILOT AGENT, WERE USING AHKV2
            missingIcons.Push(item)
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    if (missingIcons.Length == 0) {
        downloadProgress.Text := "Icon Check: Complete (all icons present)"
; HEY COPILOT AGENT, WERE USING AHKV2
        return
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Try to download missing icons
; HEY COPILOT AGENT, WERE USING AHKV2
    downloadProgress.Text := "Icon Check: " missingIcons.Length " missing, downloading..."
    local downloaded := 0
; HEY COPILOT AGENT, WERE USING AHKV2
    local failed := 0
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Load HTML to get icon URLs
    local htmlFile := appDataDir "\StrategmsRaw.html"
; HEY COPILOT AGENT, WERE USING AHKV2
    if (!FileExist(htmlFile)) {
        downloadProgress.Text := "Icon Check: " missingIcons.Length " missing (no HTML to download)"
; HEY COPILOT AGENT, WERE USING AHKV2
        return
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    local html := FileRead(htmlFile)
; HEY COPILOT AGENT, WERE USING AHKV2
    
    for index, item in missingIcons {
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Try to find icon URL in HTML
        local searchName := item.name
; HEY COPILOT AGENT, WERE USING AHKV2
        local iconUrl := ""
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Search for the strategem in HTML and extract icon URL
        local rowRegex := '(?s)<div class="bb_table_tr">((?:<div class="bb_table_td">.*?' searchName '.*?</div>)*)</div>'
; HEY COPILOT AGENT, WERE USING AHKV2
        if (RegExMatch(html, rowRegex, &match)) {
            if (RegExMatch(match[1], '<img src="([^"]+)"', &iconMatch))
; HEY COPILOT AGENT, WERE USING AHKV2
                iconUrl := iconMatch[1]
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (iconUrl == "") {
; HEY COPILOT AGENT, WERE USING AHKV2
            failed++
            continue
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Download to temp location first
        local fileName := RegExReplace(item.name, '[<>:"/\\|?*]', "_") ".png"
; HEY COPILOT AGENT, WERE USING AHKV2
        local tempPath := iconDir "\" fileName
        
; HEY COPILOT AGENT, WERE USING AHKV2
        if (URLDownloadToFile(iconUrl, tempPath)) {
            ; Move to color folder
; HEY COPILOT AGENT, WERE USING AHKV2
            local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
            local colorPath := iconDir "\" color "\" fileName
; HEY COPILOT AGENT, WERE USING AHKV2
            
            try {
; HEY COPILOT AGENT, WERE USING AHKV2
                FileCopy(tempPath, colorPath, 1)
                FileDelete(tempPath)
; HEY COPILOT AGENT, WERE USING AHKV2
                downloaded++
            } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
                failed++
            }
; HEY COPILOT AGENT, WERE USING AHKV2
        } else {
            failed++
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        if (Mod(index, 5) == 0)
            downloadProgress.Text := "Icon Check: Downloading " index "/" missingIcons.Length
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    local remaining := missingIcons.Length - downloaded
    if (remaining > 0) {
; HEY COPILOT AGENT, WERE USING AHKV2
        downloadProgress.Text := "Icon Check: " remaining " missing (" downloaded " downloaded, " failed " failed)"
    } else {
; HEY COPILOT AGENT, WERE USING AHKV2
        downloadProgress.Text := "Icon Check: Complete (" downloaded " downloaded)"
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
GrabHtml() {
    global htmlProgress
; HEY COPILOT AGENT, WERE USING AHKV2
    local file := appDataDir "\StrategmsRaw.html"
    if (!FileExist(file) || A_Now - FileGetTime(file, "M") > 7 * 24 * 60 * 60) {
; HEY COPILOT AGENT, WERE USING AHKV2
        htmlProgress.Text := "HTML Download: Downloading from Steam..."
        local url := "https://steamcommunity.com/sharedfiles/filedetails/?id=3161075951"
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!URLDownloadToFile(url, file)) {
            htmlProgress.Text := "HTML Download: Failed"
; HEY COPILOT AGENT, WERE USING AHKV2
            return false
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        htmlProgress.Text := "HTML Download: Complete"
        return true  ; Was downloaded
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    htmlProgress.Text := "HTML Download: Using cached version"
; HEY COPILOT AGENT, WERE USING AHKV2
    return false  ; Using cached version
}
; HEY COPILOT AGENT, WERE USING AHKV2

URLDownloadToFile(url, file) {
; HEY COPILOT AGENT, WERE USING AHKV2
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
; HEY COPILOT AGENT, WERE USING AHKV2
        whr.SetTimeouts(10000, 10000, 10000, 10000)  ; 10 seconds timeouts
        whr.Open("GET", url)
; HEY COPILOT AGENT, WERE USING AHKV2
        whr.Send()
        if (whr.Status != 200)
; HEY COPILOT AGENT, WERE USING AHKV2
            return false
        
; HEY COPILOT AGENT, WERE USING AHKV2
        stream := ComObject("ADODB.Stream")
        stream.Type := 1  ; Binary
; HEY COPILOT AGENT, WERE USING AHKV2
        stream.Open()
        stream.Write(whr.ResponseBody)
; HEY COPILOT AGENT, WERE USING AHKV2
        stream.SaveToFile(file, 2)  ; Overwrite
        stream.Close()
; HEY COPILOT AGENT, WERE USING AHKV2
        return true
    } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
        return false
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
; Create and show numpad GUI
CreateNumpadGUI() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global numpadGui := Gui("-AlwaysOnTop -MaximizeBox", "Stratagem Numpad")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Close handler for numpad GUI - exit app when it closes
    numpadGui.OnEvent("Close", NumpadGuiClose)
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Set tooltip delay to 0 (no delay)
; HEY COPILOT AGENT, WERE USING AHKV2
    A_TooltipDelay := 0
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Dark mode colors
    numpadGui.BackColor := "1e1e1e"
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadGui.SetFont("s14 cFFFFFF", "Segoe UI")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Create placeholder image for unassigned buttons
    global placeholderImagePath := CreatePlaceholderImage()
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Create "None" strategem entry that uses the placeholder image
; HEY COPILOT AGENT, WERE USING AHKV2
    if (placeholderImagePath != "") {
        IniWrite("None", appDataDir "\Strategems.ini", "__None__", "Code")
; HEY COPILOT AGENT, WERE USING AHKV2
        IniWrite("None", appDataDir "\Strategems.ini", "__None__", "Warbond")
        IniWrite("None", appDataDir "\Strategems.ini", "__None__", "Color")
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Assignment tracking
    global selectedStrategem := ""
; HEY COPILOT AGENT, WERE USING AHKV2
    global selectedNumpadBtn := ""
    global strategemButtons := Map()
; HEY COPILOT AGENT, WERE USING AHKV2
    global numpadButtons := Map()
    global numpadLabels := Map()
; HEY COPILOT AGENT, WERE USING AHKV2
    global assignmentsFile  ; Reference the global, don't redefine
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Load strategems from ini
    local strategems := []
; HEY COPILOT AGENT, WERE USING AHKV2
    local iniFile := appDataDir "\Strategems.ini"
    if (FileExist(iniFile)) {
; HEY COPILOT AGENT, WERE USING AHKV2
        local fileContent := FileRead(iniFile)
        local sectionRegex := '(?m)^\[([^\]]+)\]'
; HEY COPILOT AGENT, WERE USING AHKV2
        local sectionPos := 1
        while (sectionPos := RegExMatch(fileContent, sectionRegex, &match, sectionPos)) {
; HEY COPILOT AGENT, WERE USING AHKV2
            local sectionName := match[1]
            ; Skip the special __None__ strategem
; HEY COPILOT AGENT, WERE USING AHKV2
            if (sectionName != "__None__") {
                strategems.Push({name: sectionName, iconUrl: ""})
; HEY COPILOT AGENT, WERE USING AHKV2
            }
            sectionPos += StrLen(match[0])
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Sort strategems by color priority
; HEY COPILOT AGENT, WERE USING AHKV2
    strategems := SortStrategemesByColor(strategems)
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Layout dimensions
    local btnWidth := 50
; HEY COPILOT AGENT, WERE USING AHKV2
    local btnHeight := 50
    local spacing := 5
; HEY COPILOT AGENT, WERE USING AHKV2
    local leftX := 10
    local iconDir := appDataDir "\icons"
; HEY COPILOT AGENT, WERE USING AHKV2
    local itemsPerRow := 15  ; Number of items per row (increased from 12 to 15)
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Group strategems by color
    local colorGroups := Map()
; HEY COPILOT AGENT, WERE USING AHKV2
    colorGroups["Yellow"] := []
    colorGroups["Red"] := []
; HEY COPILOT AGENT, WERE USING AHKV2
    colorGroups["Green"] := []
    colorGroups["Blue"] := []
; HEY COPILOT AGENT, WERE USING AHKV2
    
    for item in strategems {
; HEY COPILOT AGENT, WERE USING AHKV2
        local itemColor := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
        colorGroups[itemColor].Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Sort Blue group: Exosuits/Vehicles first, then Packs/Guard Dogs/Shields, then others
    if (colorGroups["Blue"].Length > 0) {
; HEY COPILOT AGENT, WERE USING AHKV2
        local blueItems := colorGroups["Blue"]
        local vehicleItems := []
; HEY COPILOT AGENT, WERE USING AHKV2
        local priorityItems := []
        local otherItems := []
; HEY COPILOT AGENT, WERE USING AHKV2
        
        local topPriorityItems := []
; HEY COPILOT AGENT, WERE USING AHKV2
        
        for item in blueItems {
; HEY COPILOT AGENT, WERE USING AHKV2
            if (InStr(item.name, "Exosuit") || InStr(item.name, "Vehicule") || InStr(item.name, "Vehicle")) {
                vehicleItems.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
            } else if (InStr(item.name, "Hover") || InStr(item.name, "Jump") || InStr(item.name, "Warp")) {
                topPriorityItems.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
            } else if (InStr(item.name, "Guard Dog") || InStr(item.name, "Pack") || InStr(item.name, "Shield") || InStr(item.name, "Hellbomb")) {
                priorityItems.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
            } else {
                otherItems.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Rebuild Blue group with vehicles first, then hover/jump/warp, then shields/packs/guard dogs/hellbomb, then others
; HEY COPILOT AGENT, WERE USING AHKV2
        colorGroups["Blue"] := []
        for item in vehicleItems {
; HEY COPILOT AGENT, WERE USING AHKV2
            colorGroups["Blue"].Push(item)
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        for item in topPriorityItems {
            colorGroups["Blue"].Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        for item in priorityItems {
; HEY COPILOT AGENT, WERE USING AHKV2
            colorGroups["Blue"].Push(item)
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        for item in otherItems {
            colorGroups["Blue"].Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Layout strategems in rows, grouped by color
; HEY COPILOT AGENT, WERE USING AHKV2
    local x := leftX
    local y := 10
; HEY COPILOT AGENT, WERE USING AHKV2
    local itemsInCurrentRow := 0
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Process each color group in order
    for colorName in ["Yellow", "Red", "Green", "Blue"] {
; HEY COPILOT AGENT, WERE USING AHKV2
        local colorItems := colorGroups[colorName]
        if (colorItems.Length == 0)
; HEY COPILOT AGENT, WERE USING AHKV2
            continue
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Start new row for each color group (unless at the very beginning)
        if (itemsInCurrentRow > 0) {
; HEY COPILOT AGENT, WERE USING AHKV2
            x := leftX
            y += btnHeight + spacing
; HEY COPILOT AGENT, WERE USING AHKV2
            itemsInCurrentRow := 0
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Add items in this color group
; HEY COPILOT AGENT, WERE USING AHKV2
        for item in colorItems {
            local itemName := item.name
; HEY COPILOT AGENT, WERE USING AHKV2
            local itemColor := IniRead(appDataDir "\Strategems.ini", itemName, "Color", "Yellow")
            local itemIconPath := iconDir "\" itemColor "\" RegExReplace(itemName, '[<>:"/\\|?*]', "_") ".png"
; HEY COPILOT AGENT, WERE USING AHKV2
            local btnOpt := "w" btnWidth " h" btnHeight " x" x " y" y
            
; HEY COPILOT AGENT, WERE USING AHKV2
            if (FileExist(itemIconPath)) {
                local btn := numpadGui.Add("Pic", btnOpt " +Border", itemIconPath)
; HEY COPILOT AGENT, WERE USING AHKV2
                btn.OnEvent("Click", CreateStrategemClickHandler(itemName, itemIconPath))
                strategemButtons[itemName] := btn
; HEY COPILOT AGENT, WERE USING AHKV2
            } else {
                local btn := numpadGui.Add("Button", btnOpt, "?")
; HEY COPILOT AGENT, WERE USING AHKV2
                btn.OnEvent("Click", CreateStrategemClickHandler(itemName, ""))
                strategemButtons[itemName] := btn
; HEY COPILOT AGENT, WERE USING AHKV2
            }
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Move to next position
            x += btnWidth + spacing
; HEY COPILOT AGENT, WERE USING AHKV2
            itemsInCurrentRow++
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Start new row if we've filled this one
            if (itemsInCurrentRow >= itemsPerRow) {
; HEY COPILOT AGENT, WERE USING AHKV2
                x := leftX
                y += btnHeight + spacing
; HEY COPILOT AGENT, WERE USING AHKV2
                itemsInCurrentRow := 0
            }
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Calculate numpad position based on row width (add spacing column)
; HEY COPILOT AGENT, WERE USING AHKV2
    local numpadX := leftX + (itemsPerRow * (btnWidth + spacing)) + (btnWidth + spacing)
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Row 1: NumLock / * -
    global numLockBtn := numpadGui.Add("Picture", "w50 h50 x" numpadX " y10 +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global numLockLbl := numpadGui.Add("Text", "w50 h50 x" numpadX " y10 BackgroundTrans Center +0x200", "NL")
    global divideBtn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global divideLbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "/")
    global multiplyBtn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global multiplyLbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "*")
    global minusBtn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global minusLbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "-")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Row 2: 7 8 9
    global num7Btn := numpadGui.Add("Picture", "w50 h50 x" numpadX " y+5 +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num7Lbl := numpadGui.Add("Text", "w50 h50 x" numpadX " yp BackgroundTrans Center +0x200", "7")
    global num8Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num8Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "8")
    global num9Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num9Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "9")
    global plusBtn := numpadGui.Add("Picture", "w50 h104 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global plusLbl := numpadGui.Add("Text", "w50 h104 xp yp BackgroundTrans Center +0x200", "+")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Row 3: 4 5 6
    global num4Btn := numpadGui.Add("Picture", "w50 h50 x" numpadX " y120 +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num4Lbl := numpadGui.Add("Text", "w50 h50 x" numpadX " yp BackgroundTrans Center +0x200", "4")
    global num5Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num5Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "5")
    global num6Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num6Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "6")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Row 4: 1 2 3 Enter (tall)
    global num1Btn := numpadGui.Add("Picture", "w50 h50 x" numpadX " y175 +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num1Lbl := numpadGui.Add("Text", "w50 h50 x" numpadX " yp BackgroundTrans Center +0x200", "1")
    global num2Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num2Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "2")
    global num3Btn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num3Lbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", "3")
    global enterBtn := numpadGui.Add("Picture", "w50 h104 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global enterLbl := numpadGui.Add("Text", "w50 h104 xp yp BackgroundTrans Center +0x200", "Enter")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Row 5: 0 (double width) . 
    global num0Btn := numpadGui.Add("Picture", "w105 h50 x" numpadX " y230 +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global num0Lbl := numpadGui.Add("Text", "w105 h50 x" numpadX " yp BackgroundTrans Center +0x200", "0")
    global periodBtn := numpadGui.Add("Picture", "w50 h50 x+5 yp +Border")
; HEY COPILOT AGENT, WERE USING AHKV2
    global periodLbl := numpadGui.Add("Text", "w50 h50 xp yp BackgroundTrans Center +0x200", ".")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Store numpad buttons and labels in maps
    numpadButtons["NumLock"] := numLockBtn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["NumLock"] := numLockLbl
    numpadButtons["/"] := divideBtn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["/"] := divideLbl
    numpadButtons["*"] := multiplyBtn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["*"] := multiplyLbl
    numpadButtons["-"] := minusBtn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["-"] := minusLbl
    numpadButtons["7"] := num7Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["7"] := num7Lbl
    numpadButtons["8"] := num8Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["8"] := num8Lbl
    numpadButtons["9"] := num9Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["9"] := num9Lbl
    numpadButtons["+"] := plusBtn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["+"] := plusLbl
    numpadButtons["4"] := num4Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["4"] := num4Lbl
    numpadButtons["5"] := num5Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["5"] := num5Lbl
    numpadButtons["6"] := num6Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["6"] := num6Lbl
    numpadButtons["1"] := num1Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["1"] := num1Lbl
    numpadButtons["2"] := num2Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["2"] := num2Lbl
    numpadButtons["3"] := num3Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["3"] := num3Lbl
    numpadButtons["Enter"] := enterBtn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["Enter"] := enterLbl
    numpadButtons["0"] := num0Btn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["0"] := num0Lbl
    numpadButtons["."] := periodBtn
; HEY COPILOT AGENT, WERE USING AHKV2
    numpadLabels["."] := periodLbl
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Attach click handlers to both pictures and labels
    for key, btn in numpadButtons {
; HEY COPILOT AGENT, WERE USING AHKV2
        btn.OnEvent("Click", NumpadClicked.Bind(key))
        numpadLabels[key].OnEvent("Click", NumpadClicked.Bind(key))
; HEY COPILOT AGENT, WERE USING AHKV2
        btn.OnEvent("ContextMenu", NumpadRightClicked.Bind(key))
        numpadLabels[key].OnEvent("ContextMenu", NumpadRightClicked.Bind(key))
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Add delay control below the numpad
    numpadGui.Add("Text", "x" numpadX " y290 w40", "Delay:")
; HEY COPILOT AGENT, WERE USING AHKV2
    global keyDelayDisplay := numpadGui.Add("Text", "x+5 yp w60 h30 Center cFFFFFF", keyDelayMS)
    numpadGui.Add("Text", "x+2 yp h30", "ms")
; HEY COPILOT AGENT, WERE USING AHKV2
    global keyDelayUpArrow := numpadGui.Add("Picture", "x+7 y298 w20 h15", appDataDir "\icons\arrows\up.png")
    keyDelayUpArrow.OnEvent("Click", KeyDelayUpArrowClicked)
; HEY COPILOT AGENT, WERE USING AHKV2
    keyDelayUpArrow.OnEvent("DoubleClick", KeyDelayUpArrowClicked)
; HEY COPILOT AGENT, WERE USING AHKV2
    global keyDelayDownArrow := numpadGui.Add("Picture", "x+0 y298 w20 h15", appDataDir "\icons\arrows\down.png")
    keyDelayDownArrow.OnEvent("Click", KeyDelayDownArrowClicked)
; HEY COPILOT AGENT, WERE USING AHKV2
    keyDelayDownArrow.OnEvent("DoubleClick", KeyDelayDownArrowClicked)
; HEY COPILOT AGENT, WERE USING AHKV2
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Add checkboxes below the delay control
    global alwaysOnTopCheck := numpadGui.Add("Checkbox", "x" numpadX " y320", "Always on Top")
; HEY COPILOT AGENT, WERE USING AHKV2
    global arrowKeysCheck := numpadGui.Add("Checkbox", "x" numpadX " y340", "Arrow Keys")
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Add strategem name display at bottom right (below checkboxes) - three separate controls for different font sizes
    global strategemNameDisplay_Line1 := numpadGui.Add("Text", "x" (numpadX - 50) " y375 w260 h30 Center", "")
; HEY COPILOT AGENT, WERE USING AHKV2
    strategemNameDisplay_Line1.SetFont("s16")
    global strategemNameDisplay_Line2 := numpadGui.Add("Text", "x" (numpadX - 50) " y405 w260 h25 Center", "")
; HEY COPILOT AGENT, WERE USING AHKV2
    strategemNameDisplay_Line2.SetFont("s12")
    global strategemNameDisplay_Line3 := numpadGui.Add("Text", "x" (numpadX - 50) " y430 w260 h25 Center", "")
; HEY COPILOT AGENT, WERE USING AHKV2
    strategemNameDisplay_Line3.SetFont("s12")
    ; Container for arrow code images (up to 6 arrows at 22px each = 132px total, centered in 260px width)
; HEY COPILOT AGENT, WERE USING AHKV2
    global arrowCodePics := []
    global currentArrowCode := ""  ; Track current code to prevent flickering
; HEY COPILOT AGENT, WERE USING AHKV2
    local startX := numpadX + 2  ; Center in 260px space (numpadX-50 is left edge, +52 to center)
    loop 6 {
; HEY COPILOT AGENT, WERE USING AHKV2
        arrowCodePics.Push(numpadGui.Add("Picture", "x" (startX + (A_Index-1)*22) " y457 w20 h20 Hidden", ""))
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Load checkbox states from settings file (use global settingsFile)
; HEY COPILOT AGENT, WERE USING AHKV2
    global settingsFile
    alwaysOnTopCheck.Value := IniRead(settingsFile, "Numpad", "AlwaysOnTop", 0)
; HEY COPILOT AGENT, WERE USING AHKV2
    arrowKeysCheck.Value := IniRead(settingsFile, "Numpad", "ArrowKeys", 1)
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Set up event handlers
    alwaysOnTopCheck.OnEvent("Click", AlwaysOnTopChanged)
; HEY COPILOT AGENT, WERE USING AHKV2
    arrowKeysCheck.OnEvent("Click", ArrowKeysChanged)
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Apply Always on Top setting
    if (alwaysOnTopCheck.Value) {
; HEY COPILOT AGENT, WERE USING AHKV2
        numpadGui.Opt("+AlwaysOnTop")
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Load saved assignments
; HEY COPILOT AGENT, WERE USING AHKV2
    LoadAssignments()
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Start hover detection timer
    SetTimer(UpdateStrategemHoverDisplay, 50)
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Setup secret code hotkeys (sixseven = clear appdata & restart)
; HEY COPILOT AGENT, WERE USING AHKV2
    for char in ["s", "i", "x", "e", "v", "n"] {
        Hotkey(char, SecretCodeCharTyped, "On")
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Calculate window size based on strategem layout
    local numRows := Ceil(y / (btnHeight + spacing)) + 1
    local winHeight := y + btnHeight + 20  ; Current Y position + button height + padding
; HEY COPILOT AGENT, WERE USING AHKV2
    local winWidth := numpadX + 250  ; strategems + numpad + padding
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Ensure minimum height for numpad controls
    if (winHeight < 450)
; HEY COPILOT AGENT, WERE USING AHKV2
        winHeight := 450
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Restore saved position or show centered
    local numpadX_pos := IniRead(settingsFile, "GUI", "NumpadX", "")
; HEY COPILOT AGENT, WERE USING AHKV2
    local numpadY_pos := IniRead(settingsFile, "GUI", "NumpadY", "")
    if (numpadX_pos != "" && numpadY_pos != "")
; HEY COPILOT AGENT, WERE USING AHKV2
        numpadGui.Show("x" numpadX_pos " y" numpadY_pos " w" winWidth " h" winHeight)
    else
; HEY COPILOT AGENT, WERE USING AHKV2
        numpadGui.Show("w" winWidth " h" winHeight)
}
; HEY COPILOT AGENT, WERE USING AHKV2

AlwaysOnTopChanged(*) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global numpadGui, alwaysOnTopCheck, settingsFile
    IniWrite(alwaysOnTopCheck.Value, settingsFile, "Numpad", "AlwaysOnTop")
; HEY COPILOT AGENT, WERE USING AHKV2
    if (alwaysOnTopCheck.Value) {
        numpadGui.Opt("+AlwaysOnTop")
; HEY COPILOT AGENT, WERE USING AHKV2
    } else {
        numpadGui.Opt("-AlwaysOnTop")
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

CreatePlaceholderImage() {
; HEY COPILOT AGENT, WERE USING AHKV2
    local iconDir := appDataDir "\icons"
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Ensure icons directory exists
    if (!DirExist(iconDir)) {
; HEY COPILOT AGENT, WERE USING AHKV2
        try {
            DirCreate(iconDir)
; HEY COPILOT AGENT, WERE USING AHKV2
        } catch {
            return ""
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    local placeholderPath := iconDir "\placeholder.png"
; HEY COPILOT AGENT, WERE USING AHKV2
    local placeholderWide := iconDir "\placeholder_wide.png"
    local placeholderTall := iconDir "\placeholder_tall.png"
; HEY COPILOT AGENT, WERE USING AHKV2

    local repoBase := "https://raw.githubusercontent.com/EatPrilosec/NumpadStrategems/master"
; HEY COPILOT AGENT, WERE USING AHKV2

    ; Create standard 50x50 placeholder (fallback to repo download if generation fails)
; HEY COPILOT AGENT, WERE USING AHKV2
    if (!FileExist(placeholderPath)) {
        if (!CreatePlaceholderWithSize(50, 50, placeholderPath)) {
; HEY COPILOT AGENT, WERE USING AHKV2
            URLDownloadToFile(repoBase "/placeholder.png", placeholderPath)
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Create wide 105x50 placeholder for 0 button
    if (!FileExist(placeholderWide)) {
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!CreatePlaceholderWithSize(105, 50, placeholderWide)) {
            URLDownloadToFile(repoBase "/placeholder_wide.png", placeholderWide)
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Create tall 50x104 placeholder for + and Enter buttons
; HEY COPILOT AGENT, WERE USING AHKV2
    if (!FileExist(placeholderTall)) {
        if (!CreatePlaceholderWithSize(50, 104, placeholderTall)) {
; HEY COPILOT AGENT, WERE USING AHKV2
            URLDownloadToFile(repoBase "/placeholder_tall.png", placeholderTall)
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    return placeholderPath
}
; HEY COPILOT AGENT, WERE USING AHKV2

CreatePlaceholderWithSize(width, height, filePath) {
; HEY COPILOT AGENT, WERE USING AHKV2
    try {
        ; Initialize GDI+
; HEY COPILOT AGENT, WERE USING AHKV2
        local pToken := 0
        local si := Buffer(24, 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        NumPut("UInt", 1, si, 0)
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (!pToken) {
; HEY COPILOT AGENT, WERE USING AHKV2
            return false
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Create bitmap
; HEY COPILOT AGENT, WERE USING AHKV2
        local pBitmap := 0
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", width, "Int", height, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pBitmap)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (!pBitmap) {
; HEY COPILOT AGENT, WERE USING AHKV2
            DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
            return false
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Get graphics from bitmap
        local pGraphics := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &pGraphics)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Clear with background color #1e1e1e (ARGB: 0xFF1E1E1E)
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0xFF1E1E1E)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Release graphics
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Get PNG encoder CLSID (manually set)
        ; PNG CLSID: {557CF406-1A04-11D3-9A73-0000F81EF32E}
; HEY COPILOT AGENT, WERE USING AHKV2
        local clsid := Buffer(16, 0)
        DllCall("ole32\CLSIDFromString", "WStr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", clsid)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Save to file
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", filePath, "Ptr", clsid, "Ptr", 0)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Cleanup
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        return true
    } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
        return false
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
CreateScaledStrategemIcon(strategemName, buttonKey) {
    try {
; HEY COPILOT AGENT, WERE USING AHKV2
        local iconDir := appDataDir "\icons"
        local color := IniRead(appDataDir "\Strategems.ini", strategemName, "Color", "Yellow")
; HEY COPILOT AGENT, WERE USING AHKV2
        local sourceIcon := iconDir "\" color "\" RegExReplace(strategemName, '[<>:"/\\|?*]', "_") ".png"
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Determine target dimensions based on button key
        local targetWidth := 50
; HEY COPILOT AGENT, WERE USING AHKV2
        local targetHeight := 50
        if (buttonKey = "0") {
; HEY COPILOT AGENT, WERE USING AHKV2
            targetWidth := 105
            targetHeight := 50
; HEY COPILOT AGENT, WERE USING AHKV2
        } else if (buttonKey = "+" || buttonKey = "Enter") {
            targetWidth := 50
; HEY COPILOT AGENT, WERE USING AHKV2
            targetHeight := 104
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Check if source icon exists
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!FileExist(sourceIcon)) {
            return sourceIcon  ; Return original if scaling not needed
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Create scaled icon path in temp folder
        local scaledIconPath := iconDir "\scaled\" RegExReplace(strategemName, '[<>:"/\\|?*]', "_") "_" targetWidth "x" targetHeight ".png"
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Create scaled folder if needed
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!DirExist(iconDir "\scaled")) {
            DirCreate(iconDir "\scaled")
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Return existing scaled icon if already created
        if (FileExist(scaledIconPath)) {
; HEY COPILOT AGENT, WERE USING AHKV2
            return scaledIconPath
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Initialize GDI+
; HEY COPILOT AGENT, WERE USING AHKV2
        local pToken := 0
        local si := Buffer(24, 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        NumPut("UInt", 1, si, 0)
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (!pToken) {
; HEY COPILOT AGENT, WERE USING AHKV2
            return sourceIcon
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Load source bitmap
; HEY COPILOT AGENT, WERE USING AHKV2
        local pSourceBitmap := 0
        DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", sourceIcon, "Ptr*", &pSourceBitmap)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (!pSourceBitmap) {
; HEY COPILOT AGENT, WERE USING AHKV2
            DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
            return sourceIcon
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Create target bitmap with background color
        local pTargetBitmap := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", targetWidth, "Int", targetHeight, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pTargetBitmap)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        if (!pTargetBitmap) {
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pSourceBitmap)
; HEY COPILOT AGENT, WERE USING AHKV2
            DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
            return sourceIcon
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Get target graphics and clear with background
        local pGraphics := 0
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pTargetBitmap, "Ptr*", &pGraphics)
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", pGraphics, "UInt", 0xFF1E1E1E)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Calculate letterbox dimensions (maintain aspect ratio)
; HEY COPILOT AGENT, WERE USING AHKV2
        local sourceWidth := 0, sourceHeight := 0
        DllCall("gdiplus\GdipGetImageWidth", "Ptr", pSourceBitmap, "UInt*", &sourceWidth)
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipGetImageHeight", "Ptr", pSourceBitmap, "UInt*", &sourceHeight)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Calculate scaled dimensions
        local scaleX := (targetWidth - 4) / sourceWidth
; HEY COPILOT AGENT, WERE USING AHKV2
        local scaleY := (targetHeight - 4) / sourceHeight
        local scale := Min(scaleX, scaleY)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        local scaledWidth := sourceWidth * scale
; HEY COPILOT AGENT, WERE USING AHKV2
        local scaledHeight := sourceHeight * scale
        local offsetX := (targetWidth - scaledWidth) / 2
; HEY COPILOT AGENT, WERE USING AHKV2
        local offsetY := (targetHeight - scaledHeight) / 2
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Draw scaled image centered (with dark border around it)
        DllCall("gdiplus\GdipDrawImageRectI", "Ptr", pGraphics, "Ptr", pSourceBitmap, "Int", offsetX, "Int", offsetY, "Int", scaledWidth, "Int", scaledHeight)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Cleanup graphics
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", pGraphics)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Save target bitmap as PNG
        local clsid := Buffer(16, 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("ole32\CLSIDFromString", "WStr", "{557CF406-1A04-11D3-9A73-0000F81EF32E}", "Ptr", clsid)
        DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pTargetBitmap, "WStr", scaledIconPath, "Ptr", clsid, "Ptr", 0)
; HEY COPILOT AGENT, WERE USING AHKV2
        
        ; Cleanup
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pSourceBitmap)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", pTargetBitmap)
; HEY COPILOT AGENT, WERE USING AHKV2
        DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
        
; HEY COPILOT AGENT, WERE USING AHKV2
        return scaledIconPath
    } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
        return sourceIcon
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
ArrowKeysChanged(*) {
    global arrowKeysCheck, settingsFile
; HEY COPILOT AGENT, WERE USING AHKV2
    IniWrite(arrowKeysCheck.Value, settingsFile, "Numpad", "ArrowKeys")
}
; HEY COPILOT AGENT, WERE USING AHKV2
KeyDelayUpDownChanged(*) {
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Deprecated - arrow buttons now handle delay changes
}

; HEY COPILOT AGENT, WERE USING AHKV2
KeyDelayUpArrowClicked(*) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global keyDelayDisplay, keyDelayMS
    local newDelay := keyDelayMS + 1
; HEY COPILOT AGENT, WERE USING AHKV2
    if (newDelay <= 999) {
        keyDelayMS := newDelay
; HEY COPILOT AGENT, WERE USING AHKV2
        keyDelayDisplay.Value := newDelay
    }
}

; HEY COPILOT AGENT, WERE USING AHKV2
KeyDelayDownArrowClicked(*) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global keyDelayDisplay, keyDelayMS, lowDelayWarningShown
    local newDelay := keyDelayMS - 1
; HEY COPILOT AGENT, WERE USING AHKV2
    if (newDelay >= 1) {
        ; Check if transitioning from >=25ms to <25ms before updating
; HEY COPILOT AGENT, WERE USING AHKV2
        if (keyDelayMS >= 25 && newDelay < 25 && !lowDelayWarningShown) {
            lowDelayWarningShown := true
; HEY COPILOT AGENT, WERE USING AHKV2
            MsgBox("Warning: Delays below 25ms may cause reliability issues with longer strategems. The longer the strategem code, the more delay is recommended.`n`nYou need about 6-7ms for each strategem input.", "Low Delay Warning", "Icon!")
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        keyDelayMS := newDelay
; HEY COPILOT AGENT, WERE USING AHKV2
        keyDelayDisplay.Value := newDelay
    }
}

; Execute a strategem code sequence
; HEY COPILOT AGENT, WERE USING AHKV2
ExecuteStrategemCode(code) {
    global arrowKeysCheck, keyDelayMS
; HEY COPILOT AGENT, WERE USING AHKV2
    
    if (code == "")
; HEY COPILOT AGENT, WERE USING AHKV2
        return
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Check settings
    local useArrowKeys := arrowKeysCheck.Value
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Send each direction in the code
; HEY COPILOT AGENT, WERE USING AHKV2
    local codeLength := StrLen(code)
    loop codeLength {
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Check if Control is still held - if not, cancel execution
        if (!GetKeyState("LCtrl") && !GetKeyState("RCtrl")) {
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Control was released - cancel execution
            return
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        
; HEY COPILOT AGENT, WERE USING AHKV2
        local char := SubStr(code, A_Index, 1)
        local key := ""
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (useArrowKeys) {
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Use arrow keys
            switch char {
; HEY COPILOT AGENT, WERE USING AHKV2
                case "U": key := "Up"
                case "D": key := "Down"
; HEY COPILOT AGENT, WERE USING AHKV2
                case "L": key := "Left"
                case "R": key := "Right"
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        } else {
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Use WASD
            switch char {
; HEY COPILOT AGENT, WERE USING AHKV2
                case "U": key := "w"
                case "D": key := "s"
; HEY COPILOT AGENT, WERE USING AHKV2
                case "L": key := "a"
                case "R": key := "d"
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        }
; HEY COPILOT AGENT, WERE USING AHKV2
        
        if (key != "") {
; HEY COPILOT AGENT, WERE USING AHKV2
            Send("{Blind}{" key " Down}")
            Sleep(keyDelayMS)
; HEY COPILOT AGENT, WERE USING AHKV2
            Send("{Blind}{" key " Up}")
            Sleep(keyDelayMS)
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
; Handle numpad key press - look up assigned strategem and execute
NumpadHotkeyPressed(buttonKey) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global assignmentsFile
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Check if assignments file exists
    if (!FileExist(assignmentsFile))
; HEY COPILOT AGENT, WERE USING AHKV2
        return
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Get the assigned strategem for this button
    local strategemName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
; HEY COPILOT AGENT, WERE USING AHKV2
    if (strategemName == "" || strategemName == "__None__")
        return
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Get the strategem code from the strategems INI
; HEY COPILOT AGENT, WERE USING AHKV2
    local code := IniRead(appDataDir "\Strategems.ini", strategemName, "Code", "")
    if (code == "")
; HEY COPILOT AGENT, WERE USING AHKV2
        return
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Execute the code
    ExecuteStrategemCode(code)
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
CreateStrategemClickHandler(strategemName, strategemIconPath) {
    return StrategemClicked.Bind(strategemName, strategemIconPath)
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
StrategemClicked(strategemName, iconPath, *) {
    global selectedStrategem, selectedNumpadBtn, assignmentsFile
; HEY COPILOT AGENT, WERE USING AHKV2
    
    if (selectedNumpadBtn != "") {
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Numpad button was already selected, make assignment
        AssignStrategemToButton(strategemName, iconPath, selectedNumpadBtn)
; HEY COPILOT AGENT, WERE USING AHKV2
        selectedStrategem := ""
        selectedNumpadBtn := ""
; HEY COPILOT AGENT, WERE USING AHKV2
    } else {
        ; Select this strategem
; HEY COPILOT AGENT, WERE USING AHKV2
        selectedStrategem := strategemName
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
NumpadClicked(buttonKey, *) {
    global selectedStrategem, selectedNumpadBtn
; HEY COPILOT AGENT, WERE USING AHKV2
    
    if (selectedStrategem != "") {
; HEY COPILOT AGENT, WERE USING AHKV2
        ; Strategem was already selected, make assignment
        local color := IniRead(appDataDir "\Strategems.ini", selectedStrategem, "Color", "Yellow")
; HEY COPILOT AGENT, WERE USING AHKV2
        local iconPath := appDataDir "\icons\" color "\" RegExReplace(selectedStrategem, '[<>:"/\\|?*]', "_") ".png"
        AssignStrategemToButton(selectedStrategem, iconPath, buttonKey)
; HEY COPILOT AGENT, WERE USING AHKV2
        selectedStrategem := ""
        selectedNumpadBtn := ""
; HEY COPILOT AGENT, WERE USING AHKV2
    } else {
        ; Select this numpad button
; HEY COPILOT AGENT, WERE USING AHKV2
        selectedNumpadBtn := buttonKey
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
NumpadRightClicked(buttonKey, *) {
    global numpadButtons, numpadLabels, assignmentsFile, placeholderImagePath
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Check if there's an assignment for this button
; HEY COPILOT AGENT, WERE USING AHKV2
    if (FileExist(assignmentsFile)) {
        local strategemName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
; HEY COPILOT AGENT, WERE USING AHKV2
        if (strategemName != "" && strategemName != "__None__") {
            ; Assign "None" to unassign - this shows the placeholder
; HEY COPILOT AGENT, WERE USING AHKV2
            IniWrite("__None__", assignmentsFile, "Assignments", buttonKey)
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Immediately update the button display with appropriate placeholder
            local btn := numpadButtons[buttonKey]
; HEY COPILOT AGENT, WERE USING AHKV2
            local iconDir := appDataDir "\icons"
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Choose appropriate placeholder based on button size
            local placeholderPath := ""
; HEY COPILOT AGENT, WERE USING AHKV2
            if (buttonKey = "0") {
                ; Wide button - use placeholder_wide.png
; HEY COPILOT AGENT, WERE USING AHKV2
                placeholderPath := iconDir "\placeholder_wide.png"
            } else if (buttonKey = "+" || buttonKey = "Enter") {
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Tall buttons - use placeholder_tall.png
                placeholderPath := iconDir "\placeholder_tall.png"
; HEY COPILOT AGENT, WERE USING AHKV2
            } else {
                ; Standard button - use placeholder.png
; HEY COPILOT AGENT, WERE USING AHKV2
                placeholderPath := iconDir "\placeholder.png"
            }
; HEY COPILOT AGENT, WERE USING AHKV2
            
            if (placeholderPath != "" && FileExist(placeholderPath)) {
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Directly set placeholder without clearing
                btn.Value := placeholderPath
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

AssignStrategemToButton(strategemName, iconPath, buttonKey) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global numpadButtons, numpadLabels, assignmentsFile
    
; HEY COPILOT AGENT, WERE USING AHKV2
    local btn := numpadButtons[buttonKey]
    local lbl := numpadLabels[buttonKey]
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Update picture control to show strategem icon
; HEY COPILOT AGENT, WERE USING AHKV2
    if (FileExist(iconPath)) {
        ; Check if button is double-sized and needs scaling
; HEY COPILOT AGENT, WERE USING AHKV2
        if (buttonKey = "0" || buttonKey = "+" || buttonKey = "Enter") {
            ; Use scaled icon with letterboxing to prevent stretching
; HEY COPILOT AGENT, WERE USING AHKV2
            local scaledIcon := CreateScaledStrategemIcon(strategemName, buttonKey)
            local newValue := FileExist(scaledIcon) ? scaledIcon : iconPath
; HEY COPILOT AGENT, WERE USING AHKV2
            btn.Value := newValue
        } else {
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Standard button - use icon as-is
            btn.Value := iconPath
; HEY COPILOT AGENT, WERE USING AHKV2
        }
        ; Keep label text overlaid on icon
; HEY COPILOT AGENT, WERE USING AHKV2
    } else {
        ; Icon doesn't exist, show question mark
; HEY COPILOT AGENT, WERE USING AHKV2
        lbl.Text := "?"
    }
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Save assignment
; HEY COPILOT AGENT, WERE USING AHKV2
    IniWrite(strategemName, assignmentsFile, "Assignments", buttonKey)
}
; HEY COPILOT AGENT, WERE USING AHKV2

LoadAssignments() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global assignmentsFile, numpadButtons, numpadLabels
    
; HEY COPILOT AGENT, WERE USING AHKV2
    if (!FileExist(assignmentsFile)) {
        return
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    local iconDir := appDataDir "\icons"
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Read all assignments
    for buttonKey, btn in numpadButtons {
; HEY COPILOT AGENT, WERE USING AHKV2
        local strategemName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
        if (strategemName != "") {
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Check if this is the "None" placeholder
            if (strategemName == "__None__") {
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Choose appropriate placeholder based on button size
                local placeholderPath := ""
; HEY COPILOT AGENT, WERE USING AHKV2
                if (buttonKey = "0") {
                    ; Wide button - use placeholder_wide.png
; HEY COPILOT AGENT, WERE USING AHKV2
                    placeholderPath := iconDir "\placeholder_wide.png"
                } else if (buttonKey = "+" || buttonKey = "Enter") {
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Tall buttons - use placeholder_tall.png
                    placeholderPath := iconDir "\placeholder_tall.png"
; HEY COPILOT AGENT, WERE USING AHKV2
                } else {
                    ; Standard button - use placeholder.png
; HEY COPILOT AGENT, WERE USING AHKV2
                    placeholderPath := iconDir "\placeholder.png"
                }
; HEY COPILOT AGENT, WERE USING AHKV2
                
                if (FileExist(placeholderPath)) {
; HEY COPILOT AGENT, WERE USING AHKV2
                    btn.Value := placeholderPath
                }
; HEY COPILOT AGENT, WERE USING AHKV2
            } else {
                local color := IniRead(appDataDir "\Strategems.ini", strategemName, "Color", "Yellow")
; HEY COPILOT AGENT, WERE USING AHKV2
                local iconPath := appDataDir "\icons\" color "\" RegExReplace(strategemName, '[<>:"/\\|?*]', "_") ".png"
                if (FileExist(iconPath)) {
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Check if button is double-sized and needs scaling
                    if (buttonKey = "0" || buttonKey = "+" || buttonKey = "Enter") {
; HEY COPILOT AGENT, WERE USING AHKV2
                        ; Use scaled icon with letterboxing to prevent stretching
                        local scaledIcon := CreateScaledStrategemIcon(strategemName, buttonKey)
; HEY COPILOT AGENT, WERE USING AHKV2
                        btn.Value := scaledIcon
                    } else {
; HEY COPILOT AGENT, WERE USING AHKV2
                        ; Standard button - use icon as-is
                        btn.Value := iconPath
; HEY COPILOT AGENT, WERE USING AHKV2
                    }
                    ; Keep label text overlaid on icon
; HEY COPILOT AGENT, WERE USING AHKV2
                } else {
                    ; Icon doesn't exist, show question mark
; HEY COPILOT AGENT, WERE USING AHKV2
                    numpadLabels[buttonKey].Text := "?"
                }
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

SortStrategemesByColor(strategemArray) {
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Sort strategems by color priority: Yellow (1), Red (2), Green (3), Blue (4)
    local colorPriority := Map("Yellow", 1, "Red", 2, "Green", 3, "Blue", 4)
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Create sorted array
; HEY COPILOT AGENT, WERE USING AHKV2
    local sorted := []
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Add in priority order
    for priority in [1, 2, 3, 4] {
; HEY COPILOT AGENT, WERE USING AHKV2
        if (priority == 2) {
            ; Special handling for red strategems - put Eagle Rearm first, then other eagles, then regular
; HEY COPILOT AGENT, WERE USING AHKV2
            local eagleRearm := []
            local redEagle := []
; HEY COPILOT AGENT, WERE USING AHKV2
            local redRegular := []
            
; HEY COPILOT AGENT, WERE USING AHKV2
            for item in strategemArray {
                local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
; HEY COPILOT AGENT, WERE USING AHKV2
                if (colorPriority[color] == priority) {
                    ; Check if name is Eagle Rearm
; HEY COPILOT AGENT, WERE USING AHKV2
                    if (InStr(item.name, "Eagle Rearm")) {
                        eagleRearm.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
                    } else if (InStr(item.name, "Eagle")) {
                        redEagle.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
                    } else {
                        redRegular.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
                    }
                }
; HEY COPILOT AGENT, WERE USING AHKV2
            }
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Add Eagle Rearm first, then other eagles, then regular red strategems
            for item in eagleRearm {
; HEY COPILOT AGENT, WERE USING AHKV2
                sorted.Push(item)
            }
; HEY COPILOT AGENT, WERE USING AHKV2
            for item in redEagle {
                sorted.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
            }
            for item in redRegular {
; HEY COPILOT AGENT, WERE USING AHKV2
                sorted.Push(item)
            }
; HEY COPILOT AGENT, WERE USING AHKV2
        } else if (priority == 3) {
            ; Special handling for green strategems - put sentries/emplacements last
; HEY COPILOT AGENT, WERE USING AHKV2
            local greenRegular := []
            local greenSentry := []
; HEY COPILOT AGENT, WERE USING AHKV2
            
            for item in strategemArray {
; HEY COPILOT AGENT, WERE USING AHKV2
                local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
                if (colorPriority[color] == priority) {
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Check if name contains "sentry" or "emplacement" (case-insensitive)
                    if (InStr(item.name, "Sentry") || InStr(item.name, "Emplacement")) {
; HEY COPILOT AGENT, WERE USING AHKV2
                        greenSentry.Push(item)
                    } else {
; HEY COPILOT AGENT, WERE USING AHKV2
                        greenRegular.Push(item)
                    }
; HEY COPILOT AGENT, WERE USING AHKV2
                }
            }
; HEY COPILOT AGENT, WERE USING AHKV2
            
            ; Add regular green strategems first, then sentry/emplacement ones
; HEY COPILOT AGENT, WERE USING AHKV2
            for item in greenRegular {
                sorted.Push(item)
; HEY COPILOT AGENT, WERE USING AHKV2
            }
            for item in greenSentry {
; HEY COPILOT AGENT, WERE USING AHKV2
                sorted.Push(item)
            }
; HEY COPILOT AGENT, WERE USING AHKV2
        } else {
            for item in strategemArray {
; HEY COPILOT AGENT, WERE USING AHKV2
                local color := IniRead(appDataDir "\Strategems.ini", item.name, "Color", "Yellow")
                if (colorPriority[color] == priority) {
; HEY COPILOT AGENT, WERE USING AHKV2
                    sorted.Push(item)
                }
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    return sorted
}
; HEY COPILOT AGENT, WERE USING AHKV2

UpdateStrategemHoverDisplay() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global strategemButtons, numpadButtons, strategemNameDisplay_Line1, strategemNameDisplay_Line2, strategemNameDisplay_Line3, arrowCodePics, assignmentsFile
    
; HEY COPILOT AGENT, WERE USING AHKV2
    MouseGetPos(&mouseX, &mouseY)
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Check each strategem button
    for strategemName, btn in strategemButtons {
; HEY COPILOT AGENT, WERE USING AHKV2
        try {
            local btnPos := btn.GetPos(&x, &y, &w, &h)
; HEY COPILOT AGENT, WERE USING AHKV2
            
            ; Check if mouse is over this button
; HEY COPILOT AGENT, WERE USING AHKV2
            if (mouseX >= x && mouseX < x + w && mouseY >= y && mouseY < y + h) {
                ; Get the warbond type from INI
; HEY COPILOT AGENT, WERE USING AHKV2
                local warbond := IniRead(appDataDir "\Strategems.ini", strategemName, "Warbond", "General")
                
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Find assignment for this strategem by checking all numpad buttons
                local assignment := ""
; HEY COPILOT AGENT, WERE USING AHKV2
                if (FileExist(assignmentsFile)) {
                    ; Check each possible numpad button
; HEY COPILOT AGENT, WERE USING AHKV2
                    local buttons := ["NumLock", "/", "*", "-", "7", "8", "9", "+", "4", "5", "6", "1", "2", "3", "Enter", "0", "."]
                    for buttonKey in buttons {
; HEY COPILOT AGENT, WERE USING AHKV2
                        local assignedName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
                        if (assignedName = strategemName) {
; HEY COPILOT AGENT, WERE USING AHKV2
                            assignment := buttonKey
                            break
; HEY COPILOT AGENT, WERE USING AHKV2
                        }
                    }
; HEY COPILOT AGENT, WERE USING AHKV2
                }
                
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Set line 1: strategem name (large font)
                strategemNameDisplay_Line1.Value := strategemName
; HEY COPILOT AGENT, WERE USING AHKV2
                
                ; Set line 2: warbond if not "General", otherwise empty
; HEY COPILOT AGENT, WERE USING AHKV2
                if (warbond != "General") {
                    strategemNameDisplay_Line2.Value := warbond
; HEY COPILOT AGENT, WERE USING AHKV2
                } else {
                    strategemNameDisplay_Line2.Value := ""
; HEY COPILOT AGENT, WERE USING AHKV2
                }
                
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Set line 3: assignment if exists, otherwise empty
                if (assignment != "") {
; HEY COPILOT AGENT, WERE USING AHKV2
                    strategemNameDisplay_Line3.Value := "Numpad " assignment
                } else {
; HEY COPILOT AGENT, WERE USING AHKV2
                    strategemNameDisplay_Line3.Value := ""
                }
; HEY COPILOT AGENT, WERE USING AHKV2

                ; Set code line: arrow images
; HEY COPILOT AGENT, WERE USING AHKV2
                local code := IniRead(appDataDir "\Strategems.ini", strategemName, "Code", "")
                DisplayArrowCode(code)
; HEY COPILOT AGENT, WERE USING AHKV2
                
                return
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Skip buttons that fail position detection
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Check each numpad button
    for buttonKey, btn in numpadButtons {
; HEY COPILOT AGENT, WERE USING AHKV2
        try {
            local btnPos := btn.GetPos(&x, &y, &w, &h)
; HEY COPILOT AGENT, WERE USING AHKV2
            
            ; Check if mouse is over this button
; HEY COPILOT AGENT, WERE USING AHKV2
            if (mouseX >= x && mouseX < x + w && mouseY >= y && mouseY < y + h) {
                ; Look up what strategem is assigned to this button
; HEY COPILOT AGENT, WERE USING AHKV2
                local strategemName := ""
                if (FileExist(assignmentsFile)) {
; HEY COPILOT AGENT, WERE USING AHKV2
                    strategemName := IniRead(assignmentsFile, "Assignments", buttonKey, "")
                }
; HEY COPILOT AGENT, WERE USING AHKV2
                
                if (strategemName != "" && strategemName != "__None__") {
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Get the warbond type from INI
                    local warbond := IniRead(appDataDir "\Strategems.ini", strategemName, "Warbond", "General")
; HEY COPILOT AGENT, WERE USING AHKV2
                    
                    ; Set line 1: strategem name (large font)
; HEY COPILOT AGENT, WERE USING AHKV2
                    strategemNameDisplay_Line1.Value := strategemName
                    
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Set line 2: warbond if not "General", otherwise empty
                    if (warbond != "General") {
; HEY COPILOT AGENT, WERE USING AHKV2
                        strategemNameDisplay_Line2.Value := warbond
                    } else {
; HEY COPILOT AGENT, WERE USING AHKV2
                        strategemNameDisplay_Line2.Value := ""
                    }
; HEY COPILOT AGENT, WERE USING AHKV2
                    
                    ; Set line 3: button assignment
; HEY COPILOT AGENT, WERE USING AHKV2
                    strategemNameDisplay_Line3.Value := "Numpad " buttonKey

; HEY COPILOT AGENT, WERE USING AHKV2
                    ; Set code line: arrow images
                    local code := IniRead(appDataDir "\Strategems.ini", strategemName, "Code", "")
; HEY COPILOT AGENT, WERE USING AHKV2
                    DisplayArrowCode(code)
                } else {
; HEY COPILOT AGENT, WERE USING AHKV2
                    ; No assignment for this button or unassigned
                    strategemNameDisplay_Line1.Value := "Numpad " buttonKey
; HEY COPILOT AGENT, WERE USING AHKV2
                    strategemNameDisplay_Line2.Value := ""
                    strategemNameDisplay_Line3.Value := "Not assigned"
; HEY COPILOT AGENT, WERE USING AHKV2
                    ClearArrowCode()
                }
; HEY COPILOT AGENT, WERE USING AHKV2
                
                return
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        } catch {
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Skip buttons that fail position detection
        }
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Mouse is not over any button - clear all lines
    strategemNameDisplay_Line1.Value := ""
; HEY COPILOT AGENT, WERE USING AHKV2
    strategemNameDisplay_Line2.Value := ""
    strategemNameDisplay_Line3.Value := ""
; HEY COPILOT AGENT, WERE USING AHKV2
    ClearArrowCode()
}
; HEY COPILOT AGENT, WERE USING AHKV2

DisplayArrowCode(code) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global arrowCodePics, appDataDir, currentArrowCode
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Only update if code has changed (prevent flickering)
    if (code == currentArrowCode)
; HEY COPILOT AGENT, WERE USING AHKV2
        return
    
; HEY COPILOT AGENT, WERE USING AHKV2
    currentArrowCode := code
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Clear all arrow pictures first
    loop 6 {
; HEY COPILOT AGENT, WERE USING AHKV2
        arrowCodePics[A_Index].Value := ""
        arrowCodePics[A_Index].Visible := false
; HEY COPILOT AGENT, WERE USING AHKV2
    }
    
; HEY COPILOT AGENT, WERE USING AHKV2
    if (code == "")
        return
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Map direction letters to arrow icon filenames
; HEY COPILOT AGENT, WERE USING AHKV2
    local arrowFiles := Map()
    arrowFiles["U"] := appDataDir "\icons\arrows\up.png"
; HEY COPILOT AGENT, WERE USING AHKV2
    arrowFiles["D"] := appDataDir "\icons\arrows\down.png"
    arrowFiles["L"] := appDataDir "\icons\arrows\left.png"
; HEY COPILOT AGENT, WERE USING AHKV2
    arrowFiles["R"] := appDataDir "\icons\arrows\right.png"
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Get the first text box position to align with it
    global strategemNameDisplay_Line1
; HEY COPILOT AGENT, WERE USING AHKV2
    local textPos := strategemNameDisplay_Line1.GetPos(&tx, &ty, &tw, &th)
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Calculate centered starting position based on actual code length
    local codeLen := Min(StrLen(code), 6)
; HEY COPILOT AGENT, WERE USING AHKV2
    local totalWidth := codeLen * 22  ; 22px per arrow (20px width + 2px spacing)
    local startX := tx + (tw - totalWidth) // 2  ; Center arrows in same width as text boxes
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Display each arrow at calculated positions
; HEY COPILOT AGENT, WERE USING AHKV2
    loop codeLen {
        local ch := SubStr(code, A_Index, 1)
; HEY COPILOT AGENT, WERE USING AHKV2
        if (arrowFiles.Has(ch) && FileExist(arrowFiles[ch])) {
            ; Move picture to new position
; HEY COPILOT AGENT, WERE USING AHKV2
            arrowCodePics[A_Index].Move(startX + (A_Index-1)*22, 457)
            ; Use *w20 *h20 prefix to force image to resize to 20x20
; HEY COPILOT AGENT, WERE USING AHKV2
            arrowCodePics[A_Index].Value := "*w20 *h20 " arrowFiles[ch]
            arrowCodePics[A_Index].Visible := true
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
; HEY COPILOT AGENT, WERE USING AHKV2
}

; HEY COPILOT AGENT, WERE USING AHKV2
; Handler for closing the numpad GUI - exit the entire application
NumpadGuiClose(*) {
; HEY COPILOT AGENT, WERE USING AHKV2
    ExitApp
}
; HEY COPILOT AGENT, WERE USING AHKV2

ClearArrowCode() {
; HEY COPILOT AGENT, WERE USING AHKV2
    global arrowCodePics, currentArrowCode
    
; HEY COPILOT AGENT, WERE USING AHKV2
    ; Only update if not already empty (prevent flickering)
    if (currentArrowCode == "")
; HEY COPILOT AGENT, WERE USING AHKV2
        return
    
; HEY COPILOT AGENT, WERE USING AHKV2
    currentArrowCode := ""
    loop 6 {
; HEY COPILOT AGENT, WERE USING AHKV2
        arrowCodePics[A_Index].Value := ""
        arrowCodePics[A_Index].Visible := false
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

global secretCodeBuffer := ""
; HEY COPILOT AGENT, WERE USING AHKV2
SecretCodeCharTyped(hotkeyName) {
    global secretCodeBuffer, appDataDir, numpadGui
; HEY COPILOT AGENT, WERE USING AHKV2
    
    ; Only process if numpad GUI is active
; HEY COPILOT AGENT, WERE USING AHKV2
    try {
        if (WinActive("ahk_id " numpadGui.Hwnd)) {
; HEY COPILOT AGENT, WERE USING AHKV2
            secretCodeBuffer .= hotkeyName
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Keep only last 9 characters
            if (StrLen(secretCodeBuffer) > 9)
; HEY COPILOT AGENT, WERE USING AHKV2
                secretCodeBuffer := SubStr(secretCodeBuffer, -8)
            
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Check for "sixseven"
            if (InStr(secretCodeBuffer, "sixseven")) {
; HEY COPILOT AGENT, WERE USING AHKV2
                secretCodeBuffer := ""
                
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Clear AppData folder
                try {
; HEY COPILOT AGENT, WERE USING AHKV2
                    DirDelete(appDataDir, 1)
                }
; HEY COPILOT AGENT, WERE USING AHKV2
                
                ; Restart the script
; HEY COPILOT AGENT, WERE USING AHKV2
                Reload()
            } else {
; HEY COPILOT AGENT, WERE USING AHKV2
                ; Not building the code, send the key through
                Send("{" hotkeyName "}")
; HEY COPILOT AGENT, WERE USING AHKV2
            }
        } else {
; HEY COPILOT AGENT, WERE USING AHKV2
            ; Window not active, send key through
            Send("{" hotkeyName "}")
; HEY COPILOT AGENT, WERE USING AHKV2
        }
    }
}

; OnExit handler - save keyDelayMS to INI when script exits
; HEY COPILOT AGENT, WERE USING AHKV2
OnExit(SaveSettingsOnExit)

SaveSettingsOnExit(ExitReason, ExitCode) {
; HEY COPILOT AGENT, WERE USING AHKV2
    global keyDelayMS, settingsFile, appDataDir
    ; Only write if AppData directory still exists (skip if sixseven was used)
; HEY COPILOT AGENT, WERE USING AHKV2
    if (DirExist(appDataDir)) {
        IniWrite(keyDelayMS, settingsFile, "Settings", "KeyDelayMS")
; HEY COPILOT AGENT, WERE USING AHKV2
    }
}
; HEY COPILOT AGENT, WERE USING AHKV2

