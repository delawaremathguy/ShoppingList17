	//
	//  AllMyItemsView.swift
	//  ShoppingList
	//
	//  Created by Jerry on 5/14/20.
	//  Copyright © 2020 Jerry. All rights reserved.
	//

import SwiftData
import SwiftUI

// a list of ALL items (this is different than in SL16).
// you could also call it an item catalog, of sorts.
struct AllMyItemsView: View {
	
	// MARK: - @Environment Properties
	
	// hook into SwiftData
	@Environment(\.modelContext) private var modelContext
	// the value of Calendar.current is in the environment
	@Environment(\.calendar) private var calendar
	
	// MARK: - @Query
	
	@Query(sort: \Item.name, animation: .easeInOut) private var items: [Item]
	
	// MARK: - @State and @AppStorage Properties
	
	// variable to handle the Search field
	@State private var searchText: String = ""
	
	// trigger for sheet used to add a new shopping item
	@State private var isAddNewItemSheetPresented = false
	
	// items currently checked, on their way to the shopping list
	@State private var itemsChecked = [Item]()
	
	// hook back to userDefaults in the language of SL16
	@AppStorage(kAllMyItemsListIsMultiSectionKey)
	private var isMultiSectionList = kAllMyItemsListIsMultiSectionDefaultValue

	// how we display the items
	@State private var displayType: DisplayType
	
	init() {
		if UserDefaults.standard.bool(forKey: kAllMyItemsListIsMultiSectionKey) {
			_displayType = State(initialValue: .byDate)
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
				
				DisplayTypePicker(displayType: $displayType, options: [.byName, .byDate])
				
				// display either an appropriate "List is Empty" view, or
				// the sectioned list of all items.
				if items.isEmpty {
					appHasNoItemsView()
				} else if items.count(where: { searchText.appearsIn($0.name) }) == 0  {
					ContentUnavailableView.search(text: searchText)
				} else {
					ItemListView(itemSections: itemSections, sfSymbolName: "cart")
				} // end of if-else
				
			} // end of VStack
			.searchable(text: $searchText)
			.onAppear { searchText = "" } // clear searchText, get a clean screen
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing, content: addNewButton)
			}
			.sheet(isPresented: $isAddNewItemSheetPresented) {
				NavigationStack {
					AddOrModifyItemView(suggestedName: searchText, initialLocation: modelContext.unknownLocation)
				}
//				AddNewItemView(suggestedName: searchText, location: modelContext.unknownLocation)
					.interactiveDismissDisabled()
			}
			.onChange(of: displayType) { oldValue, newValue in
				isMultiSectionList = (newValue == .byDate)
			}
			.navigationBarTitle("All My Items")
			.navigationDestination(for: Item.self) { item in
				AddOrModifyItemView(from: item)
//				ModifyExistingItemView(item: item)
			}

		} // end of NavigationStack
	} // end of var body: some View
	
	// MARK: - Subviews
	
	// makes a simple "+" to add a new item.  tapping on 
	// the button triggers a sheet to add a new item.
	func addNewButton() -> some View {
		NavBarImageButton("plus") {
			isAddNewItemSheetPresented = true
		}
	}
	
	// the full ContentUnavailableView when the user has
	// not yet entered any items in the app.  i make this
	// a separate view, only because it's 10 less lines of view
	// code so the body can pretty much fit on one screen and
	// be readable.
	func appHasNoItemsView() -> some View {
		ContentUnavailableView {
			Label("You have entered no items yet", systemImage: "cart.badge.plus")
		} description: {
			Text("Tap the + button in the navigation bar to add a new item or tap this \"Add New Item\" button. The item will be placed on your shopping list.")
		} actions: {
			Button("Add New Item") {
				isAddNewItemSheetPresented = true
			}
			.buttonStyle(.borderedProminent)
		}

	}
	
	// MARK: - Helper Functions
	
	// itemSections breaks out the Items into sections for display,
	// where we can produce either one section for everything,
	// or else a section for each purchase date, plus one more
	// section for items never purchased.
	var itemSections: [ItemSection] {
		// reduce items by search criteria
		let searchQualifiedItems = items.filter { searchText.appearsIn($0.name) }
		
		switch displayType {
			case .byName:
				return [ItemSection(title: "Items: \(items.count)", items: searchQualifiedItems)]
				
			case .byDate:
				let purchasedItems = searchQualifiedItems.filter { $0.lastPurchased != nil }
				let dictionary = Dictionary(grouping: purchasedItems) {
					calendar.startOfDay(for: $0.lastPurchased!)
				}
				// the list of sections to build ...
				var sections = [ItemSection]()
				for key in dictionary.keys.sorted(by: { $0 > $1 }) {
					let newSection = ItemSection(title: key.formatted(date: .complete, time: .omitted),
																			 items: dictionary[key]!)
					sections.append(newSection)
				}
				let nonPurchasedItems = searchQualifiedItems.filter { $0.lastPurchased == nil }
				if !nonPurchasedItems.isEmpty {
					sections.append(ItemSection(title: "Never Purchased", items: nonPurchasedItems))
				}
				return sections
				
			case .byLocation: // not used in this view
				return []
				
		}
	}
	
}


