//
//  ShoppingListApp.swift
//  ShoppingList
//
//  Created by Jerry on 11/19/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import Foundation
import SwiftUI

/*
the App creates an InStoreTimer and pushes it into the environment,
for use with the Timer now displayed in the More... tab
we also attach .onReceive modifiers to the MainView to watch being
moved into and out of the background to properly handle what to do
with the timer, as well as establish the SwiftData model container
and its model context that automatically goes into the environment.
*/

@main
struct ShoppingListApp: App {
	
	@StateObject var inStoreTimer = InStoreTimer()
	
	let resignActivePublisher =
		NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
	let enterForegroundPublisher =
		NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
		
	var body: some Scene {
		WindowGroup {
			MainView()
				.environmentObject(inStoreTimer)
				.onReceive(resignActivePublisher) { _ in
					inStoreTimer.suspendForBackground()
				}
				.onReceive(enterForegroundPublisher) { _ in
					if inStoreTimer.isSuspended {
						inStoreTimer.start()
					}
				}
		}
		.modelContainer(for: [Item.self, Location.self])
	}
	
	
}