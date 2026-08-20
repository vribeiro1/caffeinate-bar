import Cocoa
import IOKit.pwr_mgt
import ServiceManagement

final class SleepBlocker {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive = false

    func enable() {
        guard !isActive else { return }
        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertPreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "CaffeineBar" as CFString,
            &id
        )
        if result == kIOReturnSuccess {
            assertionID = id
            isActive = true
        }
    }

    func disable() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        isActive = false
    }
}

final class StatusController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let blocker = SleepBlocker()
    private let menu = NSMenu()
    private let stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

    override init() {
        super.init()
        menu.delegate = self
        stateItem.isEnabled = false
        menu.addItem(stateItem)
        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        if UserDefaults.standard.bool(forKey: "awakeEnabled") {
            blocker.enable()
        }
        refreshIcon()
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggle()
        }
    }

    private func toggle() {
        if blocker.isActive {
            blocker.disable()
        } else {
            blocker.enable()
        }
        UserDefaults.standard.set(blocker.isActive, forKey: "awakeEnabled")
        refreshIcon()
    }

    private func refreshIcon() {
        guard let button = statusItem.button else { return }
        let description = blocker.isActive ? "Caffeinate: On" : "Caffeinate: Off"
        let symbolName = blocker.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        let fallbackSymbolName = blocker.isActive ? "mug.fill" : "mug"

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)
            ?? NSImage(systemSymbolName: fallbackSymbolName, accessibilityDescription: description) {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = blocker.isActive ? "☕" : "○"
        }
        button.toolTip = description
    }

    func menuWillOpen(_ menu: NSMenu) {
        stateItem.title = blocker.isActive ? "Awake — On" : "Awake — Off"
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate() {
        blocker.disable()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = StatusController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.applicationWillTerminate()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
