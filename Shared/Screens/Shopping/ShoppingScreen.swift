//
//  ShoppingScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct ShoppingScreen: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ShoppingScreen_Previews: PreviewProvider {
    static var previews: some View {
        ShoppingScreen().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
