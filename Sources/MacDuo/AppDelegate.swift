// Modified for bluuur 2.0.6: slightly translucent near-black settings.
import AppKit
import CoreGraphics
import SwiftUI
import Carbon
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var controller: LidController?
    private var statusItemController: StatusItemController?
    private var settingsWindow: NSWindow?
    private var hotKey: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?
    private var levelSubscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Diagnostics.geometry.notice("launched, screen recording granted: \(CGPreflightScreenCaptureAccess())")
        let preferences = Preferences.shared
        let controller = LidController(preferences: preferences)
        self.controller = controller
        levelSubscription = controller.$isActive.sink { [weak self] active in
            self?.updateSettingsLevel(effectActive: active)
        }
        statusItemController = StatusItemController(controller: controller, preferences: preferences)
        controller.start()
        installMenu()
        registerShortcut()
        showSettings()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    @objc private func showSettings() {
        guard let controller else { return }
        if settingsWindow == nil {
            let host = NSHostingController(rootView: SettingsView(preferences: .shared,
                controller: controller, onQuit: { NSApp.terminate(nil) }))
            host.sizingOptions = [.preferredContentSize]
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 660),
                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "bluuur"
            window.appearance = NSAppearance(named: .darkAqua)
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(white: 0.035, alpha: 1)
            window.alphaValue = 0.94
            window.isReleasedWhenClosed = false
            window.contentViewController = host
            window.level = .normal
            settingsWindow = window
        }
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        updateSettingsLevel(effectActive: controller.isActive)
    }

    private func updateSettingsLevel(effectActive: Bool) {
        let aboveEffect = effectActive && NSApp.isActive && CGPreflightScreenCaptureAccess()
        settingsWindow?.level = aboveEffect
            ? NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) + 1) : .normal
    }

    func applicationDidResignActive(_ notification: Notification) {
        settingsWindow?.level = .normal
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        updateSettingsLevel(effectActive: controller?.isActive ?? false)
    }

    private func installMenu() {
        let menu = NSMenu()
        let app = NSMenuItem()
        let actions = NSMenu()
        let settings = NSMenuItem(title: "Настройки bluuur…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        actions.addItem(settings)
        actions.addItem(.separator())
        actions.addItem(NSMenuItem(title: "Завершить bluuur", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        app.submenu = actions
        menu.addItem(app)
        NSApp.mainMenu = menu
    }

    private func registerShortcut() {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, _, _ in
            MainActor.assumeIsolated { Preferences.shared.isEnabled = false }
            return noErr
        }
        guard InstallEventHandler(GetApplicationEventTarget(), callback, 1, &event, nil, &hotKeyHandler) == noErr else { return }
        let id = EventHotKeyID(signature: 0x4C424C52, id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_B), UInt32(controlKey | optionKey | cmdKey),
            id, GetApplicationEventTarget(), 0, &hotKey)
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }
}
