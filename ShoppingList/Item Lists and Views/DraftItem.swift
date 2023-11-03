//
//  DraftItem.swift
//  ShoppingList
//
//  Created by Jerry on 6/28/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import Observation
import SwiftData

/*
this gives me a way to collect all the data for an Item that i might want to 
edit.  it defaults to having values appropriate for a new item upon
creation, and can be initialized from an existing Item.  this is something
i can then hand off to an edit view.  at some point, that edit view will
want to update an Item with this data, so see the function
update(using draftItem: DraftItem) defined on ModelContext

this is now a class object that conforms to Observable.
both the AddNewItemView and the ModifyExistingItemView
can create one of these as a @StateObject.
*/
@Observable
class DraftItem {
	
	// a SwiftData reference to an Item associated with this data
	// (nil if data for a new item that does not yet exist)
	let persistentModelID: PersistentIdentifier?
	
	// the properties here are those that can be edited for an Item
	var name: String
	var quantity: Int
	var location: Location
	var onList: Bool
	var isAvailable: Bool
	
	// text representation for the lastPurchased date, not editable
	let dateText: String

	// this copies all the editable data from an incoming Item.
	init(item: Item) {
		persistentModelID = item.persistentModelID
		name = item.name
		quantity = Int(item.quantity)
		location = item.location! // every item has an associated location
		onList = item.onList
		isAvailable = item.isAvailable
		dateText = item.lastPurchased?.formatted(date: .long, time: .omitted) ?? "(Never)"
	}
	
	// this creates a working draft for a new item at a
	// given location, possibly with a suggested name at
	// the call site.
	init(at location: Location, suggestedName: String? = nil) {
		persistentModelID = nil// no Item yet created
		if let suggestedName, suggestedName.count > 0 {
			name = suggestedName
		} else {
			name = "New Item"
		}
		quantity = 1
		self.location = location
		onList = true
		isAvailable = true
		dateText = "(Never)"
	}
	
// MARK: -- Computed Variables

	// to do a save/update of an Item, it must have a non-empty name
	var canBeSaved: Bool { !name.isEmpty }
	
}
