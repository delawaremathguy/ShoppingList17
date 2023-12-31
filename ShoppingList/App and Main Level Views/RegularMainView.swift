//
//  RegularMainView.swift
//  ShoppingList
//
//  Created by Jerry on 2/9/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftUI

// the RegularMainView is a two-column NavigationSplitView, where
// the first column has the same role that the tab bar of the TabView
// has in the CompactMainView.
struct RegularMainView: View {
		
	@Environment(ShoppingListCount.self) private var shoppingListCount
	@State private var selection: NavigationItem? = .shoppingList
	
	var sidebarView: some View {
		List(selection: $selection) {
			
			Label("Shopping List", systemImage: "cart")
				.badge(shoppingListCount.onListCount) // i am surprised this works!
				.tag(NavigationItem.shoppingList)
			
			Label("All My Items", systemImage: "list.bullet.clipboard")
				.tag(NavigationItem.allMyItemsList)
			
			Label("Locations", systemImage: "map")
				.tag(NavigationItem.locationList)
						
			Label("Preferences", systemImage: "gear")
				.tag(NavigationItem.preferences)
			
			Label("More", systemImage: "ellipsis")
				.tag(NavigationItem.more)

		}
	}
	
	var body: some View {
		NavigationSplitView(columnVisibility: .constant(.automatic)) {
			sidebarView
				.navigationSplitViewColumnWidth(250)
		} detail: {
			switch selection {
				case .shoppingList:
					ShoppingListView(goToAllMyItems: { selection = .allMyItemsList })
				case .allMyItemsList:
					AllMyItemsView()
				case .locationList:
					LocationsView()
				case .preferences:
					PreferencesView()
				case .more:
					MoreView()
				case .none:	// selection is an optional type, although selection will never be nil
					Text(".none")
			}
		}
		.navigationSplitViewStyle(.balanced)
			// note: this modifier comes from Stewart Lynch.  see NavAppearanceModifier.swift
		.navigationAppearance(backgroundColor: .systemGray6,
													foregroundColor: .systemBlue,
													tintColor: .systemBlue)
	}
}
