//
//  MainScreenModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 30.01.2022.
//

import Foundation
import Observation

@MainActor
@Observable
final class MainScreenModel {
    var isLoaded: Bool = false
    
    init() {
        isLoaded = true
    }
}
