	//
	//  PurchasedItemsView.swift
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
	
	@Query(sort: \Item.name) private var items: [Item]
	
	// MARK: - @State and @AppStorage Properties
	
	// variable to handle the Search field
	@State private var searchText: String = ""
	
	// trigger for sheet used to add a new shopping item
	@State private var isAddNewItemSheetPresented = false
	
	// items currently checked, on their way to the shopping list
	@State private var itemsChecked = [Item]()
	
	@State private var displayType: DisplayType
	
	init() {
		if UserDefaults.standard.bool(forKey: kPurchasedListIsMultiSectionKey) {
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
				// the sectioned list of purchased items.
				if items.isEmpty {
					ContentUnavailableView("There are no items on your Purchased List",
																 systemImage: "cart",
																 description: Text("Tap the + button to add a new item.")
					)
				} else if !searchText.isEmpty && items.count(where: { searchText.appearsIn($0.name) }) == 0  {
					ContentUnavailableView.search
				} else {
					ItemListView(itemSections: itemSections,
											 sfSymbolName: "cart")
				} // end of if-else
				
			} // end of VStack
			.searchable(text: $searchText)
			.onAppear { searchText = "" } // clear searchText, get a clean screen
			.navigationBarTitle("All My Items")
//			.navigationDestination(for: Item.self) { item in
//				ModifyExistingItemView(item: item)
//			}
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing, content: addNewButton)
			}
			.sheet(isPresented: $isAddNewItemSheetPresented) {
				AddNewItemView(suggestedName: searchText, location: modelContext.unknownLocation)
					.interactiveDismissDisabled()
			}
			.navigationDestination(for: Item.self) { item in
				ModifyExistingItemView(item: item)
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
	
	// MARK: - Helper Functions
	
	// itemSections breaks out the Items into sections,
	// where we can produce either one section for everything, 
	// or else sections for each purchase date, plus one
	// for those never purchased.
	var itemSections: [ItemSection] {
		// reduce items by search criteria
		let searchQualifiedItems = items.filter({ searchText.appearsIn($0.name) })
		
		switch displayType {
			case .byName:
				return [ItemSection(//index: 1,
					title: "Items: \(items.count)", items: searchQualifiedItems)]
				
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
				let nonPurchasedItems = searchQualifiedItems.filter({ $0.lastPurchased == nil })
				if !nonPurchasedItems.isEmpty {
					sections.append(ItemSection(title: "Never Purchased", items: nonPurchasedItems))
				}
				return sections
				
			case .byLocation: // not used in this view
				return []
				
		}
	}
	
}


