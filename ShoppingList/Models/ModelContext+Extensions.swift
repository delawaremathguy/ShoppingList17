//
//  ModelContext+Extensions.swift
//  ShoppingList
//
//  Created by Jerry on 10/10/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import Foundation
import SwiftData

extension ModelContext {
	
	// MARK: -- Item helpers
		
	// locates an Item with the given referenceID, if any.  the
	// incoming argument is an optional for convenience: it makes
	// the call site a little cleaner in some cases.
	func item(withID referenceID: UUID?) -> Item? {
		guard let referenceID else { return nil }
		let predicate = #Predicate<Item> { $0.referenceID == referenceID }
		var fetchDescriptor = FetchDescriptor<Item>(predicate: predicate)
		fetchDescriptor.fetchLimit = 1	// UUIDs are unique, right?
		do {
			let items = try fetch<Item>(fetchDescriptor)
			return items.first
		} catch let error {
			print("*** cannot fetch items: \(error.localizedDescription)")
			return nil
		}
	}
	
	func itemCount() -> Int {
		let fetchDescriptor = FetchDescriptor<Item>()
		do {
			let count = try fetchCount(fetchDescriptor)
			return count
		} catch let error {
			print("*** cannot count items: \(error.localizedDescription)")
			return 0
		}
	}
	
	// MARK: -- Location Helpers
	
	func locationCount() -> Int {
		let fetchDescriptor = FetchDescriptor<Location>()
		do {
			let count = try fetchCount(fetchDescriptor)
			return count
		} catch let error {
			print("*** cannot count locations: \(error.localizedDescription)")
			return 0
		}
	}

		
	private func updateOrInsert(representation: ItemRepresentation, at location: Location) {
		if let item = item(withID: representation.id) {
			// we'll not update any property here, although we will make sure that
			// it is associated with the location that was given to us
			item.location?.itemsOptional?.removeAll() { $0.referenceID == item.referenceID }
			location.append(item: item)
		} else {
			let newItem = Item(from: representation)
			insert(newItem)
			location.append(item: newItem)
			//insert(newItem)
		}
	}

	func updateOrInsert(representation: LocationRepresentation) {
		// if the incoming representation is for an archived unknownLocation, then
		// we will only be adding items to our (existing) unknown location, and we will
		// not update any location properties: the UL and its customization is unique to us.
		if representation.visitationOrder == kUnknownLocationPosition {
			for itemRep in representation.items {
				updateOrInsert(representation: itemRep, at: unknownLocation)
			}
			return
		}

		// do we already have a location that matches what's incoming?
		// if we do, we will not update any properties; but we will check to see
		// that we have all the associated items.
		if let foundLocation = location(withID: representation.id) {
			// possible point of discussion: should we update any current 
			// location properties in this case?
			//      YOU GET TO DECIDE!
			// there's a case we should copy/update the name at least; but you would
			// not want to update the colors or position because we may
			// be using this data already and put it into our own order.
			representation.items.forEach {
				updateOrInsert(representation: $0, at: foundLocation)
			}
			return
		}

		//  all that's left is to add a new location; copy over property values from the
		// incoming data, except for the position, which must be computed
		// so that the new location goes to the end of the list of non-UL locations.
		let lastPosition = lastLocationPosition() ?? 0
		let newLocation = Location(from: representation, atPosition: lastPosition + 1)
		insert(newLocation)
		// finally add items for this new location
		for itemRep in representation.items {
			updateOrInsert(representation: itemRep, at: newLocation)
		}

	}
	
	// finds the highest `user-defined` location position (avoids the unknown location).
	func lastLocationPosition() -> Int? {
		var fetchDescriptor = FetchDescriptor<Location>()
		fetchDescriptor.propertiesToFetch = [\.position]
		do {
			let locations = try fetch<Location>(fetchDescriptor)
			return locations.map({ $0.position }).filter({ $0 < kUnknownLocationPosition }).max()
		} catch let error {
			print("*** cannot fetch locations: \(error.localizedDescription)")
			return nil
		}
	}

	func location(withID referenceID: UUID?) -> Location? {
		guard let referenceID else { return nil }
		let predicate = #Predicate<Location> { $0.referenceID == referenceID }
		var fetchDescriptor = FetchDescriptor<Location>(predicate: predicate)
		fetchDescriptor.fetchLimit = 1
		do {
			let locations = try fetch<Location>(fetchDescriptor)
			return locations.first
		} catch let error {
			print("*** cannot fetch location with referenceID: \(error.localizedDescription)")
			return nil
		}
	}
	
	@discardableResult func createUnknownLocation() -> Location {
		let unknownLocation = Location(
			suggestedName: kUnknownLocationName,
			atPosition: kUnknownLocationPosition
		)
		insert(unknownLocation)
		return unknownLocation
	}
	
	var unknownLocation: Location {
		// we only keep one "UnknownLocation" in the data store.  you can find
		// it easily: its position is the largest 32-bit integer. to make the
		// app work, however, we need this default location to exist!
		//
		// so if we ever need to get the unknown location from the database, 
		// we will fetch it; and if it's not there, we will create it.
		
		// NOTE TO SELF: it's possible that you could have multiple
		// unknown locations: create one on your device, have it sync
		// with the cloud, then install and run the app on the second
		// device but without the cloud turned on (or available).  the
		// second device will create its own "unknown" location, but
		// then later discover the unknown location that's in the
		// cloud.
		// there is a way to solve this problem; just not right here,
		// right now (!)

		let predicate = #Predicate<Location> { $0.position == kUnknownLocationPosition }
		let fetchDescriptor = FetchDescriptor<Location>(predicate: predicate)
		do {
			let locations = try fetch(fetchDescriptor)
			if locations.isEmpty {
				return createUnknownLocation()
			}
			return locations[0]
		} catch let error {
			fatalError("*** cannot fetch locations: \(error.localizedDescription)")
		}
	}

}