; Monitor Power Control Script for AutoHotkey v2
; Default hotkey: Win+Shift+S to turn off monitors
; You can change this to any key combination you prefer

; Turn off monitors with Win+Shift+S (on key release)
#+s up:: {
    ; Method 1: SendMessage (most reliable)
    SendMessage(0x112, 0xF170, 2, , "Program Manager")
}