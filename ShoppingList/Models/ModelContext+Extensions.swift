//
//  ModelContext+Extensions.swift
//  ShoppingList
//
//  Created by Jerry on 10/10/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import Foundation
import SwiftData

// in SL16, some of the CRUD functionality appearing below was supplied
// by the Location and Item classes themselves via static functions.
// here it makes more sense to have the modelContext do that.
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
	
	// a simple "how many items do we have" computation.
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
	
	// a simple "how many locations do we have" computation.
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
		
	// used for importing Items from an archive file.  if we have the
	// item, we'll just be sure it's at the right Location; otherwise,
	// we'll add a new Item to the Location with the given data.
	private func updateOrInsert(representation: ItemRepresentation, at location: Location) {
		if let item = item(withID: representation.id) {
			// we'll not update any property here, although we will make sure that
			// it is associated with the location that was given to us.
			// although this code seems a little long-winded?  would it be
			// enough to just write
			//    item.location = location
			// and let SwiftData figure it out?
//			item.location?.itemsOptional?.removeAll() { $0.referenceID == item.referenceID }
//			location.append(item: item)
			item.location = location
		} else {
			let newItem = Item(from: representation)
			insert(newItem)
			newItem.location = location
//			location.append(item: newItem)
		}
	}

	// used for importing Locations from an archive file.  if this
	// represents the unknown location, we'll move any items to
	// our existing unknown location; if we already have the
	// location, we'll manage the associated items; otherwise,
	// we'll add a new Location with a high position number,
	// at the end.
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
	private func lastLocationPosition() -> Int? {
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

	// locates an Location with the given referenceID, if any.  the
	// incoming argument is an optional for convenience: it makes
	// the call site a little cleaner in some cases.
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
	
	// creates an unknown location on your device.
	@discardableResult 
	private func createUnknownLocation() -> Location {
		let unknownLocation = Location(suggestedName: kUnknownLocationName,
																	 atPosition: kUnknownLocationPosition)
		insert(unknownLocation)
		return unknownLocation
	}
	
	// finds all Unknown Locations.  yes, we'd like there to be only one,
	// but because of cloud latency, there could be more than one.
	private func allUnknownLocations() -> [Location] {
		let predicate = #Predicate<Location> { $0.position == kUnknownLocationPosition }
		let fetchDescriptor = FetchDescriptor<Location>(predicate: predicate)
		do {
			let locations = try fetch(fetchDescriptor)
			return locations
		} catch let error {
			print("*** cannot fetch locations: \(error.localizedDescription)")
			return []
		}

	}
	
	// finds the unknown location on your device, creating it if necessary.
	var unknownLocation: Location {
		// we only keep one "UnknownLocation" in the data store.  you can find
		// it easily: its position is the largest 32-bit integer. to make the
		// app work, however, we need this default location to exist before
		// we start adding Items.
		//
		// so if we ever need to get the unknown location from the database,
		// we will fetch it; and if it's not there, we will create it.
		
		// NOTE TO SELF: it's possible that you could have multiple
		// unknown locations: create one on your device, have it sync
		// with the cloud, then install and run the app on the second
		// device but without the cloud turned on (or available).  the
		// second device will create its own "unknown" location, but
		// then later discover the unknown location that's in the
		// cloud.  the function realUnknownLocationAfterResolution will
		// try to resolve any ambiguity based on the fetch below.
		return condenseMultipleUnknownLocations()
	}
	
	@discardableResult
	func condenseMultipleUnknownLocations(from locations: [Location]? = nil) -> Location {
		
		// incoming: a list of locations that look like they are unknown locations,
		// but if nil, then we have to go find them first
		var locationsToCondense: [Location]
		if locations == nil || locations!.isEmpty {
			locationsToCondense = allUnknownLocations()
		} else {
			locationsToCondense = locations!
		}
		
		if locationsToCondense.isEmpty {
			return createUnknownLocation()
		}
		// there is a way to solve the problem of reducing multiple unknown
		// locations introduced by cloud latency into one. if you find multiple
		// unknown locations, then
		//   -- sort them by their referenceID.uuidString values (increasing).
		//   -- accept whichever appears first among them to be the real, unknown Location;
		//   -- move items from all other unknown locations to the real, unknown location;
		//   -- and delete all those other unknown locations.
		// over time, different devices will come to agree on the real unknown location.
		
		// note: this is still under some testing ...
		let sortedLocations = locationsToCondense
			.filter({ $0.isUnknownLocation })
			.sorted { loc1, loc2 in
				loc1.referenceID.uuidString < loc2.referenceID.uuidString
			}
		let realUnknown = sortedLocations[0]
		let remainingLocations = sortedLocations.dropFirst()
		for location in remainingLocations {
			location.items.forEach { $0.location = realUnknown }
			delete(location)
		}
		return realUnknown
	}

}
