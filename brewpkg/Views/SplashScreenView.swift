//
//  SplashScreenView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/24/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var progressValue: Double = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.controlBackgroundColor).opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                VStack(spacing: Spacing.lg) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: Spacing.sm) {
                        Text("brewpkg")
                            .font(.system(size: 42, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                            .opacity(titleOpacity)
                        
                        Text("Drag. Drop. Package.")
                            .font(Typography.title3())
                            .foregroundColor(.secondaryText)
                            .opacity(subtitleOpacity)
                    }
                }
                
                Spacer()
                
                VStack(spacing: Spacing.sm) {
                    ProgressView(value: progressValue, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(Color.primaryAction)
                        .frame(width: 200)
                        .opacity(0.6)
                    
                    Text("Loading...")
                        .font(Typography.caption())
                        .foregroundColor(.tertiaryText)
                }
                .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            animateSplash()
        }
    }
    
    private func animateSplash() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
            titleOpacity = 1.0
        }
        
        withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
            subtitleOpacity = 1.0
        }
        
        withAnimation(.linear(duration: 1.5).delay(0.3)) {
            progressValue = 1.0
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}