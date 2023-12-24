//
//  AddOrModifyItemView.swift
//  ShoppingList
//
//  Created by Jerry on 12/22/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftData
import SwiftUI

/*
 the AddOrModifyItemView can be opened:
 -- via a navigation link from the ShoppingListView or the
    AllMyItemsView or the AddOrModifyLocationView to edit an
    existing shopping item,
 -- or in a sheet from the ShoppingListView or the
    AllMyItemsView or the AddOrModifyLocationView when we're adding
    a new Item (although please wrap us in a navigationStack
		when doing this).
*/

struct AddOrModifyItemView: View {
	
	@Environment(\.modelContext) private var modelContext
	@Environment(\.dismiss) private var dismiss: DismissAction
	@Environment(ShoppingListCount.self) private var shoppingListCount
	
	// the item we're editing.  note that this can be an existing
	// Item within the model context (i.e., we're editing a known
	// Item), or just a plain, vanilla Item that's not yet assigned
	// to the model context (i.e., we're adding a new Item).
	//@State
	@Bindable private var editableItem: Item
	
	// we're being used for two purposes ... adding a new item and
	// editing an existing item.  let's keep track of this!
	private var addingNewItem: Bool
	
	// and we pull out the Item's location to edit separately,
	// because when adding a new Item, we cannot link the new Item
	// (which is not yet inserted in the model context) to an existing
	// Location (which is in the model context).
	@State private var selectedLocation: Location
	
	// we need all locations so we can populate the Picker.
	@Query(sort: \Location.position, order: .forward, animation: .easeInOut)
	private var locations: [Location]
	
	// used to trigger confirmation alert process for deleting an Item.
	@State private var alertIsPresented = false
	
	// used to indicate that an existing Item has been deleted so
	// that we do not have to do any update when dismissing.
	@State private var existingItemDeleted = false
	
	// custom init here to set up when we're bringing in an existing
	// Item that can be edited.
	init(from item: Item) {
		editableItem = item
		_selectedLocation = State(wrappedValue: item.location!)
		addingNewItem = false
	}
	
	// custom init here to set up when we're adding a new Item
	// and allowing it to be edited.
	init(suggestedName: String? = nil, initialLocation location: Location) {
		let newItem = Item()
		if let suggestedName {
			newItem.name = suggestedName
		}
		editableItem = newItem
		_selectedLocation = State(wrappedValue: location)
		addingNewItem = true
	}
	
	// MARK: - BODY Property
	
	var body: some View {
		Form {
			// Section 1. Basic Information Fields
			Section(header: Text("Basic Information")) {
				
				HStack(alignment: .firstTextBaseline) {
					SLFormLabelText(labelText: "Name: ")
					TextField("Item name", text: $editableItem.name, prompt: Text("Required"))
				}
				
				Stepper(value: $editableItem.quantity, in: 1...10) {
					HStack {
						SLFormLabelText(labelText: "Quantity: ")
						Text("\(editableItem.quantity)")
					}
				}
				
				Picker(
					selection: $selectedLocation,
					label: SLFormLabelText(labelText: "Location: ")
				) {
					ForEach(locations) { location in
						Text(location.name).tag(location)
					}
				}
				
				HStack(alignment: .firstTextBaseline) {
					Toggle(isOn: $editableItem.onList) {
						SLFormLabelText(labelText: "On Shopping List: ")
					}
				}
				
				HStack(alignment: .firstTextBaseline) {
					Toggle(isOn: $editableItem.isAvailable) {
						SLFormLabelText(labelText: "Is Available: ")
					}
				}
				
				if !addingNewItem {
					HStack(alignment: .firstTextBaseline) {
						SLFormLabelText(labelText: "Last Purchased: ")
						Text("\(editableItem.dateText)")
					}
				}
				
			} // end of Section 1
			
			// Section 2. Item Management (Delete), if editing an existing Item
			if !addingNewItem {
				Section(header: Text("Shopping Item Management")) {
					Button("Delete This Shopping Item", role: .destructive) {
						alertIsPresented = true
					}
					.hCentered()
					.confirmationDialog("Delete \'\(editableItem.name)\'?",
															isPresented: $alertIsPresented,
															titleVisibility: .visible) {
						Button("Yes", role: .destructive) {
							modelContext.delete(editableItem)
							existingItemDeleted = true
							shoppingListCount.countChanged()
							try? modelContext.save()
							dismiss()
						}
					} message: {
						Text("Are you sure you want to delete the Item named \'\(editableItem.name)\'? This action cannot be undone.")
					}
					
				} // end of Section 2
			} // end of if ...
		} // end of Form
		.navigationBarTitle(addingNewItem ? "Add New Item" : "Modify Item")
		.navigationBarTitleDisplayMode(.inline)
		.navigationBarBackButtonHidden(true)
		.toolbar {
			if addingNewItem {
				ToolbarItem(placement: .cancellationAction, content: cancelButton)
				ToolbarItem(placement: .confirmationAction, content: saveButton)
			} else {
				ToolbarItem(placement: .navigationBarLeading, content: customBackButton)
			}
		}
		
	} // end of var body: some View
	
	// MARK: - Back Button for Editing Existing Item
	
	// i don't like the idea of using a custom Back button ... it does not
	// really look all that good, and you lose the ability to swipe back.
	// since this has to be localized, it should at least point
	// in the right direction for all languages because of the use of the
	// SFSymbol "chevron.backward."
	
	// for the moment, i have disabled the Back button if we have executed
	// an item deletion (although i don;t think this can happen).
	//
	// i should probably also disable the Back button
	// if the name field is empty, but when have you ever seen this in
	// any UI?  so to deal with the possibility of going back with an
	// empty name field, we could put up a confirmation alert of the form
  // "the item name cannot be empty.  do you wish to continue
	// editing or do you want to delete this item?"  (but i don't like
	// either one of these.)
	func customBackButton() -> some View {
		Button {
			editableItem.location = selectedLocation
			shoppingListCount.countChanged()
			dismiss()
		} label: {
			HStack(spacing: 5) {
				Image(systemName: "chevron.backward")
				Text("Back")
			}
		}
		.disabled(existingItemDeleted)
	}
	
	// MARK: - Save and Cancel Buttons for Adding New Item

	// the cancel button just dismisses this view when we're
	// adding a new Item.  consequently, the Item will just now
	// go away on its own, having not been inserted into the
	// model context.
	func cancelButton() -> some View {
		Button("Cancel") {
			dismiss()
		}
	}
	
	// the save button adds the proposed new item to the model context,
	// links it with the selectedLocation, and dismisses this view.
	func saveButton() -> some View {
		Button("Save") {
			modelContext.insert(editableItem)
			selectedLocation.addToItems(item: editableItem)
			shoppingListCount.countChanged()
			dismiss()
		}
		.disabled(!editableItem.canBeSaved)
	}
	
}

