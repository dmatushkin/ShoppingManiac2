//
//  AboutScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct AboutScreen: View {
    var body: some View {
        VStack {
            HStack {
                Text("ShoppingManiac V2").padding()
                Spacer()
            }            
            Spacer()
        }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all))
    }
}

struct AboutScreen_Previews: PreviewProvider {
    static var previews: some View {
        AboutScreen()
    }
}
