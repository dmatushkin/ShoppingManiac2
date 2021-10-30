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
        Text(title)
            .padding(8)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(content: { backgroundColor })
            .cornerRadius(15)
            .onTapGesture {
                action()
            }
    }
}

struct LargeAcceptButton: View {
    
    let title: String
    let action: () -> Void
    
    var body: some View {
        LargeButton(title: title, backgroundColor: Color("acceptColor"), action: action)
    }
}

struct LargeCancelButton: View {
    
    let title: String
    let action: () -> Void
    
    var body: some View {
        LargeButton(title: title, backgroundColor: Color("cancelColor"), action: action)
    }
}
