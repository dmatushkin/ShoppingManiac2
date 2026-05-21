//
//  EditStoreView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.10.2021.
//

import SwiftUI
import Factory

protocol EditStoreModelProtocol: AnyObject {
    func editStore(item: StoresItemModel?, name: String, categories: [String]) async
    func getStoreCategories(item: StoresItemModel) async -> [CategoriesItemModel]
}

struct EditStoreView<Model: EditStoreModelProtocol&Sendable>: View {
    
    let model: Model
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
            }
            .listStyle(.plain)
            #if os(iOS)
            .environment(\.editMode, isEditable ? .constant(.active) : .constant(.inactive))
            #endif
            HStack {
                LargeCancelButton(title: "Cancel", action: {
                    dismiss()
                })
                LargeAcceptButton(title: item == nil ? "Add" : "Save", action: {
                    if name.isEmpty { return }
                    Task {
                        await model.editStore(item: item, name: name, categories: categories)
                        dismiss()
                    }
                })
            }.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        editFocused = false
                    } label: {
                        Label("Dismiss keyboard", systemImage: "keyboard.chevron.compact.down")
                            .labelStyle(.iconOnly)
                    }
                }
            }.padding([.top])
            Spacer()
        }.padding()
            .background(Color("backgroundColor").ignoresSafeArea())
            .onAppear(perform: {
                name = item?.name ?? ""
                if let item = item {
                    Task {
                        categories = await model.getStoreCategories(item: item).map({ $0.name })
                    }
                }
            }).navigationTitle("Edit store")
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    EditStoreView(model: StoresModel(), item: StoresItemModel(id: UUID().uuidString, name: "Test store"))
}
