//
//  Location.swift
//  ShoppingList
//
//  Created by Jerry on 10/8/23.
//  Copyright © 2023 Jerry. All rights reserved.
//
//

import SwiftData
import SwiftUI

let kUnknownLocationName = "Unknown Location"
let kUnknownLocationPosition: Int = Int(INT32_MAX)

// a Location, a.k.a., an area of a grocery store where items
// of a certain type can be found.  the `position` value is
// used to relatively order Locations so that you can navigate from
// one location to another in a sequence defined by you.
@Model
public class Location {
	// see comment in Item model concerning the use of this UUID.
	let referenceID: UUID = UUID()
	
	var name: String = ""
	var position: Int = 1
	// color components for this location
	var red: Double = 0.85
	var blue: Double = 0.85
	var green: Double = 0.85
	var opacity: Double = 1.0
	
	// relationship (this location has many items).  note that when
	// we delete a Location, we'll handle all the associated items
	// ourself, so SwiftData should take no action for us.
	// note: the name is `itemsOptional` to remind me that this must
	// be optional to work with iCloud, but also that i do not
	// want to use this directly: it's really a Set and the order
	// of the associated Items is unpredictable.  and frankly, i
	// want to keep it private (this may change in the future).
	@Relationship(deleteRule: .noAction, inverse: \Item.location)
	fileprivate var itemsOptional: [Item]?
	
	// used only for the creation of the unknown location.
	init(suggestedName: String? = nil, atPosition position: Int? = nil) {
		if let suggestedName { name = suggestedName }
		if let position { self.position = position }
	}
	
	// used to create a Location in SwiftData, given a representation
	// of a Location's data that was exported and is now being imported.
	init(from locationRepresentation: LocationRepresentation, atPosition: Int? = nil) {
		name = locationRepresentation.name
		red = locationRepresentation.red
		green = locationRepresentation.green
		blue = locationRepresentation.blue
		opacity = locationRepresentation.opacity
		position = atPosition ?? 1
	}
	
	// used to create a Location in SwiftData when the user wants
	// to add a new location, based on information collected in
	// a draftLocation.
	init(from draftLocation: DraftLocation, atPosition: Int? = nil) {
		name = draftLocation.locationName
		if let components = draftLocation.color.cgColor?.components {
			red = Double(components[0])
			green = Double(components[1])
			blue = Double(components[2])
			opacity = Double(components[3])
		} else {
			red = 0.0
			green = 1.0
			blue = 0.0
			opacity = 0.5
		}
		position = atPosition ?? 1
	}

}

// MARK: -- Computed Variables

extension Location {
	
	// this provides programmatic access for reading the items
	// associated with a Location as a real array and
	// already sorted by name.
	var items: [Item] {
		let array = itemsOptional ?? []
		return array.sorted(by: \.name)
	}
	
	// simplified test of "is the unknown location"
	var isUnknownLocation: Bool { position == kUnknownLocationPosition }

	// manages a SwiftUI color in terms of component values
	var color: Color {
		get { Color(red: red, green: green, blue: blue, opacity: opacity) }
		set {
			if let components = newValue.cgColor?.components {
				red = components[0]
				green = components[1]
				blue = components[2]
				opacity = components[3]
			}
		}
	}
	
	// MARK: -- Useful Functions
	
	// note to self: this function has come and gone during
	// development. i would prefer to link a location to an item
	// with the statement:
	//   item.location = location
	// (this is how i would have done it in Core Data, so i would
	// not have to call the CD implementation of an addToItems
	// function.)
	//
	// but we can do it the other-way-round: append the item to
	// the location's optional array of items. this is basically
	// the equivalent addToItems function of CD and you would write:
	//   location.append(item: item)
	//
	// and from testing, it seems that using this append form may be
	// required to work properly with observation, and such is implied
	// in this article by Mohammed Azam:
	//   https://azamsharp.com/2023/07/04/the-ultimate-swift-data-guide.html
	//
	// note: was named `append`, but now renamed to `addToItems`, which
	// is not only a better name, but makes it more like what Core Data
	// would supply for you.
	func addToItems(item: Item) {
		// you probably want to remove this assertion in practice, but
		// i found it useful when getting my sea legs in SwiftData,
		// to be sure i have inserted a Location into the SwiftData
		// context before linking an Item to it.
		assert(item.modelContext == self.modelContext,
					 "*** trying to append item to location, but modelContexts not the same or missing.")

		// this is curious ... itemsOptional appears to be non-nil even when
		// there are no associated items. otherwise, how could you append
		// anything to build a relationship?
		itemsOptional?.append(item)
	}
	
	// this is the inverse of addToItems.
	func removeFromItems(item: Item) {
		itemsOptional?.removeAll() {
			$0.referenceID == item.referenceID
		}
	}
	
	// used to update an existing Location in the ModifyExistingLocationView,
	// based on data values of a DraftLocation.
	func updateValues(from draftLocation: DraftLocation) {
		name = draftLocation.locationName
		if let components = draftLocation.color.cgColor?.components {
			red = Double(components[0])
			green = Double(components[1])
			blue = Double(components[2])
			opacity = Double(components[3])
		} else {
			red = 0.0
			green = 1.0
			blue = 0.0
			opacity = 0.5
		}
	}
	
}
