//
//  EditCategoryView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import DependencyInjection
import CoreData

struct EditCategoryView: View {
    
    let model: CategoriesModel
    let item: CategoriesItemModel?
    @State private var name: String = ""
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            TextField("Category name", text: $name).textFieldStyle(.roundedBorder)
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    presentation.wrappedValue.dismiss()
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if name.isEmpty { return }
                    Task {
                        try await model.editCategory(item: item, name: name)
                        presentation.wrappedValue.dismiss()
                    }
                })
            }.padding([.top])
            Spacer()
        }.padding()
            .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
            .onAppear(perform: {
                name = item?.name ?? ""
            }).navigationTitle("Edit category")
    }
}

struct EditCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(EditCategoryView(model: CategoriesModel(), item: CategoriesItemModel(id: NSManagedObjectID(), name: "Test category")))
    }
}
