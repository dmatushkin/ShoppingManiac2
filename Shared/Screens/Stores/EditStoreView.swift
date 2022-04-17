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
    @State private var categories: [String] = []
    @State private var isEditable = false
    @FocusState private var editFocused: Bool
    @State private var showingPopover = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            RoundRectTextField(title: "Store name", input: $name, focus: $editFocused)
            HStack {
                Text("Categories")
                Spacer()
                Button("Add") {
                    showingPopover = true
                }.sheet(isPresented: $showingPopover, onDismiss: nil) {
                    AddCategoryToStoreView(categories: $categories, showingPopover: $showingPopover)
                }
            }
            List {
                ForEach(categories, id: \.self) { item in
                    Text(item).swipeActions {
                        Button("Delete") {
                            if let index = categories.firstIndex(of: item) {
                                categories.remove(at: index)
                            }
                        }.tint(.red)
                        Button("Reorder") {
                            self.isEditable = true
                        }
                    }
                }.onMove(perform: {from, to in
                    categories.move(fromOffsets: from, toOffset: to)
                    self.isEditable = false
                }).onLongPressGesture {
                    withAnimation {
                        self.isEditable = true
                    }
                }
            }.listStyle(.plain)
                .environment(\.editMode, isEditable ? .constant(.active) : .constant(.inactive))
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    dismiss()
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if name.isEmpty { return }
                    Task {
                        try await model.editStore(item: item, name: name, categories: categories)
                        dismiss()
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
                if let item = item {
                    Task {
                        categories = try await model.getStoreCategories(item: item).map({ $0.name })
                    }
                }
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
