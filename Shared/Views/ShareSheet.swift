//
//  ShareSheet.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 25.01.2022.
//

import SwiftUI

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
#elseif os(macOS)
import AppKit

struct ShareSheet: NSViewControllerRepresentable {
    let activityItems: [Any]

    func makeNSViewController(context: Context) -> NSViewController {
        let viewController = NSViewController()
        viewController.view = NSView()

        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: activityItems)
            picker.show(relativeTo: .zero, of: viewController.view, preferredEdge: .minY)
        }

        return viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
    }
}
#endif
