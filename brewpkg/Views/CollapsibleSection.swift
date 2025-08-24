//
//  CollapsibleSection.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    @State private var isExpanded: Bool
    let content: () -> Content
    
    init(title: String, icon: String, isExpanded: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self._isExpanded = State(initialValue: isExpanded)
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: Layout.animationDuration)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.primaryAction)
                        .frame(width: 20)
                    
                    Text(title)
                        .font(Typography.headline())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.sectionBackground)
            .cornerRadius(Layout.cornerRadius, corners: isExpanded ? [.topLeft, .topRight] : .allCorners)
            
            // Content
            if isExpanded {
                VStack(spacing: Spacing.sm) {
                    content()
                }
                .padding(Spacing.md)
                .background(Color.cardBackground)
                .cornerRadius(Layout.cornerRadius, corners: [.bottomLeft, .bottomRight])
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color.separatorColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// Helper extension for corner-specific rounding
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension UIRectCorner {
    static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

// NSBezierPath extension for corner rounding
extension NSBezierPath {
    convenience init(roundedRect rect: CGRect, byRoundingCorners corners: UIRectCorner, cornerRadii: CGSize) {
        self.init()
        
        let topLeft = corners.contains(.topLeft) ? cornerRadii : .zero
        let topRight = corners.contains(.topRight) ? cornerRadii : .zero
        let bottomLeft = corners.contains(.bottomLeft) ? cornerRadii : .zero
        let bottomRight = corners.contains(.bottomRight) ? cornerRadii : .zero
        
        move(to: CGPoint(x: rect.minX + topLeft.width, y: rect.minY))
        
        // Top edge
        line(to: CGPoint(x: rect.maxX - topRight.width, y: rect.minY))
        if topRight != .zero {
            curve(to: CGPoint(x: rect.maxX, y: rect.minY + topRight.height),
                  controlPoint1: CGPoint(x: rect.maxX - topRight.width * 0.5, y: rect.minY),
                  controlPoint2: CGPoint(x: rect.maxX, y: rect.minY + topRight.height * 0.5))
        }
        
        // Right edge
        line(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight.height))
        if bottomRight != .zero {
            curve(to: CGPoint(x: rect.maxX - bottomRight.width, y: rect.maxY),
                  controlPoint1: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight.height * 0.5),
                  controlPoint2: CGPoint(x: rect.maxX - bottomRight.width * 0.5, y: rect.maxY))
        }
        
        // Bottom edge
        line(to: CGPoint(x: rect.minX + bottomLeft.width, y: rect.maxY))
        if bottomLeft != .zero {
            curve(to: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft.height),
                  controlPoint1: CGPoint(x: rect.minX + bottomLeft.width * 0.5, y: rect.maxY),
                  controlPoint2: CGPoint(x: rect.minX, y: rect.maxY - bottomLeft.height * 0.5))
        }
        
        // Left edge
        line(to: CGPoint(x: rect.minX, y: rect.minY + topLeft.height))
        if topLeft != .zero {
            curve(to: CGPoint(x: rect.minX + topLeft.width, y: rect.minY),
                  controlPoint1: CGPoint(x: rect.minX, y: rect.minY + topLeft.height * 0.5),
                  controlPoint2: CGPoint(x: rect.minX + topLeft.width * 0.5, y: rect.minY))
        }
        
        close()
    }
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        
        return path
    }
}

struct UIRectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = UIRectCorner(rawValue: 1 << 0)
    static let topRight = UIRectCorner(rawValue: 1 << 1)
    static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    static let bottomRight = UIRectCorner(rawValue: 1 << 3)
}