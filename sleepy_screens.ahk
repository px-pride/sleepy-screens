; Monitor Power Control Script for AutoHotkey v2
; Default hotkey: Win+Shift+S to turn off monitors
; You can change this to any key combination you prefer

; Turn off monitors with Win+Shift+S (on key release)
#+s up:: {
    ; Method 1: SendMessage (most reliable)
    SendMessage(0x112, 0xF170, 2, , "Program Manager")
}

; Alternative hotkeys (uncomment the one you want to use):

; Ctrl+Alt+M to turn off monitors (on key release)
; ^!m up:: {
;     SendMessage(0x112, 0xF170, 2, , "Program Manager")
; }

; F12 to turn off monitors (on key release)
; F12 up:: {
;     SendMessage(0x112, 0xF170, 2, , "Program Manager")
; }

; Win+M to turn off monitors (overrides Windows minimize all) (on key release)
; #m up:: {
;     SendMessage(0x112, 0xF170, 2, , "Program Manager")
; }

; Optional: Turn on monitors with Win+Shift+N (on key release)
; Note: Moving mouse or pressing any key will also wake monitors
#+n up:: {
    ; Move mouse by 1 pixel to wake monitors
    MouseMove(1, 0, 0, "R")
}

; Optional: Toggle monitors on/off with single hotkey (on key release)
; Win+Shift+T to toggle
#+t up:: {
    ; This checks if monitors are likely off by checking idle time
    if (A_TimeIdlePhysical > 1000) {
        ; Monitors are probably off, wake them
        MouseMove(1, 0, 0, "R")
    } else {
        ; Monitors are on, turn them off
        SendMessage(0x112, 0xF170, 2, , "Program Manager")
    }
}

; Exit script with Win+Shift+Escape (on key release)
#+Escape up::ExitApp()