//
//  UserDefaultDefinitions.swift
//  ShoppingList
//
//  Created by Jerry on 12/16/22.
//  Copyright © 2022 Jerry. All rights reserved.
//

import Foundation

// i collect all the keys and default values for what are to be the User Defaults.
// this is to be sure that all the strings defining the keys are in exactly one
// place and not scattered throughout the SwiftUI views when defining their
// local access to the user default.

// @AppStorage keys
let kShoppingListIsMultiSectionKey = "kShoppingListIsMultiSectionKey"
let kAllMyItemsListIsMultiSectionKey = "kPurchasedListIsMultiSectionKey"
let kDisableTimerWhenInBackgroundKey = "kDisableTimerWhenInBackgroundKey"

// @AppStorage default values
let kShoppingListIsMultiSectionDefaultValue = false
let kAllMyItemsListIsMultiSectionDefaultValue = false
let kDisableTimerWhenInBackgroundDefaultValue = false
