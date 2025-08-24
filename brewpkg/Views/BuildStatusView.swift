//
//  BuildStatusView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct BuildStatusView: View {
    @ObservedObject var buildEngine: BuildEngine
    let outputPackageURL: URL?
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Build status indicator
            if case .building = buildEngine.state {
                BuildingStateView(progress: buildEngine.progress)
            } else if case .completed = buildEngine.state {
                CompletedStateView(outputURL: outputPackageURL)
            } else if case .failed(let error) = buildEngine.state {
                FailedStateView(error: error)
            }
        }
        .animation(.easeInOut(duration: Layout.animationDuration), value: buildEngine.state)
    }
}

struct BuildingStateView: View {
    let progress: Double
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                // Animated spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.9)
                
                Text("Building Package...")
                    .font(Typography.headline())
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Percentage
                Text("\(Int(progress * 100))%")
                    .font(Typography.headline())
                    .foregroundColor(.primaryAction)
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.separatorColor.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryAction, Color.primaryAction.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(Spacing.md)
        .background(Color.primaryAction.opacity(0.05))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color.primaryAction.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CompletedStateView: View {
    let outputURL: URL?
    @State private var showCheckmark = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Success indicator with animation
            ZStack {
                Circle()
                    .fill(Color.successGreen.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.successGreen)
                    .scaleEffect(showCheckmark ? 1.0 : 0.5)
                    .opacity(showCheckmark ? 1.0 : 0.0)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showCheckmark = true
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Package Built Successfully")
                    .font(Typography.headline())
                    .foregroundColor(.primary)
                
                if let url = outputURL {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.successGreen)
                            .font(.footnote)
                        
                        Button(url.lastPathComponent) {
                            NSWorkspace.shared.selectFile(
                                url.path,
                                inFileViewerRootedAtPath: url.deletingLastPathComponent().path
                            )
                        }
                        .buttonStyle(.link)
                        .font(Typography.footnote())
                        .help("Reveal in Finder")
                        
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url.path, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.footnote)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy path")
                    }
                }
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.successGreen.opacity(0.05))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color.successGreen.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FailedStateView: View {
    let error: Error
    @State private var showError = false
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Error indicator
            ZStack {
                Circle()
                    .fill(Color.errorRed.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.errorRed)
                    .scaleEffect(showError ? 1.0 : 0.5)
                    .opacity(showError ? 1.0 : 0.0)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showError = true
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Build Failed")
                    .font(Typography.headline())
                    .foregroundColor(.primary)
                
                Text(error.localizedDescription)
                    .font(Typography.footnote())
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.errorRed.opacity(0.05))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color.errorRed.opacity(0.3), lineWidth: 1)
        )
    }
}