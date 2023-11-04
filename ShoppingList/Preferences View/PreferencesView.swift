//
//  OperationTabView.swift
//  ShoppingList
//
//  Created by Jerry on 6/11/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// this view is for user preferences:
//
// Timer Suspension Preference
// -- whether to suspend the timer when the app goes into the
//    background.  perhaps useful if you don't want to count
//    time spent shopping that you're on the phone, or if you're
//    out browsing on the web.  you be the judge: maybe the phone
//    call is more a last minute shopping request from home, or
//    you use the web to compare prices while you're shopping.
struct PreferencesView: View {
		
	// user default.  true ==> turn off timer (counting) when in the background.
	@AppStorage(kDisableTimerWhenInBackgroundKey)
	private var suspendTimerWhenInBackground = kDisableTimerWhenInBackgroundDefaultValue

	var body: some View {
		NavigationStack {
			Form {
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
