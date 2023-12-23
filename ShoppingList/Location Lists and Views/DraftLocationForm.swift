	//
	//  DraftLocationForm.swift
	//  ShoppingList
	//
	//  Created by Jerry on 12/10/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import SwiftUI

// the DraftLocationView is a simple Form that allows the user to edit
// the fields of a DraftLocation, which in turn stands as an editable "draft"
// of the values either associated with an existing Location, or the default
// values to use in creating a new Location.

struct DraftLocationForm: View {
	
	@Environment(\.modelContext) private var modelContext
	@Environment(ShoppingListCount.self) private var shoppingListCount
	
	// incoming data:
	// -- a DraftLocation (editable values for a Location)
	// -- an optional action to execute if the user decides to delete
	//      a draft in the case that it represents an existing Location
	@Bindable var draftLocation: DraftLocation
	var dismissAction: (() -> Void)?
	
	// trigger for adding a new item at this Location
	@State private var isAddNewItemSheetPresented = false
	// trigger for confirming deletion of the associated Location (if the
	// draft represents an existing Location that is not the Unknown Location)
	@State private var isConfirmDeleteLocationPresented = false

	// definition of whether we can offer a deletion option in this view
	// (it's a real location that's not the unknown location)
	private var associatedLocation: Location? {
		if let persistentModelID = draftLocation.persistentModelID {
			return modelContext.registeredModel<Location>(for: persistentModelID)
		} else {
			return nil
		}
	}

	// delete only makes sense if we're representing a real Location
	private var locationCanBeDeleted: Bool {
		guard let associatedLocation else {
			return false
		}
		return !associatedLocation.isUnknownLocation
	}
	
	var body: some View {
		Form {
			// 1: Name (position) and Colors.  These are shown for both an existing
			// location and a potential new Location about to be created.
			Section(header: Text("Basic Information")) {
				HStack {
					SLFormLabelText(labelText: "Name: ")
					TextField("Location name", text: $draftLocation.locationName)
				}
				ColorPicker("Location Color:", selection: $draftLocation.color)
					.bold()
			} // end of Section 1
			
			// Section 2: Delete button, if the data is associated with an existing Location
			if locationCanBeDeleted {
				Section(header: Text("Location Management")) {
					Button("Delete This Location", role: .destructive)  {
						isConfirmDeleteLocationPresented = true // trigger confirmation dialog
					}
					//.foregroundColor(Color.red)
					.hCentered()
					.confirmationDialog("Delete \'\(draftLocation.locationName)\'?",
															isPresented: $isConfirmDeleteLocationPresented,
															titleVisibility: .visible) {
						Button("Yes", role: .destructive, action: deleteLocation)
					} message: {
						Text("Are you sure you want to delete the Location named \'\(draftLocation.locationName)\'? All items at this location will be moved to the Unknown Location.  This action cannot be undone.")
					}
						
				} // end of Section
			} // end of if locationCanBeDeleted ...
			
			// Section 3: Items assigned to this Location, if we are editing a Location
			if let associatedLocation {
				Section(header: ItemsListHeader()) {
					SimpleItemsList(items: associatedLocation.items)
				}
			}
			
		} // end of Form
		.sheet(isPresented: $isAddNewItemSheetPresented) {
			NavigationStack {
				AddOrModifyItemView(initialLocation: associatedLocation ?? modelContext.unknownLocation)
			}
//			AddNewItemView(location: associatedLocation ?? modelContext.unknownLocation)
				.interactiveDismissDisabled()
		}

	} // end of var body: some View
	
	var locationItemCount: Int {
		associatedLocation?.items.count ?? 0
	}
		
	func ItemsListHeader() -> some View {
		HStack {
			Text("At this Location: \(locationItemCount) items")
			Spacer()
			Button {
				isAddNewItemSheetPresented = true
			} label: {
				Image(systemName: "plus")
			}
		}
	}
	
	// called to delete the associated location
	func deleteLocation() {
		// associatedLocation is known to exist, but we'll check anyway
		guard let associatedLocation else { return }
		// move all items at this location to the unknownLocation
		let itemsToMove = associatedLocation.items
		for item in itemsToMove {
			// this code seems a little long-winded:
			modelContext.unknownLocation.addToItems(item: item)
			// it should be enough to just write
			//    item.location = modelContext.unknownLocation
			// and let SwiftData figure it out?  testing so far
			// seems to say it mostly works, but i am suspicious.
			// item.location = modelContext.unknownLocation
		}
		modelContext.delete(associatedLocation)
		try? modelContext.save()
		dismissAction?()
	}
	
}

// this is a quick way to see a list of items associated
// with a given location that we're editing.
struct SimpleItemsList: View {
	
	@Environment(\.modelContext) private var modelContext
	@Environment(ShoppingListCount.self) private var shoppingListCount

	var items: [Item]
		
	var body: some View {
		ForEach(items) { item in
			NavigationLink {
				AddOrModifyItemView(from: item)
//				ModifyExistingItemView(item: item)
			} label: {
				HStack {
					Text(item.name)
					if item.onList {
						Spacer()
						Image(systemName: "cart")
							.foregroundStyle(.green)
					}
				}
				.contextMenu {
					ItemContextMenu(item: item)
				}
			}
		}
	}
	
	@ViewBuilder
	func ItemContextMenu(item: Item) -> some View {
		Button {
			if item.onList {
				item.markAsPurchased()
			} else {
				item.onList = true
			}
			shoppingListCount.countChanged()
		} label: {
			Text(item.onList ? "Mark as Purchased" : "Move to ShoppingList")
			Image(systemName: item.onList ? "purchased" : "cart")
		}
	}

}
