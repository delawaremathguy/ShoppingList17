//
//  Item.swift
//  ShoppingList
//
//  Created by Jerry on 10/8/23.
//  Copyright © 2023 Jerry. All rights reserved.
//
//

import Foundation
import SwiftData
import SwiftUI

// an Item, a.k.a., a Shopping Item, is simply something you would
// purchase at a grocery store.  we allow you to set the isAvailable
// flag to indicate that something was on the shopping list when you
// went to the store, but it was no available.  and whenever you
// purchase an item on the shopping list, we update its timestamp
// so you can see when it was last purchased.
@Model
public class Item {
	let referenceID: UUID = UUID()
	
	var name: String = ""
	var quantity: Int = 1
	var onList: Bool = true
	var isAvailable: Bool = true
	var lastPurchased: Date?
	
	// relationship (each item belongs to a single location).
	// when the item is deleted, .nullify will remove any reference
	// from its associated Location.
	@Relationship(deleteRule: .nullify)
	var location: Location?
	
	// initializer used when importing data from Files.
	init(from representation: ItemRepresentation) {
		name = representation.name
		quantity = representation.quantity
		isAvailable = representation.isAvailable
		onList = representation.onList
		lastPurchased = representation.dateLastPurchased
	}
	
	// initializer used when creating an Item
	// in the AddNewItemView.
	init(from draft: DraftItem) {
		name = draft.name
		quantity = draft.quantity
		onList = draft.onList
		isAvailable = draft.isAvailable
	}
	
}

// MARK: -- Computed Variables

extension Item {
	
	// the item's color is the color of its association Location
	var color: Color { location?.color ?? .green	}
	
	// the name of its associated Location
	var locationName: String { location?.name ?? "No Name" }
	
}

// MARK: -- Useful functions

extension Item {

	// used when updating an Item in the ModifyExistingItemView.
	func updateValues(from draftItem: DraftItem) {
		name = draftItem.name
		quantity = draftItem.quantity
		onList = draftItem.onList
		isAvailable = draftItem.isAvailable
		location = draftItem.location
	}
	
	// call this function when tapping on an item in the
	// shopping list so we can timestamp it.
	func markAsPurchased() {
		onList = false
		lastPurchased = .now
	}
	
}
