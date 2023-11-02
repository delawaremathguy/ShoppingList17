	//
	//  ShoppingListView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 4/22/20.
	//  Copyright © 2020 Jerry. All rights reserved.
	//

import MessageUI
import SwiftData
import SwiftUI

// the main shopping list view.
struct ShoppingListView: View {
	
	// our hook into SwiftData
	@Environment(\.modelContext) private var modelContext
	
	// MARK: - @Queries

	// we need items on the shopping list only
	@Query(filter: #Predicate<Item> { $0.onList }) private var items: [Item]

	// we also need to know when locations change, especially
	// if re-ordered. see the discussion below for the
	// computed var itemSections: [ItemSection].
	@Query(sort: \Location.position) private var locations: [Location]
	
		// MARK: - @State and @AppStorage Properties
	
		// control to confirm moving all items off the shopping list
	@State private var confirmMoveAllOffListIsPresented = false
	
		// control to bring up a sheet used to add a new item
	@State private var isAddNewItemSheetPresented = false
	
	// how we are displayed
	@State private var displayType: DisplayType
	
	// we use a custom init to properly set the display type, currently
	// a value we keep in UserDefaults.  because we're in an init(),
	// we cannot use @AppStorage, so we call UserDefaults directly.
	// a question to ask: why not just use @AppStorage and set the
	// displayType in .onAppear?  you can, but when using .byLocation
	// in UserDefaults, the screen will appear as a simple list and then
	// immediately redraw in sections for .byLocation ... and the
	// animation of this is both annoying and unnecessary.
	init() {
		if UserDefaults.standard.bool(forKey: kShoppingListIsMultiSectionKey) {
			_displayType = State(initialValue: .byLocation)
		} else {
			_displayType = State(initialValue: .byName)
		}
	}
	
		// MARK: - BODY

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				
				Rectangle()
					.frame(height: 1)
				
				DisplayTypePicker(displayType: $displayType, options: [.byName, .byLocation])
				
				// we display either a "List is Empty" view, or the list of items
				// on the shopping list.  what is displayed in the shopping list is
				// determined by the multiSectionDisplay state variable, using the
				// computed sections variable.
				if items.isEmpty {
					ContentUnavailableView("There are no items on your Shopping List",
						systemImage: "cart",
						description: Text("Tap the + button to add a new item, or move to the My Items tab and select items to place on your Shopping List.")
					)
				} else {
					ItemListView(itemSections: itemSections, sfSymbolName: "purchased")
					Divider()
					ShoppingListBottomButtons()
				} //end of if items.isEmpty
				
			} // end of VStack
			.navigationBarTitle("Shopping List")
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing, content: trailingButtons)
			}
			.sheet(isPresented: $isAddNewItemSheetPresented) {
				AddNewItemView(location: modelContext.unknownLocation)
					.interactiveDismissDisabled()
			}
		}
		
	} // end of body: some View
	
	// MARK: - Subviews
	
	private func trailingButtons() -> some View {
		HStack(spacing: 12) {
			ShareLink("", item: shareContent())
				.disabled(items.count == 0)
			
			NavBarImageButton("plus") {
				isAddNewItemSheetPresented = true
			}
		} // end of HStack
	}
	
	private func ShoppingListBottomButtons() -> some View {
		HStack {
			Spacer()
			
			Button("Mark All As Purchased") {
				confirmMoveAllOffListIsPresented = true
			}
			.confirmationDialog("Mark All As Purchased?",
													isPresented: $confirmMoveAllOffListIsPresented,
													titleVisibility: .visible) {
				Button("Yes", role: .destructive) {
					items.forEach { $0.markAsPurchased() }
				}
			}

			
			if !items.allSatisfy({ $0.isAvailable })  {
				Spacer()
				Button("Mark All Available") {
					items.forEach { $0.isAvailable = true }
				}
			}
			
			Spacer()
		} // end of HStack
		.padding(.vertical, 6)
	}

	// MARK: - Helper Functions
		
	private var itemSections: [ItemSection] {
		// if we have nothing on the list, there's nothing for ItemListView to show
		if items.isEmpty {
			return []
		}

		switch displayType {
				
			case .byName:
				return [ItemSection(title: "Items Remaining: \(items.count)",
														items: items.sorted(by: { $0.name < $1.name }))]
				
			case .byLocation:
				let activeLocations =
					locations.filter({ $0.items.count(where: { $0.onList }) > 0 })
					.sorted(by: { $0.position < $1.position })
				return activeLocations.map {
					ItemSection(title: $0.name,
											items: $0.items.filter({ $0.onList }).sorted(by: { $0.name < $1.name }))
				}
				
			case .byDate:	 // not used in this view
				return []
		}

	} // end of var itemSections: [ItemSection]
		
	// MARK: - Sharing support
	
	private func shareContent() -> String {
			// we share a straight-forward text description of the
			// shopping list, based on the itemSections
		var message = "Items on your Shopping List: \n"
		for section in itemSections {
			message += "\n\(section.title)"
//			if !multiSectionDisplay {
//				message += ", \(section.items.count) item(s)"
//			}
			message += "\n\n"
			for item in section.items {
				message += "  \(item.name)\n"
			}
		}
		return message
	}
	
} // end of ShoppingListBottomButtons
