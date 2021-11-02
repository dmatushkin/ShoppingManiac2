//
//  EditStoreView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import DependencyInjection
import CoreData

struct EditStoreView: View {
    
    let model: StoresModel
    let item: StoresItemModel?
    @State private var name: String = ""
    @FocusState private var editFocused: Bool
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            RoundRectTextField(title: "Store name", input: $name, focus: $editFocused)
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    presentation.wrappedValue.dismiss()
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if name.isEmpty { return }
                    Task {
                        try await model.editStore(item: item, name: name)
                        presentation.wrappedValue.dismiss()
                    }
                })
            }.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Image(systemName: "keyboard.chevron.compact.down").onTapGesture {
                        editFocused = false
                    }
                }
            }.padding([.top])
            Spacer()
        }.padding()
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: {
                name = item?.name ?? ""
            }).navigationTitle("Edit store")
    }
}

struct EditStoreView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(EditStoreView(model: StoresModel(), item: StoresItemModel(id: NSManagedObjectID(), name: "Test store")))
    }
}
