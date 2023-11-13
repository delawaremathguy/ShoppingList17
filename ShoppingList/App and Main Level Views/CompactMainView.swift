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
	
	@State private var selection: NavigationItem? = .shoppingList

	var body: some View {
		TabView(selection: $selection) {
			// passing along a way to move directly from the ShoppingListView
			// tab over to the AllMyItemsView tab is not currently working
			// (although it does work on the iPad with NavigationSplitView)
			// and i'll try to figure this out at some point.
			ShoppingListView() { /*selection = .allMyItemsList*/ }
				.tag(NavigationItem.shoppingList)
				.tabItem { Label("Shopping List", systemImage: "cart") }
			
			AllMyItemsView()
				.tag(NavigationItem.allMyItemsList)
				.tabItem { Label("All My Items", systemImage: "list.bullet.clipboard") }
			
			LocationsView()
				.tag(NavigationItem.locationList)
				.tabItem { Label("Locations", systemImage: "map") }
			
			PreferencesView()
				.tag(NavigationItem.preferences)
				.tabItem { Label("Preferences", systemImage: "gear") }
			
			MoreView()
				.tag(NavigationItem.more)
				.tabItem { Label("More", systemImage: "ellipsis") }

		} // end of TabView
		// .onChange is here only for testing purposes !
		.onChange(of: selection) { oldValue, newValue in
			print("change from \(String(describing: oldValue)) to \(String(describing: newValue))")
		}
	} // end of var body: some View
}

