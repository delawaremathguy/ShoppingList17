//
//  ShoppingListApp.swift
//  ShoppingList
//
//  Created by Jerry on 11/19/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftData
import SwiftUI

// this is a simple observable that holds a reference to
// the model context and makes available the number of items
// on the shopping list so we can maintain a badge on the
// shopping list item in a tab view (compact, horizontal
// appearance) or in a sidebar presentation for NavSplitView.
// we'll create it at the app level and drop it into the
// environment.
@Observable
class ShoppingListCount {
	let modelContext: ModelContext
	var onListCount: Int = 0
	
	init(modelContext: ModelContext) {
		self.modelContext = modelContext
		countChanged() // update the count right away
	}
	
	// call this function whenever we physically move something
	// onto or off of the shopping list.  there might be a simpler
	// way to watch for changes directly (e.g., in core data, i'd consider
	// using a fetchedResultsController) or perhaps i could make this
	// an observer of some SwiftData/Core Data notification ... but that's
	// something i will leave for later ...
	// (it looks like the only notifications that SwiftData posts
	// are for willSave and didSave?)
	func countChanged() {
		onListCount = modelContext.itemCount(onShoppingListOnly: true)
	}
}

/*
the App creates an InStoreTimer and pushes it into the environment,
for use with the Timer now displayed in the More... tab.
we also attach .onReceive modifiers to the MainView to watch being
moved into and out of the background to properly handle what to do
with the timer; and we push the shopping list count into the
environment.  Finally, we attach the SwiftData model container to
the WindowGroup, which places the modelContext into the environment.
*/

@main
struct ShoppingListApp: App {
	
	@State var inStoreTimer = InStoreTimer()
	
	let resignActivePublisher =
		NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
	let enterForegroundPublisher =
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
	let remoteStoreChangePublisher =
		NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
	
	// the modelContainer for SwiftData
	let modelContainer: ModelContainer
	// and the shoppingListCount observable that will hook
	// into the model context for changes to the shopping list count
	let shoppingListCount: ShoppingListCount
	// i like the idea of separately initializing the ModelContainer
	// here, where we might exert more control over its creation (e.g.,
	// we could change its name) and better handle data migrations that
	// may be necessary in the future.
	// reference: Stewart Lynch, SwiftData Containers (and Preview Data)
	//   https://www.youtube.com/watch?v=tZq4mvqH9Fg
	init() {
		let schema = Schema([Item.self, Location.self])
		do {
			modelContainer =  try ModelContainer(for: schema)
		} catch let error {
			fatalError("cannot set up modelContainer: \(error.localizedDescription)")
		}
		// create the shoppingListCount here, since we now have the modelContext
		shoppingListCount = ShoppingListCount(modelContext: modelContainer.mainContext)
	}
		
	var body: some Scene {
		WindowGroup {
			MainView()
				.environment(inStoreTimer)
				.environment(shoppingListCount)
				.onReceive(resignActivePublisher) { _ in
					inStoreTimer.suspendForBackground()
				}
				.onReceive(enterForegroundPublisher) { _ in
					if inStoreTimer.isSuspended {
						inStoreTimer.start()
					}
				}
				.onReceive(enterForegroundPublisher) { _ in
					if inStoreTimer.isSuspended {
						inStoreTimer.start()
					}
				}
			// we need to watch this for the case of the cloud telling us
			// that data has been synced ... the shopping list count
			// may have changed as a result
				.onReceive(remoteStoreChangePublisher) { _ in
					shoppingListCount.countChanged()
				}

		}
		.modelContainer(modelContainer)
	}
	
	
}
