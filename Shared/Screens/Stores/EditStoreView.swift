//
//  EditStoreView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI

struct EditStoreView: View {
    
    let model: StoresModel
    let item: StoresItemModel
    @State private var name: String = ""
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            TextField("Store name", text: $name).textFieldStyle(.roundedBorder)
            Button("Save", action: {
                Task {
                    try await model.editStore(item: item, name: name)
                    presentation.wrappedValue.dismiss()
                }
            }).padding([.top])
            Spacer()
        }.padding().background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: {
                name = item.name
        })
    }
}
