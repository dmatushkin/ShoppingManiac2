//
//  AddStoreView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI

struct AddStoreView: View {
    
    let model: StoresModel
    @State private var name: String = ""
    
    var body: some View {
        VStack {
            TextField("Store name", text: $name).textFieldStyle(.roundedBorder)
            Button("Add", action: {
                Task {
                    try await model.addStore(name: name)
                }
            }).padding([.top])
            Spacer()
        }.padding().background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}
