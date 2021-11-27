//
//  LargeButton.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 29.10.2021.
//

import SwiftUI

struct LargeButton: View {
    
    struct LargeButtonStyle: ButtonStyle {
        let backgroundColor: Color
        
        func makeBody(configuration: Configuration) -> some View {
            Group {
                if configuration.isPressed {
                    configuration
                        .label
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(backgroundColor)).foregroundColor(.white)
                        .southEastShadow().opacity(0.8)
                } else {
                    configuration
                        .label
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(backgroundColor)).foregroundColor(.white)
                        .northWestShadow()
                }
            }            
        }
    }
    
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    init(title: String, backgroundColor: Color, action: @escaping () -> Void) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(title, action: {
            action()
        }).buttonStyle(LargeButtonStyle(backgroundColor: backgroundColor))
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

struct Large_Buttons_Previews: PreviewProvider {
    static var previews: some View {
        LargeAcceptButton(title: "Save", action: {})
            .padding()
            .frame(width: 375, height: 50).previewLayout(.sizeThatFits)
        LargeCancelButton(title: "Cancel", action: {})
            .padding()
            .frame(width: 375, height: 50).previewLayout(.sizeThatFits)
        HStack {
            LargeCancelButton(title: "Cancel", action: {})
            LargeAcceptButton(title: "Save", action: {})
        }.padding().frame(width: 375, height: 50).previewLayout(.sizeThatFits)
    }
}
