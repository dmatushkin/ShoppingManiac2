//
//  ShoppingListView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI
import FactoryKit

struct ShoppingListView: View {
    
    @State private var model: ShoppingListViewModel
    @State private var searchText = ""
    private let listModel: ShoppingListModel
    
    private var displayedOutput: ShoppingListOutput {
        model.output.filtered(by: searchText)
    }
    
    init(listModel: ShoppingListModel) {
        _model = State(wrappedValue: ShoppingListViewModel())
        self.listModel = listModel
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                ForEach(displayedOutput.sections) { section in
                    Section(content: {
                        ShoppingListSectionContent(model: model, section: section)
                    }, header: {
                        Text(section.title).font(section.isStore ? Font.title3 : Font.caption).foregroundStyle(.gray)
                    }).listRowBackground(Color("backgroundColor"))
                }
                ForEach(displayedOutput.items) { item in
                    ShoppingListItemView(item: item, model: model)
                }
            }
            #if os(iOS)
            .listStyle(.grouped)
            #else
            .listStyle(.inset)
            #endif
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 88)
                    .allowsHitTesting(false)
            }
            .overlay {
                if displayedOutput.isEmpty {
                    if searchText.shoppingNormalizedName.isEmpty {
                        ContentUnavailableView("No items", systemImage: "cart", description: Text("Tap Add item to start this list."))
                    } else {
                        ContentUnavailableView.search
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
            .onAppear(perform: { model.listModel = listModel })
            .navigationTitle(Text(listModel.title))
            .background(Color("backgroundColor").ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        model.showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("shoppingList.shareButton")
                    .confirmationDialog("Share", isPresented: $model.showShareSheet) {
                        Button("Share with file") {
                            model.shareByFile(model: listModel)
                        }
                    }
                }
            }
            .sheet(isPresented: $model.showAddSheet, onDismiss: nil) {
                EditShoppingListItemView(model: model, item: nil)
            }.sheet(item: $model.itemToShow) { item in
                EditShoppingListItemView(model: model, item: item)
            }.sheet(item: $model.dataToShare) { item in
                ShareSheet(activityItems: [item.url])
            }
            Button {
                model.showAddSheet = true
            } label: {
                Label("Add item", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.accentColor))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("shoppingList.addItemButton")
            .accessibilityLabel("Add item")
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            LoadingView().opacity(model.isLoading ? 0.9 : 0)
        }
    }
}

private extension ShoppingListOutput {
    var isEmpty: Bool {
        sections.isEmpty && items.isEmpty
    }
    
    func filtered(by searchText: String) -> ShoppingListOutput {
        let query = searchText.shoppingCanonicalName
        guard !query.isEmpty else { return self }
        
        return ShoppingListOutput(
            sections: sections.compactMap { $0.filtered(by: query) },
            items: items.filter { $0.matches(query) }
        )
    }
}

private extension ShoppingListSection {
    func filtered(by query: String) -> ShoppingListSection? {
        if title.shoppingCanonicalName.contains(query) {
            return self
        }
        
        let filteredSubsections = subsections.compactMap { $0.filtered(by: query) }
        let filteredItems = items.filter { $0.matches(query) }
        guard !filteredSubsections.isEmpty || !filteredItems.isEmpty else { return nil }
        
        return ShoppingListSection(
            id: id,
            title: title,
            isStore: isStore,
            subsections: filteredSubsections,
            items: filteredItems
        )
    }
}

private extension ShoppingListItemModel {
    func matches(_ query: String) -> Bool {
        [title, amount, store, category, price]
            .contains { $0.shoppingCanonicalName.contains(query) }
    }
}

#if DEBUG
#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    NavigationStack {
        ShoppingListView(listModel: ShoppingListModel(id: UUID().uuidString, name: "test list", date: Date()))
    }
}
#endif
