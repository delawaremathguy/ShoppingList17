//
//  ShoppingListApp.swift
//  ShoppingList
//
//  Created by Jerry on 11/19/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftData
import SwiftUI

/*
the App creates an InStoreTimer and pushes it into the environment,
for use with the Timer now displayed in the More... tab.
we also attach .onReceive modifiers to the MainView to watch being
moved into and out of the background to properly handle what to do
with the timer.  Finally, we establish the SwiftData model container
and attach is to the WindowGroup/place it into the environment.
*/

@main
struct ShoppingListApp: App {
	
	@State var inStoreTimer = InStoreTimer()
	
	let resignActivePublisher =
		NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
	let enterForegroundPublisher =
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
	
	let modelContainer: ModelContainer

	// i like the idea of separately initializing the ModelContainer
	// here, where we could exert more control over its creation (e.g.,
	// we could change its name) and better handle data migrations that
	// might be necessary in the future.
	// reference: Stewart Lynch, SwiftData Containers and Preview Data
	//   https://www.youtube.com/watch?v=tZq4mvqH9Fg
	init() {
		let schema = Schema([Item.self, Location.self])
		do {
			modelContainer =  try ModelContainer(for: schema)
		} catch let error {
			fatalError("cannot set up modelContainer: \(error.localizedDescription)")
		}
	}
		
	var body: some Scene {
		WindowGroup {
			MainView()
				.environment(inStoreTimer)
				.onReceive(resignActivePublisher) { _ in
					inStoreTimer.suspendForBackground()
				}
				.onReceive(enterForegroundPublisher) { _ in
					if inStoreTimer.isSuspended {
						inStoreTimer.start()
					}
				}
		}
		.modelContainer(modelContainer)
	}
	
	
}
