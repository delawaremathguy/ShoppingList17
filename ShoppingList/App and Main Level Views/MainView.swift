//
//  MainView.swift
//  ShoppingList
//
//  Created by Jerry on 2/9/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftUI

// the MainView simply decides which top-level view to use, based on
// the horizontal size class of the app.
struct MainView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	
	var body: some View {
		if horizontalSizeClass == .compact {
			// standard tab view for an iPhone in portrait, or even
			// some iPad presentations which take up only part of
			// a window and have a compact size.
			CompactMainView()
		} else {
			// this looks better on the iPad with NavigationSplitView
			RegularMainView()
		}
		
	}
}

