//
//  StepIndicatorView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct StepIndicatorView: View {
    let currentStep: Int
    let hasSelectedPreset: Bool
    let hasAddedFiles: Bool
    let isBuilding: Bool
    let isComplete: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Steps to Create Your Package")
                .font(Typography.headline())
                .foregroundColor(.primary)
            
            HStack(spacing: Spacing.lg) {
                // Step 1: Select Template
                StepItem(
                    number: 1,
                    title: "Select Template",
                    isActive: currentStep == 1,
                    isComplete: hasSelectedPreset,
                    icon: "lightbulb.fill"
                )
                
                StepConnector(isComplete: hasSelectedPreset)
                
                // Step 2: Add Files
                StepItem(
                    number: 2,
                    title: "Add Your Files",
                    isActive: currentStep == 2,
                    isComplete: hasAddedFiles,
                    icon: "photo.stack"
                )
                
                StepConnector(isComplete: hasAddedFiles)
                
                // Step 3: Build
                StepItem(
                    number: 3,
                    title: "Build Package",
                    isActive: currentStep == 3,
                    isComplete: isComplete,
                    icon: "shippingbox.fill"
                )
            }
            
            // Context-sensitive help text
            if currentStep == 1 && !hasSelectedPreset {
                HelpText(text: "Click 'Teams Example' below to configure for Microsoft Teams backgrounds", icon: "arrow.down")
            } else if currentStep == 2 && !hasAddedFiles {
                HelpText(text: "Drag your background images (PNG/JPG) or a ZIP file into the drop zone above", icon: "arrow.up")
            } else if currentStep == 3 && hasAddedFiles {
                HelpText(text: "Click 'Build Package' to create your installer", icon: "arrow.down")
            } else if isComplete {
                HelpText(text: "Package created! Deploy via Intune, Jamf, or manual installation", icon: "checkmark.circle.fill", color: .successGreen)
            }
        }
        .padding(Spacing.md)
        .background(Color.cardBackground.opacity(0.5))
        .cornerRadius(Layout.cornerRadius)
    }
}

struct StepItem: View {
    let number: Int
    let title: String
    let isActive: Bool
    let isComplete: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: 40, height: 40)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isActive ? .white : .secondaryText)
                }
            }
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(.spring(response: 0.3), value: isActive)
            
            Text(title)
                .font(Typography.caption())
                .foregroundColor(isComplete ? .primary : (isActive ? .primary : .secondaryText))
                .fontWeight(isActive ? .semibold : .regular)
        }
    }
    
    var backgroundGradient: LinearGradient {
        if isComplete {
            return LinearGradient(
                colors: [Color.successGreen, Color.successGreen.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isActive {
            return LinearGradient(
                colors: [Color.primaryAction, Color.primaryAction.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.secondaryText.opacity(0.3), Color.secondaryText.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct StepConnector: View {
    let isComplete: Bool
    
    var body: some View {
        Rectangle()
            .fill(isComplete ? Color.successGreen : Color.separatorColor)
            .frame(height: 2)
            .frame(maxWidth: 50)
            .overlay(
                Rectangle()
                    .fill(Color.successGreen)
                    .frame(width: isComplete ? 50 : 0, height: 2)
                    .animation(.easeInOut(duration: 0.3), value: isComplete)
            )
    }
}

struct HelpText: View {
    let text: String
    let icon: String
    var color: Color = .primaryAction
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundColor(color)
            Text(text)
                .font(Typography.footnote())
                .foregroundColor(.secondaryText)
        }
        .padding(.top, Spacing.xs)
    }
}