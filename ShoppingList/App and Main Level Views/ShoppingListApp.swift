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
which places its model context automatically into the environment.
*/

@main
struct ShoppingListApp: App {
	
	@State var inStoreTimer = InStoreTimer()
	
	let resignActivePublisher =
		NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
	let enterForegroundPublisher =
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
//	let remoteChangePublisher = NotificationCenter.default.publisher(for: NSNotification.Name.NSPersistentStoreRemoteChange)
	
	let modelContainer: ModelContainer
	init() {
		let schema = Schema([Item.self, Location.self])
		do {
			modelContainer =  try ModelContainer(for: schema)
		} catch let error {
			fatalError("cannot set up modelContainer: \(error.localizedDescription)")
		}
		
		// fix error in database ??
		let fetchDescriptor = FetchDescriptor<Item>()
		do {
			let items = try modelContainer.mainContext.fetch(fetchDescriptor)
			let itemsToDelete = items.filter { $0.name.contains("New Item32") }
			print("found \(itemsToDelete.count) items to delete.")
			for item in itemsToDelete {
				modelContainer.mainContext.delete(item)
			}
			try? modelContainer.mainContext.save()
			
		} catch let error {
			print("*** cannot fetch items: \(error.localizedDescription)")
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
//				.onReceive(remoteChangePublisher) { _ in
//					DispatchQueue.main.async {
//						modelContainer.mainContext.condenseMultipleUnknownLocations()
//					}
//				}
		}
		.modelContainer(modelContainer)
	}
	
	
}
