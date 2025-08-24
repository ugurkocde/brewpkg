//
//  brewpkgApp.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI
import Sparkle

// Custom updater delegate for better update messages
class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    // Optional delegate methods can be added here if needed
}

@main
struct brewpkgApp: App {
    @State private var showSplash = true
    
    private let updaterController: SPUStandardUpdaterController
    private let updaterDelegate = UpdaterDelegate()
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: updaterDelegate, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(updaterController: updaterController)
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
