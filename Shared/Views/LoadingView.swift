//
//  LoadingView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 30.01.2022.
//

import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ProgressView().progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
            Spacer()
        }.background(Color.white)
    }
}
