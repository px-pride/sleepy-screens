; Monitor Power Control Script for AutoHotkey v2
; Default hotkey: Win+Alt+S to turn off monitors
; You can change this to any key combination you prefer

; Constants
STARTUP_REG_KEY := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
APP_NAME := "SleepyScreens"

; Get the executable path (works for both .ahk and compiled .exe)
APP_PATH := A_IsCompiled ? A_ScriptFullPath : '"' . A_AhkPath . '" "' . A_ScriptFullPath . '"'

; Initialize startup behavior on first run
InitializeStartup()

; Create system tray menu
CreateTrayMenu()

; Turn off monitors with Win+Alt+S (on key release)
#!s up:: {
    ; Method 1: SendMessage (most reliable)
    SendMessage(0x112, 0xF170, 2, , "Program Manager")
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
    A_TrayMenu.Add("Help", ShowHelp)
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    
    ; Check the startup item if it's enabled
    if IsStartupEnabled() {
        A_TrayMenu.Check("Run at startup")
    }
    
    ; Set tooltip
    A_IconTip := "Sleepy Screens - Win+Alt+S to turn off monitors"
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
    MsgBox("Press Win+Alt+S to turn off your monitors instantly.", "Sleepy Screens - Help", 64)
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