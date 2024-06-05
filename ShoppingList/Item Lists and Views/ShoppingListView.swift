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
	@Environment(ShoppingListCount.self) private var shoppingListCount

	// MARK: - @Queries

	// we need items on the shopping list ... let SwiftData sort them for us
	@Query(filter: #Predicate<Item> { $0.onList },
				 sort: \Item.name, order: .forward, animation: .easeInOut)
	private var items: [Item]

	// we also need to know when locations change, especially
	// if re-ordered. see the discussion below for the
	// computed var itemSections: [ItemSection].
	@Query(sort: \Location.position, animation: .easeInOut)
	private var locations: [Location]
	
		// MARK: - @State and @AppStorage Properties
	
		// control to confirm moving all items off the shopping list
	@State private var confirmMoveAllOffListIsPresented = false
	
		// control to bring up a sheet used to add a new item
	@State private var isAddNewItemSheetPresented = false
	
	// hook back to userDefaults in the language of SL16
	@AppStorage(kShoppingListIsMultiSectionKey)
	private var isMultiSectionShoppingList = kShoppingListIsMultiSectionDefaultValue

	// how we are displayed, but in terms of the value of
	// kShoppingListIsMultiSectionKey in AppStorage from SL16.
	// appropriately updates User Defaults when changed.
	@State var displayType: DisplayType = .byName
	
	// use this function if the user wants to programmatically go
	// over to look at the AllMyItemsView.
	private var goToAllMyItems: () -> Void
	
	// we use a custom init to properly set both goToAllMyItems and
	// the initial display type, currently based on
	// a value we keep in UserDefaults.  because we're in an init(),
	// we cannot use @AppStorage, so we call UserDefaults directly.
	// a question to ask: why not just use @AppStorage and set the
	// displayType in .onAppear?  you can, but when using .byLocation
	// in UserDefaults, the screen will appear as a simple list and then
	// immediately redraw in sections for .byLocation ... and the
	// animation of this is both annoying and unnecessary.
	init(goToAllMyItems: @escaping () -> Void) {
		let isMultiSection = UserDefaults.standard.bool(forKey: kShoppingListIsMultiSectionKey)
		_displayType = State(initialValue: isMultiSection ? .byName : .byLocation)
		self.goToAllMyItems = goToAllMyItems
	}
	
		// MARK: - BODY

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				
				Rectangle()
					.frame(height: 1)
				
				DisplayTypePicker(displayType: $displayType, options: [.byName, .byLocation])
				
				// we display either a "List is Empty" view, or the list of items
				// on the shopping list.
				if items.isEmpty {
					noItemsOnShoppingListView()
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
				NavigationStack {
					AddOrModifyItemView(initialLocation: modelContext.unknownLocation)
				}
//				AddNewItemView(location: modelContext.unknownLocation)
					.interactiveDismissDisabled()
			}
			.onAppear {
				// this seems a little bit of a hack, and i am not totally
				// convinced this will do much ... but let's at least hope
				// this gives us a shot at getting the count right for the
				// problem of background updates received via iCloud
				// for items on the shopping list being modified on a
				// different device.
				DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
					// updating this directly in .onAppear does not really solve the problem (!)
					// but delaying this for a few seconds should be a reasonable fix.
					shoppingListCount.countChanged()
				}
			}
			// i don't like separating this nav destination from where the
			// links to use it are located -- in the ItemListView -- but
			// the placement of this matters ... and the best advice that
			// i've seen about issues involving navigationDestination are to
			// place this modifier as high up in the view hierarchy as
			// possible.  and something changed from iOS 16 to iOS 17 for
			// this modifier, which still leaves me confused about why it
			// mostly works, but then occasionally fails (either because a
			// destination cannot be found, or it goes into some sort of
			// infinite loop and becomes unresponsive).
			.navigationDestination(for: Item.self) { item in
				AddOrModifyItemView(from: item)
//				ModifyExistingItemView(item: item)
			}
			.onChange(of: displayType) { oldValue, newValue in
				isMultiSectionShoppingList = (newValue == .byLocation)
			}
		} // end of NavigationStack
		
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
					shoppingListCount.countChanged()
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
	
	// the full ContentUnavailableView when the user has
	// not yet entered any items in the app.  i make this
	// a separate view, only because it's 10 less lines of view
	// code so the body can pretty much fit on one screen and
	// be readable.
	func noItemsOnShoppingListView() -> some View {
		ContentUnavailableView {
			Label("There are no items on your Shopping List", systemImage: "cart.badge.questionmark")
		} description: {
			Text("Tap the + button in the navigation bar to add a new item, or move to the All My Items tab and select items to place on your Shopping List.")
		} actions: {
			HStack(spacing: 30) {
				Spacer()
				Button("Go to All My Items") {
					goToAllMyItems()
				}
				Button("Add New Item") {
					isAddNewItemSheetPresented = true
				}
				Spacer()
			}
			.buttonStyle(.borderedProminent)
		}
	}


	// MARK: - Helper Functions
		
	private var itemSections: [ItemSection] {
		// (updated from SL16 code)
		// if we have nothing on the list, there's nothing for ItemListView to show
		if items.isEmpty {
			return []
		}

		switch displayType {
				
				// byName is simple: list items alphabetically
			case .byName:
				return [ItemSection(title: "Items Remaining: \(items.count)",
														items: items)]
				
				// byLocation just pulls out locations that have items on the SL
				// sorted by their position, then for each, pull its items
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
