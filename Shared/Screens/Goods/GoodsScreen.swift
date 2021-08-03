//
//  GoodsScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct GoodsScreen: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct GoodsScreen_Previews: PreviewProvider {
    static var previews: some View {
        GoodsScreen().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
