//
//  LargeButton.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 29.10.2021.
//

import SwiftUI

struct LargeButton: View {
        
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
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(backgroundColor)).foregroundStyle(.white)
                .northWestShadow()
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
