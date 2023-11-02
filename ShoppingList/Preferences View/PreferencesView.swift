//
//  OperationTabView.swift
//  ShoppingList
//
//  Created by Jerry on 6/11/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
	
//	// this view is for user preferences:
//	//
//	// Purchased Items History Mark:
//	// -- first section: items purchased within the last N days
//	// -- second section: all other items purchased.
//	// we'll allow N here to be 0 ... 10
//	//
//	// Timer Suspension Preference
//	// -- whether to suspend the timer when the app goes into the
//	//    background.  perhaps useful if you don't want to count
//	//    time spent shopping that you're on the phone, or if you're
//	//    out browsing on the web.  you be the judge: maybe the phone
//	//    call is more a last minute shopping request from home, or
//	//    you use the web to compare prices while you're shopping.
//	
//	// user default. 0 = purchased today; 3 = purchased up to 3 days ago, ...
//	@AppStorage(kPurchasedMostRecentlyKey)
//	private var historyMarker = kPurchasedMostRecentlyDefaultValue
	
	// user default.  true ==> turn off timer (counting) when in the background.
	@AppStorage(kDisableTimerWhenInBackgroundKey)
	private var suspendTimerWhenInBackground = kDisableTimerWhenInBackgroundDefaultValue

	var body: some View {
		NavigationStack {
			Form {
//				Section() {
//					Stepper(value: $historyMarker, in: 0...10) {
//						HStack {
//							SLFormLabelText(labelText: "History mark: ")
//							Text("\(historyMarker)")
//						}
//					}
//				} header: {
//					Text("Purchased Items History Mark")
//				} footer: {
//					Text("Sets the number of days to look backwards in time to separate out items purchased recently.")
//				}
				
				Section() {
					Toggle(isOn: $suspendTimerWhenInBackground) {
						Text("Suspend when in background")
					}
				} header: {
					Text("Timer Preference")
				} footer: {
					Text("Turn this on if you want the timer to pause, say, while you are on a phone call")
				}
			} // end of Form
			.navigationBarTitle("Preferences")
		}
	} // end of var body: some View
	
}
