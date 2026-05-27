//
//  ShoppingListSectionContent.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 26.10.2021.
//

import SwiftUI

struct ShoppingListSectionContent<Model: ShoppingListItemModelProtocol>: View {
    let model: Model
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
