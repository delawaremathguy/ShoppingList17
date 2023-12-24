//
//  AddNewLocationView.swift
//  ShoppingList
//
//  Created by Jerry on 12/10/21.
//  Copyright © 2021 Jerry. All rights reserved.
//

//import SwiftData
//import SwiftUI
//
//// see AddNewItemView.swift for similar comments and explanation of how this works
//struct AddNewLocationView: View {
//	
//	// our hook into SwiftData
//	@Environment(\.modelContext) private var modelContext
//	// we're coming up as a sheet and need to dismiss ourself
//	@Environment(\.dismiss) var dismiss
//
//	
//	// a draftLocation is initialized here, holding default values for
//	// a new Location.
//	@State private var draftLocation = DraftLocation()
//	
//	// the body is just an editing form for the draftLocation
//	var body: some View {
//		NavigationStack {
//			DraftLocationForm(draftLocation: draftLocation)
//				.navigationBarTitle("Add New Location")
//				.navigationBarTitleDisplayMode(.inline)
//				.toolbar {
//					ToolbarItem(placement: .cancellationAction, content: cancelButton)
//					ToolbarItem(placement: .confirmationAction, content: saveButton)
//				}
//		}
//	}
//	
//	// the cancel button
//	func cancelButton() -> some View {
//		Button("Cancel") {
//			dismiss()
//		}
//	}
//	
//	// the save button ... cannot save unless the draftLocation
//	// has sufficient info (i.e. a non-empty name)
//	func saveButton() -> some View {
//		Button("Save") {
//			let newLocation = Location(from: draftLocation)
//			modelContext.insert(newLocation)
//			dismiss()
//		}
//		.disabled(!draftLocation.canBeSaved)
//	}
//	
//}
//
