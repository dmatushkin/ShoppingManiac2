//
//  SceneDelegate.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.05.2022.
//

import CloudKit
import Factory
import SwiftUI

#if os(iOS)
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        Task { @MainActor in
            Container.shared.appEventCenter().shoppingListsChanged()
            Container.shared.appEventCenter().showSuccess("Shared list updated", detail: nil)
        }
    }
}
#endif
