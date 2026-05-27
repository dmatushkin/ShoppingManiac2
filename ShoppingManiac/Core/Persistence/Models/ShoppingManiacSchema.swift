//
//  ShoppingManiacSchema.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 27.05.2026.
//

import SwiftData

enum ShoppingManiacSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            ShoppingList.self,
            ShoppingListItem.self,
            Good.self,
            Category.self,
            Store.self,
            CategoryStoreOrder.self
        ]
    }
}

enum ShoppingManiacMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ShoppingManiacSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

enum ShoppingManiacSchema {
    static var current: Schema {
        Schema(versionedSchema: ShoppingManiacSchemaV1.self)
    }
}
