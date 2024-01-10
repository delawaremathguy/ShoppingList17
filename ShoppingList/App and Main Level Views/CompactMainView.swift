//
//  CompactMainView.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

enum NavigationItem: Int, Hashable {
	case shoppingList = 1
	case allMyItemsList
	case locationList
	case preferences
	case more
}

// the CompactMainView is a tab view with five tabs.
// not much happens here (the 5 tabs each manage
// their own navigation stack).
struct CompactMainView: View {
	
	@Environment(ShoppingListCount.self) private var shoppingListCount
	
	// note to self: this cannot be an optional type; otherwise
	// the programmatic tab switching i want does not work.
	@State private var selection: NavigationItem = .shoppingList

	var body: some View {
		TabView(selection: $selection) {
			// for ShoppingListView, we are passing along a way to
			// move directly from the ShoppingListView tab over to
			// the AllMyItemsView tab.
			ShoppingListView(goToAllMyItems: { selection = .allMyItemsList })
				.tabItem { Label("Shopping List", systemImage: "cart") }
				.tag(NavigationItem.shoppingList)
				// i would like to add a badge modifier here, but it won't update
				// as items are marked purchased ... only when you change tabs.
				.badge(shoppingListCount.onListCount)

			AllMyItemsView()
				.tabItem { Label("All My Items", systemImage: "list.bullet.clipboard") }
				.tag(NavigationItem.allMyItemsList)
			
			LocationsView()
				.tabItem { Label("Locations", systemImage: "map") }
				.tag(NavigationItem.locationList)
			
			PreferencesView()
				.tabItem { Label("Preferences", systemImage: "gear") }
				.tag(NavigationItem.preferences)
			
			MoreView()
				.tabItem { Label("More", systemImage: "ellipsis") }
				.tag(NavigationItem.more)

		} // end of TabView
		// .onChange is here only for testing purposes !
//		.onChange(of: selection) { oldValue, newValue in
//			print("change from \(String(describing: oldValue)) to \(String(describing: newValue))")
//		}
	} // end of var body: some View
}

