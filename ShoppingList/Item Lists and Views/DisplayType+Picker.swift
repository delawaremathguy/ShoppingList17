//
//  DisplayType+Picker.swift
//  ShoppingList
//
//  Created by Jerry on 11/2/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftUI

// both the ShoppingListView and the AllMyItemsView use a
// variety of display modes, which we collect here for both
// this and the AllMyItemsView.  (only two of the three apply
// to any one of these views ...)
enum DisplayType: Hashable, Identifiable {
	case byName, byDate, byLocation
	
	// implement Identifiable since we use a ForEach with these
	var id: Self { self }
	// names to display when used in a Picker
	var title: String {
		switch self {
			case .byName: "Name"
			case .byDate: "Purchase Date"
			case .byLocation: "Location"
		}
	}
}

// this is what a picker looks like when choosing a
// DisplayType ... we use it in both the ShoppingListView
// and the AllMyItemsView
struct DisplayTypePicker: View {
	
	// incoming binding to a State variable in the enclosing view
	@Binding var displayType: DisplayType
	
	// selectable options to display in the Picker; which ones
	// are used depends on the call site and usage context.
	let options: [DisplayType]
	
	var body: some View {
		HStack(spacing: 4) {
			Spacer()
			
			Text("Display by:")
				.font(.subheadline)
			
			Picker("", selection: $displayType) {
				ForEach(options) { option in
					Text(option.title).tag(option)
				}
			}
			.pickerStyle(.segmented)
			.padding(.vertical, 8)
			
			Spacer()
		}
		.padding(.horizontal, 16)
		.background(Color.systemGray6)
	}
	
} // end of struct DisplayTypePicker: View

