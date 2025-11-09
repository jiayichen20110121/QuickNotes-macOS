import Foundation
import AppKit
import Carbon.HIToolbox

// ⚠️ 这里的字典值必须是 UInt32，不是 Int
private let letterToKeyCode: [String: UInt32] = [
    "a": UInt32(kVK_ANSI_A), "b": UInt32(kVK_ANSI_B), "c": UInt32(kVK_ANSI_C), "d": UInt32(kVK_ANSI_D),
    "e": UInt32(kVK_ANSI_E), "f": UInt32(kVK_ANSI_F), "g": UInt32(kVK_ANSI_G), "h": UInt32(kVK_ANSI_H),
    "i": UInt32(kVK_ANSI_I), "j": UInt32(kVK_ANSI_J), "k": UInt32(kVK_ANSI_K), "l": UInt32(kVK_ANSI_L),
    "m": UInt32(kVK_ANSI_M), "n": UInt32(kVK_ANSI_N), "o": UInt32(kVK_ANSI_O), "p": UInt32(kVK_ANSI_P),
    "q": UInt32(kVK_ANSI_Q), "r": UInt32(kVK_ANSI_R), "s": UInt32(kVK_ANSI_S), "t": UInt32(kVK_ANSI_T),
    "u": UInt32(kVK_ANSI_U), "v": UInt32(kVK_ANSI_V), "w": UInt32(kVK_ANSI_W), "x": UInt32(kVK_ANSI_X),
    "y": UInt32(kVK_ANSI_Y), "z": UInt32(kVK_ANSI_Z)
]

final class GlobalHotkeyCenter {
    static let shared = GlobalHotkeyCenter()

    private var summonRef: EventHotKeyRef?
    private var closeRef:  EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // 回调
    var onSummon: (() -> Void)?
    var onClose:  (() -> Void)?

    // 注册或重注册
    func register(summon: Hotkey, close: Hotkey) {
        unregisterAll()

        // 安装一次事件处理器
        if eventHandler == nil {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                     eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, eventRef, userData in
                    guard let ud = userData else { return noErr }
                    let `self` = Unmanaged<GlobalHotkeyCenter>
                        .fromOpaque(ud).takeUnretainedValue()

                    var hkID = EventHotKeyID()
                    GetEventParameter(eventRef,
                                      EventParamName(kEventParamDirectObject),
                                      EventParamType(typeEventHotKeyID),
                                      nil,
                                      MemoryLayout<EventHotKeyID>.size,
                                      nil,
                                      &hkID)

                    switch hkID.id {
                    case 1: self.onSummon?()
                    case 2: self.onClose?()
                    default: break
                    }
                    return noErr
                },
                1, &spec,
                Unmanaged.passUnretained(self).toOpaque(),
                &eventHandler
            )
        }

        // 召唤：ctrl+cmd+w（或自定义）
        if let code = letterToKeyCode[summon.key.lowercased()] {
            var id = EventHotKeyID(signature: OSType(0x51554b4e), id: UInt32(1)) // 'QUKN'
            let mods = toCarbonFlags(cmd: summon.useCommand, ctrl: summon.useControl, opt: summon.useOption, shift: summon.useShift)
            RegisterEventHotKey(code, mods, id, GetApplicationEventTarget(), 0, &summonRef)
        }

        // 关闭：Esc 或自定义
        if close.useEscape {
            var id = EventHotKeyID(signature: OSType(0x51554b4e), id: UInt32(2))
            RegisterEventHotKey(UInt32(kVK_Escape), 0, id, GetApplicationEventTarget(), 0, &closeRef)
        } else if let code = letterToKeyCode[close.key.lowercased()] {
            var id = EventHotKeyID(signature: OSType(0x51554b4e), id: UInt32(2))
            let mods = toCarbonFlags(cmd: close.useCommand, ctrl: close.useControl, opt: close.useOption, shift: close.useShift)
            RegisterEventHotKey(code, mods, id, GetApplicationEventTarget(), 0, &closeRef)
        }
    }

    func unregisterAll() {
        if let s = summonRef { UnregisterEventHotKey(s); summonRef = nil }
        if let c = closeRef  { UnregisterEventHotKey(c);  closeRef  = nil }
    }

    deinit { unregisterAll() }
}

private func toCarbonFlags(cmd: Bool, ctrl: Bool, opt: Bool, shift: Bool) -> UInt32 {
    var f: UInt32 = 0
    if cmd   { f |= UInt32(cmdKey) }
    if ctrl  { f |= UInt32(controlKey) }
    if opt   { f |= UInt32(optionKey) }
    if shift { f |= UInt32(shiftKey) }
    return f
}
