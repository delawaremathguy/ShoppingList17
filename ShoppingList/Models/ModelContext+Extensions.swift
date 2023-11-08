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
			item.location?.itemsOptional?.removeAll() { $0.referenceID == item.referenceID }
			location.append(item: item)
//			item.location = location
		} else {
			let newItem = Item(from: representation)
			insert(newItem)
			location.append(item: newItem)
//			newItem.location = location
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
		// we will fetch it; and if it's not there, we will create it.  and
		// there's also a third possibility of having more than one, so we
		// hand all of the necessary logic off to resolveMultipleUnknownLocations
		// to figure out what to do.
		return resolveMultipleUnknownLocations()
	}
	
	// QUESTION: why can there be multiple unknown locations?
	// this only happens in a limited number of cases when you are
	// using the cloud for syncing across multiple devices on the same
	// Apple ID (this should never happen on a stand-alone device with
	// no intention of using the cloud for sharing).
	//
	// EXAMPLE:
	//
	// (1A) install and run on a first device
	// (1B) an unknown location is created on your device
	// (1C) sync with the cloud
	//
	// (2A) install and run on the second device but without
	//      the cloud turned on or available.
	// (2B) the second device creates its own unknown location,
	//      before it can discover an existing unknown location
	//      in the cloud.
	// (2C) eventually, your second device finds the cloud and
	//      discovers an already-existing unknown location.

	// this function returns an unknown location that is accepted
	// as the unique unknown location known on a single device and
	// agreed to as the unknown location by all devices sharing
	// data across the same Apple ID.
	@discardableResult
	func resolveMultipleUnknownLocations() -> Location {
		// get all unknown locations
		let locationsToCondense = allUnknownLocations()

		// create the unknown location now if we don't yet have one
		if locationsToCondense.isEmpty {
			let location = Location(suggestedName: kUnknownLocationName,
															atPosition: kUnknownLocationPosition)
			insert(location)
			return location
		}
		
		// finding one unknown location is almost always the case,
		// so return the one we found
		if locationsToCondense.count == 1 {
			return locationsToCondense[0]
		}
		
		// so we have multiple unknown locations, probably because of an
		// iCloud syncing issue when installing on multiple devices
		// on the same Apple ID.  but we want the unknown location
		// to be unique.
		//
		// there is a way to solve the problem of reducing such multiple
		// unknown locations introduced by multiple devices into one.
		// indeed, if you find multiple unknown locations:
		//   - sort them by their referenceID.uuidString values (increasing).
		//   - accept whichever appears first among them to be the real, unknown Location;
		//   - move items from all other unknown locations to the real, unknown location;
		//   - and delete all those other unknown locations.
		// over time, different devices will come to agree on the real unknown location.
		
		// note: this seems to work in my tests ... fingers crossed for now.
		let sortedLocations = locationsToCondense
			.filter { $0.isUnknownLocation }
			.sorted { loc1, loc2 in
				loc1.referenceID.uuidString < loc2.referenceID.uuidString
			}
		let realUnknown = sortedLocations[0]
		let remainingLocations = sortedLocations.dropFirst()
		for location in remainingLocations {
			location.items.forEach {
				realUnknown.append(item: $0)
//				$0.location = realUnknown
			}
			delete(location)
		}
		try? save()
		return realUnknown
	}

}
