//
//  ShoppingListSectionTitle.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI

struct ShoppingListSectionTitle: View {
    let title: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(title.uppercased()).font(Font.caption).foregroundStyle(.gray)
        }
    }
}
