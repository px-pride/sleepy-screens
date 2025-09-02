; Monitor Power Control Script for AutoHotkey v2
; Default hotkey: Win+Alt+S to turn off monitors
; You can change this to any key combination you prefer

; Constants
STARTUP_REG_KEY := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
SETTINGS_REG_KEY := "HKEY_CURRENT_USER\Software\SleepyScreens"
APP_NAME := "SleepyScreens"

; Wake timer variables
global wakeTime := ""
global wakeEnabled := false
global lastWake := ""

; Get the executable path (works for both .ahk and compiled .exe)
APP_PATH := A_IsCompiled ? A_ScriptFullPath : '"' . A_AhkPath . '" "' . A_ScriptFullPath . '"'

; Initialize startup behavior on first run
InitializeStartup()

; Load wake settings
LoadWakeSettings()

; Create system tray menu
CreateTrayMenu()

; Start wake timer (checks every second)
SetTimer(CheckWake, 1000)

; Turn off monitors with Win+Alt+S (on key release)
#!s up:: {
    ; Method 1: SendMessage (most reliable)
    SendMessage(0x112, 0xF170, 2, , "Program Manager")
}

; Set wake time with Win+Alt+W
#!w:: {
    SetWakeTime()
}

; Check if it's time to wake monitors
CheckWake() {
    global wakeTime, wakeEnabled, lastWake
    
    if (!wakeEnabled || wakeTime == "")
        return
    
    currentTime := FormatTime(, "HH:mm")
    currentDateTime := FormatTime(, "yyyyMMddHHmm")
    if (currentTime == wakeTime && currentDateTime != lastWake) {
        lastWake := currentDateTime  ; Store full datetime to allow daily recurrence
        ; Move mouse 1 pixel to wake monitors
        DllCall("mouse_event", "UInt", 0x0001, "Int", 1, "Int", 0, "UInt", 0, "Ptr", 0)
        Sleep(40)
        DllCall("mouse_event", "UInt", 0x0001, "Int", -1, "Int", 0, "UInt", 0, "Ptr", 0)
    }
}

; Load wake settings from registry
LoadWakeSettings() {
    global wakeTime, wakeEnabled
    try {
        wakeTime := RegRead(SETTINGS_REG_KEY, "WakeTime")
        wakeEnabled := RegRead(SETTINGS_REG_KEY, "WakeEnabled") == "1"
    }
}

; Function to initialize startup (add to registry on first run)
InitializeStartup() {
    try {
        ; Check if already in startup
        RegRead(STARTUP_REG_KEY, APP_NAME)
    } catch {
        ; Not in startup, add it (first run behavior)
        try {
            RegWrite(APP_PATH, "REG_SZ", STARTUP_REG_KEY, APP_NAME)
        }
    }
}

; Function to create the tray menu
CreateTrayMenu() {
    ; Clear default menu items
    A_TrayMenu.Delete()
    
    ; Add menu items
    A_TrayMenu.Add("Run at startup", ToggleStartup)
    A_TrayMenu.Add() ; Separator
    A_TrayMenu.Add("Set wake time", SetWakeTime)
    
    ; Add Enable wake timer with time display
    wakeMenuText := "Enable wake timer"
    if (wakeTime != "")
        wakeMenuText .= " (" . wakeTime . ")"
    A_TrayMenu.Add(wakeMenuText, ToggleWakeTimer)
    
    ; Check and/or disable based on state
    if (wakeTime == "") {
        A_TrayMenu.Disable(wakeMenuText)
    } else if (wakeEnabled) {
        A_TrayMenu.Check(wakeMenuText)
    }
    
    A_TrayMenu.Add() ; Separator
    A_TrayMenu.Add("Help", ShowHelp)
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    
    ; Check the startup item if it's enabled
    if IsStartupEnabled() {
        A_TrayMenu.Check("Run at startup")
    }
    
    ; Set tooltip
    tooltip := "Sleepy Screens - Win+Alt+S to turn off monitors"
    if (wakeEnabled && wakeTime != "")
        tooltip .= "`nWake at " . wakeTime
    A_IconTip := tooltip
}

; Function to check if startup is enabled
IsStartupEnabled() {
    try {
        RegRead(STARTUP_REG_KEY, APP_NAME)
        return true
    } catch {
        return false
    }
}

; Function to show help
ShowHelp(*) {
    helpText := "Win+Alt+S - Turn your screens off instantly`n"
    helpText .= "Win+Alt+W - Wake up your screens on a timer"
    MsgBox(helpText, "Sleepy Screens - Help", 64)
}

; Set wake time
SetWakeTime(*) {
    global wakeTime, wakeEnabled
    
    result := InputBox("Set wake time (24-hour format, e.g. 17:30):", "Set Wake Time", "w300 h100", wakeTime)
    if (result.Result == "Cancel")
        return
    
    ; Parse various time formats
    inputTime := Trim(result.Value)
    
    ; Try to match different formats and normalize to HH:MM
    if (RegExMatch(inputTime, "^(\d{1,2}):(\d{2})$", &match)) {
        ; Format: H:MM or HH:MM
        hours := Format("{:02d}", match[1])
        minutes := match[2]
    } else if (RegExMatch(inputTime, "^(\d{1,2})(\d{2})$", &match)) {
        ; Format: HMM or HHMM
        hours := Format("{:02d}", match[1])
        minutes := match[2]
    } else if (RegExMatch(inputTime, "^(\d{3,4})$", &match)) {
        ; Format: HMM or HHMM (without groups)
        if (StrLen(match[1]) == 3) {
            hours := Format("{:02d}", SubStr(match[1], 1, 1))
            minutes := SubStr(match[1], 2, 2)
        } else {
            hours := SubStr(match[1], 1, 2)
            minutes := SubStr(match[1], 3, 2)
        }
    } else {
        MsgBox("Invalid time format. Use HH:MM, HHMM, or HMM (e.g., 17:30, 1730, 730)", "Error", 48)
        return
    }
    
    ; Validate hours and minutes
    if (hours > 23 || minutes > 59) {
        MsgBox("Invalid time. Hours must be 0-23, minutes 0-59.", "Error", 48)
        return
    }
    
    wakeTime := hours . ":" . minutes
    wakeEnabled := true  ; Automatically enable when time is set
    try {
        RegWrite(wakeTime, "REG_SZ", SETTINGS_REG_KEY, "WakeTime")
        RegWrite("1", "REG_SZ", SETTINGS_REG_KEY, "WakeEnabled")
    }
    
    CreateTrayMenu() ; Refresh menu
}

; Toggle wake timer
ToggleWakeTimer(*) {
    global wakeEnabled, wakeTime
    
    if (wakeTime == "") {
        MsgBox("Please set a wake time first.", "No Wake Time", 48)
        return
    }
    
    wakeEnabled := !wakeEnabled
    try {
        RegWrite(wakeEnabled ? "1" : "0", "REG_SZ", SETTINGS_REG_KEY, "WakeEnabled")
    }
    
    CreateTrayMenu() ; Refresh menu
}

; Function to toggle startup
ToggleStartup(*) {
    if IsStartupEnabled() {
        ; Currently enabled, so disable it
        try {
            RegDelete(STARTUP_REG_KEY, APP_NAME)
            A_TrayMenu.Uncheck("Run at startup")
        } catch as err {
            MsgBox("Failed to remove from startup: " . err.Message, "Error", 16)
        }
    } else {
        ; Currently disabled, so enable it
        try {
            RegWrite(APP_PATH, "REG_SZ", STARTUP_REG_KEY, APP_NAME)
            A_TrayMenu.Check("Run at startup")
        } catch as err {
            MsgBox("Failed to add to startup: " . err.Message, "Error", 16)
        }
    }
}