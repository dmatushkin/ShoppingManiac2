//
//  AboutScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct AboutScreen: View {
    
    let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    let longVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("\(shortVersion) build \(longVersion)").padding().font(.headline)
                    Spacer()
                }
                HStack {
                    Text("Simple application to organize your shopping lists").padding()
                    Spacer()
                }
                Spacer()
            }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all)).navigationTitle("ShoppingManiac")
        }
    }
}

struct AboutScreen_Previews: PreviewProvider {
    static var previews: some View {
        AboutScreen()
    }
}
