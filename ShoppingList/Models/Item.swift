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

@Model 
public class Item {
	let referenceID: UUID = UUID()
	
	var name: String = ""
	var quantity: Int = 1
	var onList: Bool = true
	var isAvailable: Bool = true
	var lastPurchased: Date?
	
	// relationship (each item belongs to a single location)
	// when deleted, .nullify will remove its reference from
	// the associated Locations
	@Relationship(deleteRule: .nullify)
	var location: Location?
	
	init(from representation: ItemRepresentation) {
		name = representation.name
		quantity = representation.quantity
		isAvailable = representation.isAvailable
		onList = representation.onList
		lastPurchased = representation.dateLastPurchased
	}
	
	init(from draft: DraftItem) {
		name = draft.name
		quantity = draft.quantity
		onList = draft.onList
		isAvailable = draft.isAvailable
//		draft.location.itemsOptional?.append(self)
	}
	
}

// MARK: -- Computed Variables

extension Item {
	
	// the color of its association Location
	var color: Color { location?.color ?? .green	}
	
	// the name of its associated Location
	var locationName: String { location?.name ?? "No Name" }
	
}

// MARK: -- Useful functions

extension Item {

	func updateValues(from draftItem: DraftItem) {
		name = draftItem.name
		quantity = draftItem.quantity
		onList = draftItem.onList
		isAvailable = draftItem.isAvailable
		location = draftItem.location
	}
	
	func markAsPurchased() {
		onList = false
		lastPurchased = .now
	}
	
}
