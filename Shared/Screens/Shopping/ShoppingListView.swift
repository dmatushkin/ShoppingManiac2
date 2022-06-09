//
//  ShoppingListView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI
import DependencyInjection
import CoreData

struct ShoppingListSectionTitle: View {
    let title: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(title.uppercased()).font(Font.caption).foregroundColor(.gray)
        }
    }
}

struct ShoppingListSectionContent: View {
    @ObservedObject var model: ShoppingListViewModel
    let section: ShoppingListSection
    
    var body: some View {
        ForEach(section.subsections) { subsection in
            ShoppingListSectionTitle(title: subsection.title)
            ForEach(subsection.items) { item in
                ShoppingListItemView(item: item, model: model)
            }
        }
        if !section.subsections.isEmpty && !section.items.isEmpty {
            ShoppingListSectionTitle(title: "No category")
        }
        ForEach(section.items) { item in
            ShoppingListItemView(item: item, model: model)
        }
    }
}

struct ShoppingListView: View {
    
    @StateObject private var model: ShoppingListViewModel
    private let listModel: ShoppingListModel
    
    init(listModel: ShoppingListModel) {
        _model = StateObject(wrappedValue: ShoppingListViewModel())
        self.listModel = listModel
    }
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    ForEach(model.output.sections) { section in
                        Section(content: {
                            ShoppingListSectionContent(model: model, section: section)
                        }, header: {
                            Text(section.title).font(section.isStore ? Font.title3 : Font.caption).foregroundColor(.gray)
                        }).listRowBackground(Color("backgroundColor"))
                    }
                    ForEach(model.output.items) { item in
                        ShoppingListItemView(item: item, model: model)
                    }
                }.listStyle(.grouped).safeAreaInset(edge: .bottom) {
                    VStack {
                        HStack(alignment: .center) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 25, weight: .light))
                                .padding(10)
                                .onTapGesture {
                                    model.showShareSheet = true
                                }.background(content: { Color.black.opacity(0.2) })
                                .cornerRadius(10)
                                .padding(10)
                            Spacer()
                            Image("add_purchase_large")
                                .padding(10)
                                .onTapGesture {
                                    model.showAddSheet = true
                                }.background(content: { Color.black.opacity(0.2) })
                                .cornerRadius(10)
                                .padding(10)
                        }.padding(.bottom, 15)
                            .background(content: {
                                Color("bottomPanelColor")
                            })
                    }
                }
            }.onAppear(perform: { model.listModel = listModel })
                .navigationTitle(Text(listModel.title))
                .background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
                .sheet(isPresented: $model.showAddSheet, onDismiss: nil) {
                    EditShoppingListItemView(model: model, item: nil)
                }.sheet(item: $model.itemToShow) { item in
                    EditShoppingListItemView(model: model, item: item)
                }.sheet(item: $model.dataToShare) { item in
                    ShareSheet(activityItems: [item.url])
                }.sheet(item: $model.sharedList) { sharedList in
                    CloudSharingView(share: sharedList.share, container: sharedList.container, list: listModel)
                }.confirmationDialog("Share", isPresented: $model.showShareSheet) {
                    Button("Share with iCloud") {
                        model.shareByiCloud(model: listModel)
                    }
                    Button("Share with file") {
                        model.shareByFile(model: listModel)
                    }
                }
            LoadingView().opacity(model.isLoading ? 0.9 : 0)
        }
    }
}

struct ShoppingListView_Previews: PreviewProvider {
    static var previews: some View {
        DIProvider.shared
            .register(forType: DAOProtocol.self, dependency: DAOStub.self)
            .showView(
                NavigationView {
                    ShoppingListView(listModel: ShoppingListModel(id: NSManagedObjectID(), uniqueId: "1241234", name: "test list", date: Date()))
                }
            )
    }
}
