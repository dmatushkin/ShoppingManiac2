//
//  ShoppingListShareModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 02.02.2022.
//

import Foundation
import CloudKitSync
import CloudKit
import CoreData

/*final class ShoppingListShareModel: CloudKitSyncItemProtocol {
    
    private let objectId: NSManagedObjectID
    private let itemDependents: [ShoppingItemShareModel]
    
    init(objectId: NSManagedObjectID, recordId: String?, ownerName: String?, isRemote: Bool, dependentItems: [ShoppingItemShareModel]) {
        self.objectId = objectId
        self.itemRecordId = recordId
        self.itemOwnerName = ownerName
        self.isRemote = isRemote
        self.itemDependents = dependentItems
    }
    
    static var zoneName: String { "ShareZone" }
    
    static var recordType: String { "ShoppingList" }
    
    static var hasDependentItems: Bool { true }
    
    static var dependentItemsRecordAttribute: String { "items" }
    
    static var dependentItemsType: CloudKitSyncItemProtocol.Type { ShoppingItemShareModel.self }
    
    let isRemote: Bool
    
    func dependentItems() -> [CloudKitSyncItemProtocol] {
        return itemDependents
    }
    
    private var itemRecordId: String?
    
    var recordId: String? { itemRecordId }
    
    private var itemOwnerName: String?
    
    var ownerName: String? { itemOwnerName }
    
    func setRecordId(_ recordId: String) async throws {
        
    }
    
    func populate(record: CKRecord) async throws {
        
    }
    
    static func store(record: CKRecord, isRemote: Bool) async throws -> CloudKitSyncItemProtocol {
        
    }
    
    func setParent(item: CloudKitSyncItemProtocol) async throws {
    }
}
*/
