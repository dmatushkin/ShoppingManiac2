//
//  StoresScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import DependencyInjection

struct StoresScreen: View {
    
    @StateObject private var model = StoresModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(model.items) { item in
                    NavigationLink(destination: {
                        NavigationLazyView(EditStoreView(model: model, item: item))
                    }, label: {
                        Text(item.name)
                    }).listRowBackground(Color("backgroundColor"))
                }.onDelete(perform: {indexSet in
                    Task {
                        try await model.removeStore(offsets: indexSet)
                    }
                })
            }.listStyle(.grouped)
                .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
                .toolbar {
                    Button(action: {
                        model.showAddSheet = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }.navigationTitle("Stores")
        }.sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditStoreView(model: model, item: nil)
        })
    }
}

struct StoresScreen_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(StoresScreen())
    }
}
