	//
	//  AddNewItemView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 12/8/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import SwiftUI

/*
the AddNewItemView is opened via a sheet from either the ShoppingListView
or the PurchasedItemTabView, within a NavigationView, to do as it says: add
a new shopping item.  the strategy is simple:
	
 -- create a default set of values for a new shopping item (a StateObject)
 -- the body shows a Form in which the user can edit the default data
 -- we supply buttons in the navigation bar to save a new item from the edited data
      and to dismiss.  note: i have added .interactiveDismissDisabled() to the sheet so
	 no data will be discarded unless the user touches the Cancel button ... i.e., the
	 user cannot simply dismiss the AddNew sheet by pulling down on it.
 
i make no attempt to alert the user should she tap the Cancel button
if there have been edits to the original default data.
*/
struct AddNewItemView: View {
	
	@Environment(\.modelContext) private var modelContext
	@Environment(\.dismiss) private var dismiss
	
	// this draftItem object contains all of the information
	// for a new Item that is needed from the User
	@State private var draftItem: DraftItem

	// custom init here to set up a draft for an Item to be added,
	// one having default values
	init(suggestedName: String? = nil, location: Location) {
		let initialValue = DraftItem(at: location, suggestedName: suggestedName)
		_draftItem = State(wrappedValue: initialValue)
	}
	
	// the body is pretty short -- just call up a Form inside a NavigationStack
	// to edit the value of a draftItem representing a new Item, and
	// add Cancel and Save buttons.
	var body: some View {
		NavigationStack {
			DraftItemForm(draftItem: draftItem)
				.navigationBarTitle("Add New Item", displayMode: .inline)
				.toolbar {
					ToolbarItem(placement: .cancellationAction, content: cancelButton)
					ToolbarItem(placement: .confirmationAction, content: saveButton)
				}
		}
	}
	
	// the cancel button just dismisses this view
	func cancelButton() -> some View {
		Button("Cancel") {
			dismiss()
		}
	}
	
	// the save button creates the a item in the persistent store,
	// links it the draftItem's location, and dismisses this view.
	func saveButton() -> some View {
		Button("Save") {
			let item = Item(from: draftItem)
			modelContext.insert(item)
			draftItem.location.append(item: item)
			dismiss()
		}
		.disabled(!draftItem.canBeSaved)
	}
	
}


