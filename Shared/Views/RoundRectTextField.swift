//
//  RoundRectTextField.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 02.11.2021.
//

import SwiftUI

struct RoundRectTextField: View {
    let title: String
    @Binding var input: String
    let focus: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.caption2).foregroundColor(.gray).opacity(input.isEmpty ? 0 : 1)
            TextField(title, text: $input)
                .focused(focus)
                .textFieldStyle(.roundedBorder)
        }
    }
}
