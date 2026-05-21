//
//  LargeAcceptButton.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 29.10.2021.
//

import SwiftUI

struct LargeAcceptButton: View {
    
    let title: String
    let action: () -> Void
    
    var body: some View {
        LargeButton(title: title, backgroundColor: Color("acceptColor"), action: action)
    }
}
