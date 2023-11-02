//
//  ArchiveFormat.swift
//  ShoppingList
//
//  Created by Jerry on 7/25/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import Foundation

	// a simple struct representation of an Item that we use to
	// save to/restore from disk.
struct ItemRepresentation: Codable {
	var id: UUID
	var name: String
	var onList: Bool
	var isAvailable: Bool
	var quantity: Int
	var dateLastPurchased: Date?
	
	init(from item: Item) {
		id = item.referenceID
		name = item.name
		onList = item.onList
		isAvailable = item.isAvailable
		quantity = item.quantity
		// this was initially left out
		dateLastPurchased = item.lastPurchased
	}
}

	// a simple struct representation of a Location that we use to
	// save to/restore from disk.  note that this includes an array
	// representing associated Items.
struct LocationRepresentation: Codable {
	var id: UUID
	var name: String
	var visitationOrder: Int
	var red: Double
	var green: Double
	var blue: Double
	var opacity: Double
	var items: [ItemRepresentation]
	
	init(from location: Location) {
		id = location.referenceID
		name = location.name
		visitationOrder = Int(location.position)
		red = location.red
		green = location.green
		blue = location.blue
		opacity = location.opacity
		items = []
		for item in location.items {
			items.append(ItemRepresentation(from: item))
		}
	}
}
