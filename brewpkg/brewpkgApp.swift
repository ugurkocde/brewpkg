//
//  brewpkgApp.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI
import Sparkle

// Custom updater delegate for better update messages
class UpdaterDelegate: NSObject, SPUUpdaterDelegate, ObservableObject {
    @Published var updateAvailable = false
    @Published var updateVersion: String?
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        DispatchQueue.main.async {
            self.updateAvailable = true
            self.updateVersion = item.displayVersionString
            
            // Show a system notification
            let notification = NSUserNotification()
            notification.title = "brewpkg Update Available"
            notification.informativeText = "Version \(item.displayVersionString) is available. Click to update."
            notification.soundName = NSUserNotificationDefaultSoundName
            notification.hasActionButton = true
            notification.actionButtonTitle = "Update"
            
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        DispatchQueue.main.async {
            self.updateAvailable = false
            self.updateVersion = nil
        }
    }
}

@main
struct brewpkgApp: App {
    @State private var showSplash = true
    @StateObject private var updaterDelegate = UpdaterDelegate()
    @State private var windowTitle = "brewpkg"

    private let updaterController: SPUStandardUpdaterController

    init() {
        let delegate = UpdaterDelegate()
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: delegate, userDriverDelegate: nil)
        _updaterDelegate = StateObject(wrappedValue: delegate)
    }

    var body: some Scene {
        WindowGroup(windowTitle) {
            ZStack {
                ContentView(updaterController: updaterController, updaterDelegate: updaterDelegate, windowTitle: $windowTitle)
                    .opacity(showSplash ? 0 : 1)
                    .animation(.easeIn(duration: 0.5), value: showSplash)

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}

struct CheckForUpdatesView: NSViewRepresentable {
    let updater: SPUUpdater
    
    func makeNSView(context: Context) -> NSView {
        let button = NSButton(title: "Check for Updates...", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.target = updater
        button.action = #selector(SPUUpdater.checkForUpdates)
        return button
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
