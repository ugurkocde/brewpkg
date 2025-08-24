//
//  FormFieldView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct FormFieldView<Content: View>: View {
    let label: String
    let isRequired: Bool
    let content: () -> Content
    
    init(label: String, isRequired: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.isRequired = isRequired
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Spacer()
                if isRequired {
                    RequiredFieldIndicator()
                }
                Text(label)
                    .font(Typography.body())
                    .foregroundColor(.primary)
            }
            .frame(width: Layout.formLabelWidth, alignment: .trailing)
            
            content()
                .frame(maxWidth: .infinity)
        }
        .formRow()
    }
}

struct FormTextField: View {
    let placeholder: String
    @Binding var text: String
    var isValid: Bool = true
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.roundedBorder)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCornerRadius)
                    .stroke(isValid ? Color.clear : Color.errorRed.opacity(0.5), lineWidth: 1)
            )
    }
}

struct FormSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .sectionHeader()
            
            VStack(spacing: Spacing.sm) {
                content()
            }
            .cardStyle()
        }
    }
}