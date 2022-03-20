//
//  MainScreenModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 30.01.2022.
//

import Foundation

@MainActor
final class MainScreenModel: ObservableObject {
    @Published var isLoaded: Bool = false
    
    init() {
        Task {
            isLoaded = true
        }
    }
}
