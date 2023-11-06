//
//  DraftItemForm.swift
//  ShoppingList
//
//  Created by Jerry on 12/8/21.
//  Copyright © 2021 Jerry. All rights reserved.
//

import Observation
import SwiftData
import SwiftUI

// the DraftItemForm is a simple Form that allows the user to edit
// the value of a DraftItem, which can represent either default values
// for a new Item to create, or an existing Item.  additionally, for
// an existing Item, we are provided a dismissAction to perform
// after deleting the Item, which allows the parent view to dismiss
// itself.
struct DraftItemForm: View {
	
	@Environment(\.modelContext) private var modelContext
	
	// incoming data `draftItem` represents either
	// -- default data for an Item that we can edit and save, or
	// -- data for an existing Item that we can modify
	@Bindable var draftItem: DraftItem
	// incoming function `dismissAction` can be used to dismiss
	// ourself should the user confirm they want to delete
	// this Item ... because we cannot leave this view on screen after
	// the Item is deleted.
	var dismissAction: (() -> Void)?
	
	// we need all locations so we can populate the Picker.
	@Query(sort: \Location.position, order: .forward, animation: .easeInOut)
	private var locations: [Location]
	
	// used to trigger confirmation alert process for deleting an Item.
	@State private var alertIsPresented = false
	
	// MARK: - Computed Variables
	
	// finds the Item associated with this draft, if there is one.
	private var associatedItem: Item? {
		if let persistentModelID = draftItem.persistentModelID {
			return modelContext.registeredModel<Item>(for: persistentModelID)
		}
		return nil
	}
	
	// MARK: - BODY
	
	var body: some View {
		Form {
			// Section 1. Basic Information Fields
			Section(header: Text("Basic Information")) {
				
				HStack(alignment: .firstTextBaseline) {
					SLFormLabelText(labelText: "Name: ")
					TextField("Item name", text: $draftItem.name)
				}
				
				Stepper(value: $draftItem.quantity, in: 1...10) {
					HStack {
						SLFormLabelText(labelText: "Quantity: ")
						Text("\(draftItem.quantity)")
					}
				}
				
				Picker(
					selection: $draftItem.location,
					label: SLFormLabelText(labelText: "Location: ")
				) {
					ForEach(locations) { location in
						Text(location.name).tag(location)
					}
				}
				
				HStack(alignment: .firstTextBaseline) {
					Toggle(isOn: $draftItem.onList) {
						SLFormLabelText(labelText: "On Shopping List: ")
					}
				}
				
				HStack(alignment: .firstTextBaseline) {
					Toggle(isOn: $draftItem.isAvailable) {
						SLFormLabelText(labelText: "Is Available: ")
					}
				}
				
				if associatedItem != nil {
					HStack(alignment: .firstTextBaseline) {
						SLFormLabelText(labelText: "Last Purchased: ")
						Text("\(draftItem.dateText)")
					}
				}
				
			} // end of Section 1
			
			// Section 2. Item Management (Delete), if present
			if associatedItem != nil {
				Section(header: Text("Shopping Item Management")) {
					Button("Delete This Shopping Item", role: .destructive) {
						alertIsPresented = true
					}
					.hCentered()
					.confirmationDialog("Delete \'\(draftItem.name)\'?",
															isPresented: $alertIsPresented,
															titleVisibility: .visible) {
						Button("Yes", role: .destructive) {
							modelContext.delete(associatedItem!)
							try? modelContext.save()
							dismissAction?()
						}
					} message: {
						Text("Are you sure you want to delete the Item named \'\(draftItem.name)\'? This action cannot be undone.")
					}
					
				} // end of Section 2
			} // end of if ...
		} // end of Form
	} // end of var body: some View
	
}
