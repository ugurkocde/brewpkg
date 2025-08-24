//
//  HeaderView.swift
//  brewpkg
//
//  Created by Ugur Koc on 8/23/25.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                
                Text("brewpkg")
                    .font(Typography.largeTitle())
                    .foregroundColor(.primary)
            }
            
            Text("Drag. Drop. Package.")
                .font(Typography.subheadline())
                .foregroundColor(.secondaryText)
        }
        .padding(.vertical, Spacing.md)
    }
}