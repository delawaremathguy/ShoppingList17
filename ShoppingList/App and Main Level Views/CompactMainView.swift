//
//  CompactMainView.swift
//  ShoppingList
//
//  Created by Jerry on 5/6/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// the CompactMainView is a tab view with five tabs.
// not much happens here, although the 5 tabs each manage
// their own navigation stack.

struct CompactMainView: View {
	var body: some View {
		TabView {
			ShoppingListView()
				.tabItem { Label("Shopping List", systemImage: "cart") }
			
			AllMyItemsView()
				.tabItem { Label("All My Items", systemImage: "list.bullet.clipboard") }
			
			LocationsView()
				.tabItem { Label("Locations", systemImage: "map") }
			
			PreferencesView()
				.tabItem { Label("Preferences", systemImage: "gear") }
			
			MoreView()
				.tabItem { Label("More", systemImage: "ellipsis") }

		} // end of TabView
	} // end of var body: some View
}

