//
//  AutocompletionList.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 01.11.2021.
//

import SwiftUI

struct AutocompletionList: View {
    
    @Binding var items: [String]
    @Binding var search: String
    let focus: FocusState<Bool>.Binding
    let offset: CGSize

    private var uniqueItems: [String] {
        var seenItems = Set<String>()
        return items.filter { seenItems.insert($0).inserted }
    }
    
    private var isVisible: Bool {
        focus.wrappedValue && !uniqueItems.isEmpty && uniqueItems.first != search
    }

    private var topOffset: CGFloat {
        offset.height.isFinite ? max(offset.height, 0) : 0
    }
    
    var body: some View {
        Group {
            if isVisible {
                List {
                    ForEach(uniqueItems, id: \.self) { element in
                        Button {
                            search = element
                            focus.wrappedValue = false
                        } label: {
                            HStack {
                                Text(element)
                                Spacer()
                            }.contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        focus.wrappedValue = false
                    } label: {
                        HStack {
                            Spacer()
                            Label("Dismiss suggestions", systemImage: "arrow.up.to.line")
                                .labelStyle(.iconOnly)
                            Spacer()
                        }.contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .offset(y: topOffset)
            }
        }
    }
}
