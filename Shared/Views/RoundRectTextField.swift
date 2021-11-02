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
        TextField(title, text: $input)
            .focused(focus)
            .textFieldStyle(.roundedBorder)
    }
}
