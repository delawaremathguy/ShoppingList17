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
// used to order the Locations so that you can navigate from
// one location to another in a sequence defined by you.
@Model
public class Location {
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
	// of the associated Items is unpredictable.
	@Relationship(deleteRule: .noAction, inverse: \Item.location)
	var itemsOptional: [Item]?
	
	// used only for the creation of the unknown location.
	init(suggestedName: String? = nil, atPosition position: Int? = nil) {
		referenceID = UUID()
		if let suggestedName { name = suggestedName }
		if let position { self.position = position }
	}
	
	init(from locationRepresentation: LocationRepresentation, atPosition: Int? = nil) {
		//referenceID = locationRepresentation.id
		name = locationRepresentation.name
		red = locationRepresentation.red
		green = locationRepresentation.green
		blue = locationRepresentation.blue
		opacity = locationRepresentation.opacity
		position = atPosition ?? 1
	}
	
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
	
	// this is the programmatic interface to reading the items associated
	// with a Location, already ordered by name.
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
	
	func append(item: Item) {
		assert(item.modelContext == self.modelContext,
					 "*** trying to append item to location, but modelContexts not the same or missing.")
		// this is curious ... there must be something
		// happening, since itemsOptional appears to be non-nil even when
		// there are no associated items.
		// otherwise, how could you append anything to build a relationship?
		itemsOptional?.append(item)
	}
	
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
