	//
	//  DraftLocation.swift
	//  ShoppingList
	//
	//  Created by Jerry on 8/1/20.
	//  Copyright © 2020 Jerry. All rights reserved.
	//

import Foundation
import SwiftData
import SwiftUI

// **** see the companion discussion over in DraftItem.swift ****
// (note: DraftItem.swift is older code and is on its way out; i will
// soon consolidate the actions of AddNewLocation and ModifyExistingLocation
// into a single view using a SwiftData model object directly to be
// similar to AddOrModifyItemView.

@Observable
class DraftLocation {
	// a SwiftData reference to a Location associated with this data
	// (nil if data for a new item that does not yet exist)
	let persistentModelID: PersistentIdentifier?
	// these are the editable data for a Location
	var locationName: String
	var position: Int
	var color: Color
	
	// this copies all the editable data from an incoming
	// Location, or sets defaults values for what will be
	// a new Location with nil-coalescing.
	init(location: Location? = nil) {
		persistentModelID = location?.persistentModelID
		locationName = location?.name ?? ""
		position = Int(location?.position ?? 0)
		color = location?.color ?? .green
	}
	
}

// MARK: -- Computed Variables

extension DraftLocation {
	
		// to do a save/commit of an Item, it must have a non-empty name
	var canBeSaved: Bool { locationName.count > 0 }
	
}

