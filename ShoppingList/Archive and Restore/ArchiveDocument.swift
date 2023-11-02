//
//  ArchiveDocument.swift
//  ShoppingList
//
//  Created by Jerry on 7/23/23.
//  Copyright © 2023 Jerry. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

	// we need this extension to define the type (by signature) that is associated
	// with documents that we import/export.  see Document Types and Exported
	// Type Identifier in the project file, for the ShoppingList target, under Info.
extension UTType {
	static let archiveDocumentType = UTType(exportedAs: "com.dela.ware.math.ShoppingList.archive")
}

	// definition of a document that we can export or import with a .shoppingList extension.
	// it conforms to FileDocument, so that it can be used with a .fileExporter.
	// (we also use it with the fileImporter, although we don't really have to do
	// this, but it keeps all the I/O code in one place.)
	// its content is an array of LocationRepresentations.  its main responsibility:
	// serializing data to and from disk.
struct ArchiveDocument: FileDocument {
	
		// tell the system we support only json text
	static var readableContentTypes = [UTType.archiveDocumentType]
	static var writableContentTypes = [UTType.archiveDocumentType]
	
		// class method to create a file document from a url and return a Result type
		// so the caller can decide what to do about any error
	static func createNew(from url: URL) -> Result<ArchiveDocument, Error> {
		do {
			let document = try ArchiveDocument(url: url)
			return .success(document)
		} catch let error { // the only errors thrown are .accessDenied, .fileUnreadable, .fileNotDecodable
			return .failure(error)
		}
	}
	
		// instance property: a JSON data representing locations (and their associated items)
	let locationRepresentations: [LocationRepresentation]
	
		// MARK: Initializers
	
		// initializer, given an array of all Locations (Core Data objects)
	init(locations: [Location]) {
		locationRepresentations = locations.map({ LocationRepresentation(from: $0) })
	}
	
		// this initializer loads data that has been saved previously, if given a
		// read configuration by the OS.  i don't think this is actually called at
		// the moment since we don't really have an Open command like you have
		// in a MacOS app ... but it would be useful if you emailed an archive
		// document to someone else, who then just by tapping on the document
		// inside Mail will open the ShoppingList app and read in the document.
		// (i have not implemented this capability as of yet ...)
	init(configuration: ReadConfiguration) throws {
		guard let data = configuration.file.regularFileContents else {
			throw ArchiveImportError.fileUnreadable
		}
		do {
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			locationRepresentations = try decoder.decode([LocationRepresentation].self, from: data)
		} catch let error {
			print("Unable to read file: \(error.localizedDescription)")
			locationRepresentations = []
			throw ArchiveImportError.fileNotDecodable
		}
	}
	
		// an initializer when given just a url, as we are in the result of .fileExporter
		// (the result is actually of type Result<ArchiveDocument, Error>).
	init(url: URL) throws {
		
			// be sure on exit we release any hold we have on the file.
		defer { url.stopAccessingSecurityScopedResource() }
		
			// Start accessing the security-scoped resource.
		guard url.startAccessingSecurityScopedResource() else {
			print("can't access security scoped resource")
			throw ArchiveImportError.accessDenied
		}
		
			// get data first -- we want to see any error here (especially during development)
		var data: Data!
		do {
			data = try Data(contentsOf: url)
		} catch let error as NSError {
			print("Unable to read file: \(error.localizedDescription)")
			throw ArchiveImportError.fileUnreadable
		}
		
			// try to decode the data, and we're done.
		do {
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			locationRepresentations = try decoder.decode([LocationRepresentation].self, from: data)
		} catch let error as NSError {
			print("Unable to decode file: \(error.localizedDescription)")
			throw ArchiveImportError.fileNotDecodable
		}
	}
	
		// MARK: - Serialization (Output)
	
		// this will be called when the system wants to write data to disk.  in this case,
		// we just need to encode what we have as data to a regular file.
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.dateEncodingStrategy = .iso8601
		let data = try! encoder.encode(locationRepresentations)
		return FileWrapper(regularFileWithContents: data)
	}
	
}

	// MARK: - Errors When Importing Archive Files.

enum ArchiveImportError: LocalizedError {
	case accessDenied
	case fileUnreadable
	case fileNotDecodable
	
		// this could be fleshed out a little more (!)
	var errorDescription: String { "\(self)" }
}
