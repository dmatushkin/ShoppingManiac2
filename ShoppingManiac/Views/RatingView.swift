//
//  RatingView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 29.10.2021.
//

import SwiftUI

struct RatingView: View {
    
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            StarItemView(ratingValue: 1, rating: $rating)
            StarItemView(ratingValue: 2, rating: $rating)
            StarItemView(ratingValue: 3, rating: $rating)
            StarItemView(ratingValue: 4, rating: $rating)
            StarItemView(ratingValue: 5, rating: $rating)
        }.padding(4).background(content: { Color("ratingBackgroundColor") }).cornerRadius(10)
    }
}
