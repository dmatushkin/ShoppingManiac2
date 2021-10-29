//
//  LargeButton.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 29.10.2021.
//

import SwiftUI

struct LargeButton: View {
    
    let title: String
    let backroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Text(title).padding(8).frame(maxWidth: .infinity).foregroundColor(.white).background(content: { backroundColor }).cornerRadius(15).onTapGesture {
            action()
        }
    }
}

struct LargeAcceptButton: View {
    
    let title: String
    let action: () -> Void
    
    var body: some View {
        LargeButton(title: title, backroundColor: Color("acceptColor"), action: action)
    }
}

struct LargeCancelButton: View {
    
    let title: String
    let action: () -> Void
    
    var body: some View {
        LargeButton(title: title, backroundColor: Color("cancelColor"), action: action)
    }
}
