//
//  DesignSystem.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

// MARK: - Spacing System
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
}

// MARK: - Typography
enum Typography {
    static func largeTitle() -> Font {
        .system(size: 34, weight: .bold, design: .default)
    }
    
    static func title1() -> Font {
        .system(size: 28, weight: .regular, design: .default)
    }
    
    static func title2() -> Font {
        .system(size: 22, weight: .regular, design: .default)
    }
    
    static func title3() -> Font {
        .system(size: 20, weight: .regular, design: .default)
    }
    
    static func headline() -> Font {
        .system(size: 17, weight: .semibold, design: .default)
    }
    
    static func body() -> Font {
        .system(size: 17, weight: .regular, design: .default)
    }
    
    static func callout() -> Font {
        .system(size: 16, weight: .regular, design: .default)
    }
    
    static func subheadline() -> Font {
        .system(size: 15, weight: .regular, design: .default)
    }
    
    static func footnote() -> Font {
        .system(size: 13, weight: .regular, design: .default)
    }
    
    static func caption() -> Font {
        .system(size: 12, weight: .regular, design: .default)
    }
    
    static func monospaced() -> Font {
        .system(size: 13, design: .monospaced)
    }
}

// MARK: - Colors
extension Color {
    // Semantic Colors
    static let primaryAction = Color.accentColor
    static let successGreen = Color(NSColor.systemGreen)
    static let warningOrange = Color(NSColor.systemOrange)
    static let errorRed = Color(NSColor.systemRed)
    static let secondaryText = Color(NSColor.secondaryLabelColor)
    static let tertiaryText = Color(NSColor.tertiaryLabelColor)
    static let quaternaryText = Color(NSColor.quaternaryLabelColor)
    
    // Background Colors
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let windowBackground = Color(NSColor.windowBackgroundColor)
    static let separatorColor = Color(NSColor.separatorColor)
    static let controlAccent = Color(NSColor.controlAccentColor)
    
    // Custom semantic colors
    static let dropZoneBackground = Color(NSColor.controlBackgroundColor).opacity(0.5)
    static let dropZoneHover = Color.accentColor.opacity(0.1)
    static let sectionBackground = Color(NSColor.controlBackgroundColor).opacity(0.3)
}

// MARK: - Layout Constants
enum Layout {
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 6
    static let borderWidth: CGFloat = 1
    static let formLabelWidth: CGFloat = 120
    static let minButtonWidth: CGFloat = 80
    static let maxContentWidth: CGFloat = 800
    static let animationDuration: Double = 0.3
}

// MARK: - Component Styles
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(Color.cardBackground)
            .cornerRadius(Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline())
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCornerRadius)
                    .fill(isEnabled ? Color.primaryAction : Color.gray)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.body())
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCornerRadius)
                    .stroke(Color.secondaryText.opacity(0.3), lineWidth: Layout.borderWidth)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FormRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            content
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.headline())
            .foregroundColor(.primary)
            .padding(.bottom, Spacing.sm)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func formRow() -> some View {
        modifier(FormRowStyle())
    }
    
    func sectionHeader() -> some View {
        modifier(SectionHeaderStyle())
    }
    
    func fadeTransition() -> some View {
        transition(.opacity.animation(.easeInOut(duration: Layout.animationDuration)))
    }
    
    func slideTransition() -> some View {
        transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ).animation(.easeInOut(duration: Layout.animationDuration)))
    }
}

// MARK: - Custom Components
struct RequiredFieldIndicator: View {
    var body: some View {
        Text("*")
            .foregroundColor(.errorRed)
            .font(Typography.caption())
    }
}

struct ValidationMessage: View {
    let message: String
    let type: ValidationType
    
    enum ValidationType {
        case error, warning, info
        
        var color: Color {
            switch self {
            case .error: return .errorRed
            case .warning: return .warningOrange
            case .info: return .primaryAction
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.footnote)
            Text(message)
                .font(Typography.footnote())
                .foregroundColor(type.color)
            Spacer()
        }
        .padding(Spacing.sm)
        .background(type.color.opacity(0.1))
        .cornerRadius(Layout.smallCornerRadius)
    }
}