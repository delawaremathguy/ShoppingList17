//
//  View+Extensions.swift
//  ShoppingList
//
//  Created by Jerry on 2/17/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftUI

extension View {
	
	func hCentered() -> some View {
		HStack {
			Spacer()
			self
			Spacer()
		}
	}
}
