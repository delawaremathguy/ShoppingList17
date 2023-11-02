	//
	//  ModifyExistingLocationView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 12/11/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import SwiftUI

struct ModifyExistingLocationView: View {
	
	@Environment(\.dismiss) var dismiss: DismissAction
	@Environment(\.modelContext) private var modelContext

	// draftLocation will be initialized from the incoming Location
	@State private var draftLocation: DraftLocation
	
	init(location: Location) {
		_draftLocation = State(wrappedValue: DraftLocation(location: location))
	}
	
	// we'll need a reference to the real Location being modified
	// on our way out; but here we can tell whether what should
	// be the associated Location still exists when it comes
	// time to update its data.
	private var associatedLocation: Location? {
		if let persistentModelID = draftLocation.persistentModelID {
			return modelContext.registeredModel<Location>(for: persistentModelID)
		} else {
			return nil
		}
	}
	
	var body: some View {
		// the trailing closure provides the DraftLocationView with what
		// to do after the user has
		// chosen to delete the Location, namely to dismiss this view,"
		// so we "go back" up the navigation stack
		DraftLocationForm(draftLocation: draftLocation, dismissAction: dismiss.callAsFunction)
			.navigationBarTitle("Modify Location")
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarBackButtonHidden(true)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading, content: customBackButton)
			}
	}
	
	func customBackButton() -> some View {
			//...  see comments in ModifyExistingItemView about using
			// our own back button.
		Button {
			associatedLocation?.updateValues(from: draftLocation)
			dismiss()
		} label: {
			HStack(spacing: 5) {
				Image(systemName: "chevron.backward")
				Text("Back")
			}
		}
	}

	
}

