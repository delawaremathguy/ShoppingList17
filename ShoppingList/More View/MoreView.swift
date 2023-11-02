//
//  MoreView.swift
//  ShoppingList
//
//  Created by Jerry on 7/23/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

	// this is a new view to hold the timer (really, the timer does not need its own
	// tab) and two buttons to import/export an shopping list archive.
	// future: for an iPad, we could break out the timer as a separate item
	// in the sidebar; but who really brings an iPad with them when they shop?
struct MoreView: View {
	
	@Environment(\.modelContext) private var modelContext
	
		// @State variables to handle presenting of file importer and file
		// exporter, as well as what document we want to export.
	@State private var isFileImporterPresented = false
	@State private var isFileExporterPresented = false
	@State private var archiveDocument: ArchiveDocument?
	
		// controls for presenting an alert after exporting or importing data
		// to tell you what happened.
	@State private var isAlertPresented = false
	@State private var alertTitle: String = ""
	@State private var alertMessage: String = ""
	
	@Query() private var items: [Item]
	@Query() private var locations: [Location]

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				Divider()
				TimerView()
				Divider()
				List {
					Section("Shopping List Archive") {
						
						Button {
							isFileImporterPresented = true // trigger the fileImporter
						} label: {
							Label("Import Data from Files", systemImage: "arrow.down.doc")
						}
						
						Button {
							archiveDocument = ArchiveDocument(locations: locations)
							isFileExporterPresented = true // trigger the fileExporter with a document
						} label: {
							Label("Archive Data To Files", systemImage: "arrow.up.doc")
						}
					}
					.buttonStyle(.plain)
					
#if targetEnvironment(simulator)
					Section("Developer Actions") {
						// 1.  load sample data
						Button("Load Sample Data", action: loadSampleData)
						.hCentered()
						.disabled(items.count > 0)
					} // end of Section
#endif
					
				}
			}
			.navigationBarTitle("More ...")
			.alert(alertTitle, isPresented: $isAlertPresented) {
				Button("OK", action: { /* do nothing ... the alert will dismiss when OK is tapped */ })
			} message: {
				Text(alertMessage)
			}
			.fileImporter(isPresented: $isFileImporterPresented,
										allowedContentTypes: [UTType.archiveDocumentType]) { result in
				handleFileImportResult(result: result)
			}
			.fileExporter(isPresented: $isFileExporterPresented,
										document: archiveDocument,
										contentType: UTType.archiveDocumentType,
										defaultFilename: "Exported Shopping List") { result in
				handleFileExporterResult(result: result)
				archiveDocument = nil	// there's no need to hold on to this.
			}
		}
	} // end of var body: some View
	
}

	// MARK: - Load Sample Data on Simulator

extension MoreView {
	
	func loadSampleData() {
		let beginLocationCount = locations.count // what it is now
		let beginItemCount = items.count // what it is now
		
			// use new archive format straight from an archive document in the bundle
		var locationRepresentations: [LocationRepresentation] = Bundle.main.decode(from: "ExportedShoppingList.json")
		locationRepresentations.sort(by: { $0.visitationOrder < $1.visitationOrder })
		for representation in locationRepresentations {
			modelContext.updateOrInsert(representation: representation)
		}
		
		let locationsAdded = modelContext.locationCount() - beginLocationCount // now the differential
		let itemsAdded = modelContext.itemCount() - beginItemCount // now the differential
		
		alertTitle = "Data Added."
		alertMessage = "Sample data for the app (\(locationsAdded) locations and \(itemsAdded) shopping items) have been added."
		isAlertPresented = true
	}
	
}

	// MARK: - File Export Handling

extension MoreView {
	
		// we can quickly handle the return of the fileExporter, which is either telling
		// us the URL where the file was saved (the app does not need this, but it
		// is useful when working on the simulator) or what, if any, error occurred.
	func handleFileExporterResult(result: Result<URL, Error>) {
		switch result {
			case .success(let url):
				print("Saved to \(url)")
				alertTitle = "Success."
				alertMessage = "All ShoppingList data have been successfully archived."
				isAlertPresented = true
				
			case .failure(let error):
				alertTitle = "OOPS, something went wrong."
				alertMessage = "The error being reported is \(error.localizedDescription)."
				isAlertPresented = true
		}
	}
	
}

	// MARK: - FileImporter Functions

extension MoreView {
	
		// this is the first level of handling the result of the fileImporter, which has
		// given us a Result<URL, Error> to indicate whether we succeeded in getting
		// a URL for the incoming archive data, or whether there was some system error.
	func handleFileImportResult(result: Result<URL, Error>) {
		switch result {
				
				// success ==> read the ArchiveDocument from disk.
			case .success(let url):
					// get the result of reading in the content of a new ArchiveDocument.
					// we're passing along another Result type here to a second level.
				let importResult = ArchiveDocument.createNew(from: url)
				handleImportResult(importResult)
				
				// failure ==> post an alert.
			case .failure(let error):
				print(error.localizedDescription)
				alertTitle = "OOPS, something went wrong."
				alertMessage = "The error being reported is \(error.localizedDescription)."
				isAlertPresented = true
		}
	}
	
		// this is the second level of handling what the fileImporter started.  at this
		// point, we're looking as a Result<ArchiveDocument, Error> to indicate whether
		// we succeeded in reading in data and creating a valid ArchiveDocument, or
		// whether there was some reading or decoding error.
	private func handleImportResult(_ result: Result<ArchiveDocument, Error>) {
		
		switch result {
				
					// failure ==> post an alert.
			case .failure(let error):
				alertTitle = "OOPS, something went wrong."
				alertMessage = "The error being reported is \(error.localizedDescription)."
				isAlertPresented = true
				
					// success ==> we have a valid ArchiveDocument that was read from disk
					// without error, so pull all its data by locationRepresentations and ask
					// the Location class to figure out what to do with them in its
					// updateOrInsert method.
			case .success(let archiveDocument):
					// add/update incoming items and locations, but do this according
					// to visitationOrder of locations
				archiveDocument
					.locationRepresentations
					.sorted(by: { $0.visitationOrder < $1.visitationOrder })
					.forEach { modelContext.updateOrInsert(representation: $0) }
				
					// this is the only tricky thing ...we have incorporated the incoming,
					// but before we post a Success alert, we'll wait just a bit to let SwiftUI
					// settle down, to give it time to dismiss the fileImporter.
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					alertTitle = "Success."
					alertMessage = "ShoppingList data have been imported."
					isAlertPresented = true
				}
		}
	} // end of func handleImportResult
	
} // end of extension SessionListView: View

