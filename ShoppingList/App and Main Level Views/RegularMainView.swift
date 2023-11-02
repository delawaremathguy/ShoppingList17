//
//  RegularMainView.swift
//  ShoppingList
//
//  Created by Jerry on 2/9/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftUI

// the RegularMainView is a two-column NavigationSplitView, where
// the first column has the same role that the TabView has in the
// CompactMainView.

struct RegularMainView: View {
	
	enum NavigationItem {
		case shoppingList
		case purchasedList
		case locationList
		//case inStoreTimer
		case preferences
		case more
	}
	
	@State private var selection: NavigationItem? = .shoppingList
	
	var sidebarView: some View {
		List(selection: $selection) {
			
			Label("Shopping List", systemImage: "cart")
				.tag(NavigationItem.shoppingList)
			
			Label("All My Items", systemImage: "list.bullet.clipboard")
				.tag(NavigationItem.purchasedList)
			
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
						ShoppingListView()
					case .purchasedList:
						AllMyItemsView()
					case .locationList:
						LocationsView()
					case .preferences:
						PreferencesView()
					case .more:
						MoreView()
					case .none:	// selection is an optional type, although it will never be nil
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
