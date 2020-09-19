//
//  ShoppinngListSwipeActions.swift
//  ShoppingManiacUI
//
//  Created by Dmitry Matyushkin on 9/19/20.
//

import Foundation
import SwiftUI
import Introspect

struct ShoppingListSwipeActions: ViewModifier {

	@ObservedObject var coordinator: Coordinator

	init(editAction: @escaping (IndexPath) -> Void, deleteAction: @escaping (IndexPath) -> Void) {
		coordinator = Coordinator(editAction: editAction, deleteAction: deleteAction)
	}

	func body(content: Content) -> some View {

		return content
			.introspectTableView { tableView in
				tableView.delegate = self.coordinator
			}
	}

	class Coordinator: NSObject, ObservableObject, UITableViewDelegate {

		init(editAction: @escaping (IndexPath) -> Void, deleteAction: @escaping (IndexPath) -> Void) {
			self.editAction = editAction
			self.deleteAction = deleteAction
		}

		private let editAction: (IndexPath) -> Void
		private let deleteAction: (IndexPath) -> Void

		func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
			return .delete
		}

		func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

			tableView.cellForRow(at: indexPath)?.selectionStyle = .none

			let editAction = UIContextualAction(style: .normal, title: "Edit") {[unowned self] action, view, completionHandler in
				self.editAction(indexPath)
				completionHandler(true)
			}

			let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {[unowned self] action, view, completionHandler in
				self.deleteAction(indexPath)
				completionHandler(true)
			}

			let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])

			return configuration
		}
	}
}

extension List {
	func swipeActions(editAction: @escaping (_ path: IndexPath) -> Void, deleteAction: @escaping (_ path: IndexPath) -> Void) -> some View {
		return self.modifier(ShoppingListSwipeActions(editAction: editAction, deleteAction: deleteAction))
	}
}
