//
//  GeometryAware.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 01.11.2021.
//

import SwiftUI

struct GeometryAware: ViewModifier {
    
    let viewName: String
    let geometryStorage: GeometryStorage
    
    func body(content: Content) -> some View {
        return content.overlay(content: {
            GeometryReader { geometry in
                updateGeometry(geometry: geometry)
            }
        })
    }
    
    private func updateGeometry(geometry: GeometryProxy) -> some View {
        geometryStorage.setFrame(geometry.frame(in: .named(geometryStorage.coordinateSpace)), viewName: viewName)
        return Color.clear
    }
}

extension View {
    func geometryAware(viewName: String, geometryStorage: GeometryStorage) -> some View {
        return modifier(GeometryAware(viewName: viewName, geometryStorage: geometryStorage))
    }
}

extension CGRect {
    
    var offset: CGSize {
        return CGSize(width: self.origin.x, height: self.origin.y + self.size.height)
    }
}

final class GeometryStorage {
    let coordinateSpace: String
    private var storage: [String: CGRect] = [:]
    
    init(coordinateSpace: String) {
        self.coordinateSpace = coordinateSpace
    }
    
    func getFrame(viewName: String) -> CGRect {
        return storage[viewName] ?? .zero
    }
    
    func setFrame(_ frame: CGRect, viewName: String) {
        storage[viewName] = frame
    }
}
