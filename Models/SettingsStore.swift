import Foundation
import SwiftUI

struct Hotkey: Codable, Equatable {
    var useEscape: Bool = true
    var key: String = "w"
    var useCommand: Bool = true
    var useControl: Bool = true
    var useOption: Bool = false
    var useShift: Bool = false

    func matchModifiers(_ flags: NSEvent.ModifierFlags) -> Bool {
        return flags.contains(.command) == useCommand &&
               flags.contains(.control) == useControl &&
               flags.contains(.option)  == useOption  &&
               flags.contains(.shift)   == useShift
    }

    func matchKey(_ chars: String?) -> Bool {
        guard let c = chars?.lowercased(), !c.isEmpty else { return false }
        return String(c.prefix(1)) == key.lowercased()
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var summon: Hotkey
    @Published var close: Hotkey

    private let kSummonKey = "QuickNotes.Settings.summon"
    private let kCloseKey  = "QuickNotes.Settings.close"

    init() {
        let ud = UserDefaults.standard
        if let d = ud.data(forKey: kSummonKey), let v = try? JSONDecoder().decode(Hotkey.self, from: d) {
            summon = v
        } else {
            summon = Hotkey(useEscape: false, key: "w", useCommand: true, useControl: true, useOption: false, useShift: false)
        }
        if let d = ud.data(forKey: kCloseKey), let v = try? JSONDecoder().decode(Hotkey.self, from: d) {
            close = v
        } else {
            close = Hotkey(useEscape: true, key: "q", useCommand: false, useControl: false, useOption: false, useShift: false)
        }
    }

    func persist() {
        if let d = try? JSONEncoder().encode(summon) { UserDefaults.standard.set(d, forKey: kSummonKey) }
        if let d = try? JSONEncoder().encode(close)  { UserDefaults.standard.set(d, forKey: kCloseKey) }
    }
}
