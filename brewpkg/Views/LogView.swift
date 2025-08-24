//
//  LogView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct LogView: View {
    let logOutput: String
    @State private var isExpanded = false
    
    var body: some View {
        GroupBox {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(logOutput.isEmpty ? "Build output will appear here..." : logOutput)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(logOutput.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .textSelection(.enabled)
                        .id("logBottom")
                }
                .frame(height: isExpanded ? 400 : 150)
                .background(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(4)
                .onChange(of: logOutput) { _ in
                    withAnimation {
                        proxy.scrollTo("logBottom", anchor: .bottom)
                    }
                }
            }
        } label: {
            HStack {
                Label("Build Log", systemImage: "terminal")
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.borderless)
                
                if !logOutput.isEmpty {
                    Button(action: copyLog) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .help("Copy log to clipboard")
                    
                    Button(action: clearLog) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Clear log")
                }
            }
        }
    }
    
    private func copyLog() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logOutput, forType: .string)
    }
    
    private func clearLog() {
        // This would need to be connected to the parent view's state
    }
}