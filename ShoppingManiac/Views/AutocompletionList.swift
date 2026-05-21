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
    
    private var isVisible: Bool {
        focus.wrappedValue && !items.isEmpty && items.first != search
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: offset.height)
            List {
                ForEach(items, id: \.self) { element in
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
            }.listStyle(.plain)
        }
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
    }
}
