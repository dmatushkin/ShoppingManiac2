//
//  StoresScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI
import Factory

struct StoresScreen: View {
    
    @StateObject private var model: StoresModel
    @FocusState private var editFocused: Bool
    
    init() {
        _model = StateObject(wrappedValue: StoresModel())
    }
    
    var body: some View {
        NavigationView {
            VStack {
                RoundRectTextField(title: "Search", input: $model.searchString, focus: $editFocused).padding()
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
                }.listStyle(.plain)
            }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: {
                            model.showAddSheet = true
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Image(systemName: "keyboard.chevron.compact.down").onTapGesture {
                            editFocused = false
                        }
                    }
                }.navigationTitle("Stores")
            VStack {
                Spacer()
                HStack {
                    Spacer()
                }
                Spacer()
            }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
        }.onAppear(perform: {
            model.reload()
        }).sheet(isPresented: $model.showAddSheet, onDismiss: nil, content: {
            EditStoreView(model: model, item: nil)
        })
    }
}

struct StoresScreen_Previews: PreviewProvider {
    static var previews: some View {
        Container.shared.dao.register(factory: { DAOStub() })
        return StoresScreen()
    }
}
