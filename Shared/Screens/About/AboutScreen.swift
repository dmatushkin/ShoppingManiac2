//
//  AboutScreen.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 12.06.2021.
//

import SwiftUI

struct AboutScreen: View {
    
    @StateObject private var model: AboutModel
    let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    let longVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    
    init() {
        _model = StateObject(wrappedValue: AboutModel())
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("\(shortVersion) build \(longVersion)").padding().font(.headline)
                Spacer()
            }
            HStack {
                Text("Simple application to organize your shopping lists").padding()
                Spacer()
            }
            
            LargeAcceptButton(title: "Create backup") {
                model.makeBackup()
            }.padding()
            Spacer()
        }.background(Color("backgroundColor").edgesIgnoringSafeArea(.all)).navigationTitle("ShoppingManiac")
            .sheet(item: $model.dataToShare) { item in
                ShareSheet(activityItems: [item.url])
            }
    }
}

struct AboutScreen_Previews: PreviewProvider {
    static var previews: some View {
        AboutScreen()
    }
}
