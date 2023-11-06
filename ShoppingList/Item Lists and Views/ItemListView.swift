	//
	//  ShoppingListDisplay.swift
	//  ShoppingList
	//
	//  Created by Jerry on 2/7/21.
	//  Copyright © 2021 Jerry. All rights reserved.
	//

import Foundation
import SwiftUI

	// MARK: - ItemListView

/*
this is a subview of the ShoppingListView and the AllMyItemsView,
and shows a sectioned list of Items that is determined by the caller.

each item that appears has a NavigationLink to a detail view and has a
contextMenu associated with it; an action from the contextMenu to delete
an Item will require bringing up an alert to confirm the deletion.
*/

struct ItemListView: View {
	
	@Environment(\.modelContext) private var modelContext
	
	// this is the incoming section layout of items handed to us
	// by either the ShoppingListView or the AllMyItemsView
	var itemSections: [ItemSection]
	
	// the symbol to show for an Item that is tapped
	var sfSymbolName: String
	
	// controls for opening a confirmation dialog to delete some Item:
	// a Bool to trigger the dialog, plus a reference to the Item to be
	// deleted (set in the Context Menu).  also, to make the strings
	// defined in the confirmation dialog a little less ugly, we'll define
	// a computed variable to return the item's name.
	@State private var isConfirmItemDeletePresented = false
	@State private var itemToDelete: Item?
	private var itemToDeleteName: String { itemToDelete?.name ?? "No Name" }
	
	// this is a temporary holding array for items being moved to the other list.  it's a
	// @State variable, so if any SelectableItemRowView or a context menu adds an Item
	// to this array, we will get some redrawing + animation; and we'll also have queued
	// the actual execution of the move to the other list to follow after the animation
	// completes -- and that deletion will again change this array and redraw.
	@State private var itemsChecked = [Item]()
	
	// MARK: - BODY
	
	var body: some View {
		List(itemSections) { section in
			Section(header: Text(section.title)) {
				ForEach(section.items) { item in
					NavigationLink(value: item) {
						SelectableItemRowView(item: item,
																	selected: itemsChecked.contains(item),
																	sfSymbolName: sfSymbolName) { handleItemTapped(item) }
					}
					.contextMenu {
						ItemContextMenu(item: item)
					} // end of contextMenu
				} // end of ForEach
			} // end of Section
		}  // end of List ... phew!
		.listStyle(.insetGrouped)
//		.navigationDestination(for: Item.self) { item in
//			ModifyExistingItemView(item: item)
//		}
		.animation(.default, value: itemSections)
		.confirmationDialog("Delete \'\(itemToDeleteName)\'?",
												isPresented: $isConfirmItemDeletePresented,
												titleVisibility: .visible) {
			Button("Yes", role: .destructive) {
				if let itemToDelete { // it should be non-nil if called!
					withAnimation {
						modelContext.delete(itemToDelete)
						try? modelContext.save()
					}
				}
			}
		} message: {
			Text("Are you sure you want to delete the Item named \'\(itemToDeleteName)\'? This action cannot be undone.")
		}
			
	} // end of body: some View
	
	// MARK: - Subviews
	
	@ViewBuilder
	func ItemContextMenu(item: Item) -> some View {
		Button {
			if item.onList {
				item.markAsPurchased()
			} else {
				item.onList = true
			}
		} label: {
			Text(item.onList ? "Mark as Purchased" : "Move to ShoppingList")
			Image(systemName: item.onList ? "purchased" : "cart")
		}
		
		Button {
			item.isAvailable.toggle()
		} label: {
			Text(item.isAvailable ? "Mark as Unavailable" : "Mark as Available")
			Image(systemName: item.isAvailable ? "pencil.slash" : "pencil")
		}
		
		Button(role: .destructive) {
			itemToDelete = item
			isConfirmItemDeletePresented = true
		} label: {
			Text("Delete This Item")
			Image(systemName: "trash")
		}
	}

	// MARK: Helper Functions
		
	func handleItemTapped(_ item: Item) {
		// don't do anything if we're animating
		guard !itemsChecked.contains(item) else {
			return
		}
		
		// put the item into our list of what's about to be removed, 
		// and because itemsChecked is a @State variable, we will
		// see a momentary animation showing the change.
		itemsChecked.append(item)
		// and we queue the actual removal long enough to allow animation to finish
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
			withAnimation {
				if item.onList {
					if sfSymbolName == "cart" {
						// we're in the AllMyItemsView, so i'll just change the
						// onList status of the item.  (i need to make this better;
						// it's pretty cheesy to look at the sfSymbolName ...
						item.onList = false
					} else {
						// we're in the ShoppingList, so mark as purchased
						item.markAsPurchased()
					}
				} else {
					item.onList = true
				}
				itemsChecked.removeAll(where: { $0 == item })
			}
		}
	}
		
}

