//
//  Array+Extensions.swift
//  ShoppingList
//
//  Created by Jerry on 1/12/24.
//  Copyright © 2024 Jerry. All rights reserved.
//

import Foundation

extension Array {
	
	// this is a generic function you can use on an array
	// to break it into subarrays according to some Hashable
	// value, such as "by date" or "by the name's first letter,"
	// and you can specify how to order the subarrays within an
	// enclosing array according to this value.
	//
	// for example, starting with an array of Strings such as
	//
	//   let names = ["Avery", "Bob", "Carol", "Alice", "Charlie", "Dan", "Bill"]
	//
	// we can produce this array of subarrays by first letter
	// appearing by groups from D to A:
	//
	//  [["Dan"], ["Carol", "Charlie"], ["Bob", "Bill"], ["Avery", ""Alice"]]
	//
	// it's as simple as writing:
	//
	//   let groupedNames = names.grouped(by: { $0.firstLetter }, orderingFunction: >)
	//
	// and the firstLetter function when applied to a string is
	//
	// func firstLetterString(str: String) -> String {
	//   String(str.first(where: { $0.isLetter })!)
	// }
	//
	// similarly, to produce an array of subarrays based on increasing
	// string length, use
	//
	//   let groupedNames = names.grouped(by: { $0.count }, orderingFunction: <)
	//
	// so that you get
	//
	//   [["Dan", "Bob"], ... , ["Charlie"]]
	//
	// note: i don't use this anywhere in the project ... but i do use its basic operation
	// more directly in the AllMyItemsView (it's simpler in that case to have the
	// dictionary elements themselves available, with both the key and value).
	func grouped<T: Hashable>(by groupingFunction: (Element) -> T,
														orderedBy orderingFunction: (T, T) -> Bool) -> Array<Array<Element>> {
		Dictionary(grouping: self, by: { groupingFunction($0) })
			.sorted { orderingFunction($0.key, $1.key) }
			.map { $0.value }
	}
	
}
