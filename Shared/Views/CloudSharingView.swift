//
//  CloudSharingView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.05.2022.
//

import CloudKit
import SwiftUI

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let list: ShoppingListModel
    
    func makeCoordinator() -> CloudSharingCoordinator {
        CloudSharingCoordinator(list: list)
    }
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        share[CKShare.SystemFieldKey.title] = list.name
        let controller = UICloudSharingController(share: share, container: container)
        controller.modalPresentationStyle = .formSheet
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
    }
}

final class CloudSharingCoordinator: NSObject, UICloudSharingControllerDelegate {
    let persistance = PersistenceController.shared
    let list: ShoppingListModel
    init(list: ShoppingListModel) {
        self.list = list
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        list.name
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("Failed to save share: \(error)")
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("Saved the share")
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
    }
}
