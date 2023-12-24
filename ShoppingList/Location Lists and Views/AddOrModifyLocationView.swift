//
//  AddOrModifyLocationView.swift
//  ShoppingList
//
//  Created by Jerry on 12/24/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftUI

/*
 the AddOrModifyLocationView can be opened:
 -- via a navigation link from the LocationsView to edit an
    existing shopping item,
 -- or in a sheet from the LocationsView when we're adding
    a new Item (although please wrap us in a navigationStack
    when doing this).
 
 see the comments in AddOrModifyItemView, since this code is
 quite similar.
 */

struct AddOrModifyLocationView: View {
	
	@Environment(\.modelContext) private var modelContext
	@Environment(\.dismiss) private var dismiss
	@Environment(ShoppingListCount.self) private var shoppingListCount
	
	// incoming data:
	// -- a Location (when editing a Location, whether in the model context)
	//    or not).
	@Bindable var location: Location
	
	// trigger for adding a new item at this Location
	@State private var isAddNewItemSheetPresented = false
	// trigger for confirming deletion of the location
	@State private var isConfirmDeleteLocationPresented = false
	
	// definition of whether we can offer a deletion option in this view
	// (it's a real location that's not the unknown location)
	private var addingNewLocation: Bool
	
	init(from location: Location) {
		self.location = location
		addingNewLocation = false
	}
	
	init() {
		self.location = Location()
		addingNewLocation = true
	}
	
	var body: some View {
		Form {
			// 1: Name (position) and Colors.  These are shown for both an existing
			// location and a potential new Location about to be created.
			Section(header: Text("Basic Information")) {
				HStack {
					SLFormLabelText(labelText: "Name: ")
					TextField("Location name", text: $location.name)
				}
				ColorPicker("Location Color:", selection: $location.color)
					.bold()
			} // end of Section 1
			
			// Section 2: Delete button, applicable only if we're editing an
			// existing location that is not the unknown location
			if !addingNewLocation && !location.isUnknownLocation {
				Section(header: Text("Location Management")) {
					Button("Delete This Location", role: .destructive)  {
						isConfirmDeleteLocationPresented = true // trigger confirmation dialog
					}
					.hCentered()
					.confirmationDialog("Delete \'\(location.name)\'?",
															isPresented: $isConfirmDeleteLocationPresented,
															titleVisibility: .visible) {
						Button("Yes", role: .destructive, action: deleteLocation)
					} message: {
						Text("Are you sure you want to delete the Location named \'\(location.name)\'? All items at this location will be moved to the Unknown Location.  This action cannot be undone.")
					}
					
				} // end of Section
			} // end of if locationCanBeDeleted ...
			
			// Section 3: Items assigned to this Location, if we are editing 
			// an existing location
			if !addingNewLocation {
				Section(header: ItemsListHeader()) {
					SimpleItemsList(items: location.items)
				}
			}
			
		} // end of Form
		.sheet(isPresented: $isAddNewItemSheetPresented) {
			NavigationStack {
				AddOrModifyItemView(initialLocation: location)
			}
			//			AddNewItemView(location: associatedLocation ?? modelContext.unknownLocation)
			.interactiveDismissDisabled()
		}
		.toolbar {
			if addingNewLocation {
				ToolbarItem(placement: .cancellationAction, content: cancelButton)
				ToolbarItem(placement: .confirmationAction, content: saveButton)
			} else {
				ToolbarItem(placement: .navigationBarLeading, content: customBackButton)
			}
		}
		.navigationBarTitle(addingNewLocation ? "Add New Location" : "Modify Location")
		.navigationBarTitleDisplayMode(.inline)
		.navigationBarBackButtonHidden(true)

	} // end of var body: some View
		
	func ItemsListHeader() -> some View {
		HStack {
			Text("At this Location: \(location.items.count) items")
			Spacer()
			Button {
				isAddNewItemSheetPresented = true
			} label: {
				Image(systemName: "plus")
			}
		}
	}
	
	// called to delete an existing location ... note that
	// this can only be called in the case that we are editing
	// an existing location that is not the unknown location.
	func deleteLocation() {
		// move all items at this location to the unknownLocation
		let itemsToMove = location.items
		for item in itemsToMove {
			modelContext.unknownLocation.addToItems(item: item)
		}
		modelContext.delete(location)
		try? modelContext.save()
		dismiss()
	}
	
	// MARK: - Save and Cancel buttons for adding a New Location
	
	// the cancel button
	func cancelButton() -> some View {
		Button("Cancel") {
			dismiss()
		}
	}
	
	// the save button ... cannot save unless the location
	// has sufficient info (i.e. a non-empty name)
	func saveButton() -> some View {
		Button("Save") {
			// set position at the end and insert into the model context
			let lastPosition = modelContext.lastLocationPosition() ?? 0
			location.position = lastPosition + 1
			modelContext.insert(location)
			dismiss()
		}
		.disabled(location.name.count == 0)
	}

	// MARK: - Custom Back button for editing an existing Location
	
	func customBackButton() -> some View {
		//...  see comments in AddOrModifyItemView about using
		// our own back button.
		Button {
			dismiss()	// this was a live edit, so nothing to do
		} label: {
			HStack(spacing: 5) {
				Image(systemName: "chevron.backward")
				Text("Back")
			}
		}
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
