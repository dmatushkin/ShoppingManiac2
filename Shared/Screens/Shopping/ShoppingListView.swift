//
//  ShoppingListView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI
import CoreData
import Factory

struct ShoppingListView: View {
    
    @State private var model: ShoppingListViewModel
    private let listModel: ShoppingListModel
    
    init(listModel: ShoppingListModel) {
        _model = State(wrappedValue: ShoppingListViewModel())
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
                            Text(section.title).font(section.isStore ? Font.title3 : Font.caption).foregroundStyle(.gray)
                        }).listRowBackground(Color("backgroundColor"))
                    }
                    ForEach(model.output.items) { item in
                        ShoppingListItemView(item: item, model: model)
                    }
                }.listStyle(.grouped).safeAreaInset(edge: .bottom) {
                    VStack {
                        HStack(alignment: .center) {
                            Button {
                                model.showShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .labelStyle(.iconOnly)
                                    .font(.system(size: 25, weight: .light))
                                    .padding(10)
                                    .background(content: { Color.black.opacity(0.2) })
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .confirmationDialog("Share", isPresented: $model.showShareSheet) {
                                Button("Share with iCloud") {
                                    model.shareByiCloud(model: listModel)
                                }
                                Button("Share with file") {
                                    model.shareByFile(model: listModel)
                                }
                            }
                            .padding(10)
                            Spacer()
                            Button {
                                model.showAddSheet = true
                            } label: {
                                Label {
                                    Text("Add item")
                                } icon: {
                                    Image("add_purchase_large")
                                }
                                .labelStyle(.iconOnly)
                                .padding(10)
                                .background(content: { Color.black.opacity(0.2) })
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .padding(10)
                        }.padding(.bottom, 15)
                            .background(content: {
                                Color("bottomPanelColor")
                            })
                    }
                }
            }.onAppear(perform: { model.listModel = listModel })
                .navigationTitle(Text(listModel.title))
                .background(Color("backgroundColor").ignoresSafeArea())
                .sheet(isPresented: $model.showAddSheet, onDismiss: nil) {
                    EditShoppingListItemView(model: model, item: nil)
                }.sheet(item: $model.itemToShow) { item in
                    EditShoppingListItemView(model: model, item: item)
                }.sheet(item: $model.dataToShare) { item in
                    ShareSheet(activityItems: [item.url])
                }.sheet(item: $model.sharedList) { sharedList in
                    CloudSharingView(share: sharedList.share, container: sharedList.container, list: listModel)
                }
            LoadingView().opacity(model.isLoading ? 0.9 : 0)
        }
    }
}

#Preview {
    let _ = Container.shared.dao.register(factory: { DAOStub() })
    NavigationStack {
        ShoppingListView(listModel: ShoppingListModel(id: NSManagedObjectID(), uniqueId: "1241234", name: "test list", date: Date()))
    }
}
