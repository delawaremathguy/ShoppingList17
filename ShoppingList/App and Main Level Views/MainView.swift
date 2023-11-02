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
				// standard tab view for an iPhone in portrait, etc.
			CompactMainView()
		} else {
				// this looks better on the iPad since the introduction of NavigationSplitView
				// and it behaves better than before.
			RegularMainView()
		}
		
	}
}

