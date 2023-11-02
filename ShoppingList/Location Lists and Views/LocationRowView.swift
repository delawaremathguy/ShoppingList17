//
//  LocationRowView.swift
//  ShoppingList
//
//  Created by Jerry on 6/1/20.
//  Copyright © 2020 Jerry. All rights reserved.
//

import SwiftUI

// MARK: - LocationRowView

struct LocationRowView: View {
	
	var location: Location
	
	 //var rowData: LocationRowData

	var body: some View {
		HStack {
			// color bar at left (new in this code)
			location.color
				.frame(width: 10, height: 36)
			
			VStack(alignment: .leading) {
				Text(location.name)
					.font(.headline)
				Text(subtitle())
					.font(.caption)
			}
			// we do not show the location index in SL16
//			if !location.isUnknownLocation {
//				Spacer()
//				Text(String(location.visitationOrder))
//			}
		} // end of HStack
	} // end of body: some View
	
	func subtitle() -> String {
		let count = location.items.count
		if count == 1 {
			return "1 item"
		} else {
			return "\(count) items"
		}
	}
	
}
