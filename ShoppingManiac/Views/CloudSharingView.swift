//
//  CloudSharingView.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 21.05.2022.
//

import CloudKit
import FactoryKit
import SwiftUI

#if os(iOS)
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let list: ShoppingListModel
    
    func makeCoordinator() -> CloudSharingCoordinator {
        CloudSharingCoordinator(list: list)
    }
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        share[CKShare.SystemFieldKey.title] = list.title
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate, .allowPublic]
        controller.modalPresentationStyle = .formSheet
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
    }
}
final class CloudSharingCoordinator: NSObject, UICloudSharingControllerDelegate {
    let list: ShoppingListModel
    init(list: ShoppingListModel) {
        self.list = list
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        list.title
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        Task { @MainActor in
            Container.shared.appEventCenter().showError(error, fallback: "Unable to save share")
        }
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        Task { @MainActor in
            Container.shared.appEventCenter().showSuccess("Share saved", detail: list.title)
        }
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        Task { @MainActor in
            Container.shared.appEventCenter().showSuccess("Sharing stopped", detail: list.title)
        }
    }
}
#else
struct CloudSharingView: View {
    let share: CKShare
    let container: CKContainer
    let list: ShoppingListModel

    var body: some View {
        EmptyView()
    }
}
#endif
