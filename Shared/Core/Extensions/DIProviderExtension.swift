//
//  DIProviderExtension.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 30.10.2021.
//

import DependencyInjection
import SwiftUI

extension DIProvider {
    
    func showView<T: View>(_ view: T) -> T {
        return view
    }
}
