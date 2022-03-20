//
//  ShoppingItemShareModel.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 02.02.2022.
//

import Foundation
import CloudKitSync
import CloudKit
import CoreData

/*final class ShoppingItemShareModel: CloudKitSyncItemProtocol {
    
    private let objectId: NSManagedObjectID
    
    init(objectId: NSManagedObjectID, recordId: String?, ownerName: String?, isRemote: Bool) {
        self.objectId = objectId
        self.itemRecordId = recordId
        self.itemOwnerName = ownerName
        self.isRemote = isRemote
    }
    
    static var zoneName: String { "ShareZone" }
    
    static var recordType: String { "ShoppingListItem" }
    
    static var hasDependentItems: Bool { false }
    
    static var dependentItemsRecordAttribute: String { "" }
    
    static var dependentItemsType: CloudKitSyncItemProtocol.Type { ShoppingItemShareModel.self }
    
    let isRemote: Bool
    
    func dependentItems() -> [CloudKitSyncItemProtocol] {
        []
    }
    
    private var itemRecordId: String?
    
    var recordId: String? { itemRecordId }
    
    private var itemOwnerName: String?
    
    var ownerName: String? { itemOwnerName }
    
    func setRecordId(_ recordId: String) async throws {
        itemRecordId = recordId
    }
    
    func populate(record: CKRecord) async throws {
        
    }
    
    static func store(record: CKRecord, isRemote: Bool) async throws -> CloudKitSyncItemProtocol {
        
    }
    
    func setParent(item: CloudKitSyncItemProtocol) async throws {
        
    }
}
*/
