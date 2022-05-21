//
//  SceneDelegate.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.05.2022.
//

import CloudKit
import SwiftUI

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        guard let shareStore = PersistenceController.shared.sharedPersistentStore else { return }
        let persistentContainer = PersistenceController.shared.container
        persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: shareStore) { _, error in
            if let error = error {
                print("acceptShareInvitation error :\(error)")
            }
            GlobalCommands.reloadTopList.send()
        }
    }
}
