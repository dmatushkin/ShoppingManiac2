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
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(uniqueItems, id: \.self) { element in
                                Button {
                                    search = element
                                    focus.wrappedValue = false
                                } label: {
                                    HStack {
                                        Text(element)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                        }
                    }
                    .frame(maxHeight: 220)

                    Button {
                        focus.wrappedValue = false
                    } label: {
                        HStack {
                            Spacer()
                            Label("Dismiss suggestions", systemImage: "arrow.up.to.line")
                                .labelStyle(.iconOnly)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 1)
                }
                .shadow(radius: 8, y: 4)
                .offset(y: topOffset)
                .padding(.horizontal)
            }
        }
    }
}
