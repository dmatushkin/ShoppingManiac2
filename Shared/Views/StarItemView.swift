//
//  StarItemView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 29.10.2021.
//

import SwiftUI

struct StarItemView: View {
    
    let ratingValue: Int
    @Binding var rating: Int
    
    var body: some View {
        Button {
            rating = ratingValue
        } label: {
            Image(rating > (ratingValue - 1) ? "star_selected" : "star_not_selected").padding(2)
        }
        .buttonStyle(.plain)
    }
}
