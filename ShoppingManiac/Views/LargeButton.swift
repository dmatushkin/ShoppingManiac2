//
//  LargeButton.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 29.10.2021.
//

import SwiftUI

struct LargeButton: View {
    
    @Environment(\.isEnabled) private var isEnabled
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    init(title: String, backgroundColor: Color, action: @escaping () -> Void) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Capsule().fill(backgroundColor))
                .foregroundStyle(isEnabled ? .white : .black.opacity(0.6))
                .northWestShadow()
                .opacity(isEnabled ? 1 : 0.45)
            }
        .buttonStyle(.plain)
    }
}

#Preview {
    Group {
        LargeAcceptButton(title: "Save", action: {})
            .padding()
            .frame(width: 375, height: 50)
        LargeCancelButton(title: "Cancel", action: {})
            .padding()
            .frame(width: 375, height: 50)
        HStack {
            LargeCancelButton(title: "Cancel", action: {})
            LargeAcceptButton(title: "Save", action: {})
        }.padding().frame(width: 375, height: 50)
    }
}
