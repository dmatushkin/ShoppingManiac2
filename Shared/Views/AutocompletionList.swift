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
    
    var body: some View {
        VStack {
            Spacer().frame(height: offset.height)
            List {
                ForEach(items, id: \.self) { element in
                    HStack {
                        Text(element)
                        Spacer()
                    }.contentShape(Rectangle())
                        .onTapGesture {
                            search = element
                            focus.wrappedValue = false
                        }
                }
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.to.line")
                    Spacer()
                }.contentShape(Rectangle())
                    .onTapGesture {
                        focus.wrappedValue = false
                    }
            }.listStyle(.plain)
        }.opacity((focus.wrappedValue && items.count > 0 && items.first != search) ? 1 : 0)
    }
}
