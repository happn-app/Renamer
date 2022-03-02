/*
 * ViewController.swift
 * Renamer
 *
 * Created by François Lamboley on 2022/02/23.
 */

import Cocoa



class MainViewController : NSViewController, NSTableViewDataSource, NSUserInterfaceValidations {
	
	@IBOutlet var labelWarning: NSTextField!
	
	@IBOutlet var tableViewFiles: NSTableView!
	@IBOutlet var tableViewFilenames: NSTableView!
	
	@IBOutlet var arrayControllerFiles: NSArrayController!
	@IBOutlet var arrayControllerFilenames: NSArrayController!
	
	@objc dynamic var files = [URL]()        {didSet {updateStateVars()}}
	@objc dynamic var filenames = [String]() {didSet {updateStateVars()}}
	
	@objc dynamic var canRename = true
	@objc dynamic var errorMessage: String?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableViewFiles.registerForDraggedTypes([.fileURL, DraggedFile.draggedType])
		tableViewFilenames.registerForDraggedTypes([.fileURL, DraggedFilename.draggedType])
		
		files = []
		filenames = []
	}
	
	override var representedObject: Any? {
		didSet {
		}
	}
	
	@IBAction func copy(_ sender: AnyObject) {
		let pasteboard = NSPasteboard.general
		switch view.window?.firstResponder {
			case tableViewFiles:
				let urls = arrayControllerFiles.selectedObjects as! [URL]
				pasteboard.clearContents()
				pasteboard.writeObjects(urls as [NSURL])
				pasteboard.setString(urls.map{ $0.path }.joined(separator: "\n"), forType: .string)
				
			case tableViewFilenames:
				let lines = arrayControllerFilenames.selectedObjects as! [String]
				pasteboard.clearContents()
				pasteboard.setString(lines.joined(separator: "\n"), forType: .string)
				
			default:
				NSSound.beep()
		}
	}
	
	@IBAction func paste(_ sender: AnyObject) {
		let pasteboard = NSPasteboard.general
		guard let string = (pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String])?.first
		else {NSSound.beep(); return}
		
		var lines = [String]()
		string.enumerateLines{ line, _ in lines.append(line) }
		lines = lines
			.map{ line in
				line
					.trimmingCharacters(in: .whitespacesAndNewlines)
					.replacingOccurrences(of: "/", with: "_")
			}
			.filter{ !$0.isEmpty }
		arrayControllerFilenames.remove(contentsOf: arrayControllerFilenames.arrangedObjects as! [Any])
		arrayControllerFilenames.add(contentsOf: lines)
	}
	
	@IBAction func delete(_ sender: AnyObject) {
		switch view.window?.firstResponder {
			case tableViewFiles:
				arrayControllerFiles.remove(atArrangedObjectIndexes: arrayControllerFiles.selectionIndexes)
				
			case tableViewFilenames:
				arrayControllerFilenames.remove(atArrangedObjectIndexes: arrayControllerFilenames.selectionIndexes)
				
			default:
				NSSound.beep()
		}
	}
	
	override func keyDown(with event: NSEvent) {
		guard event.specialKey == .delete else {
			return super.keyDown(with: event)
		}
		delete(event)
	}
	
	func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
		switch item.action {
			case #selector(MainViewController.copy(_:))?:
				switch view.window?.firstResponder {
					case tableViewFiles:     return !tableViewFiles.selectedRowIndexes.isEmpty
					case tableViewFilenames: return !tableViewFilenames.selectedRowIndexes.isEmpty
					default: return false
				}
				
			case #selector(MainViewController.paste(_:))?:
				return NSPasteboard.general.canReadObject(forClasses: [NSString.self], options: nil)
				
			case #selector(MainViewController.delete(_:))?:
				switch view.window?.firstResponder {
					case tableViewFiles:     return !tableViewFiles.selectedRowIndexes.isEmpty
					case tableViewFilenames: return !tableViewFilenames.selectedRowIndexes.isEmpty
					default: return false
				}
				
			default:
				return false
//				return super.validateUserInterfaceItem(item)
		}
	}
	
	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		switch tableView {
			case tableViewFiles:     return DraggedFile(sourceRow: row)
			case tableViewFilenames: return DraggedFilename(sourceRow: row)
			default:                 return nil
		}
	}
	
	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		switch tableView {
			case tableViewFiles:
				let canRead = (
					info.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: readOptions) ||
					info.draggingPasteboard.canReadObject(forClasses: [DraggedFile.self], options: nil)
				)
				return (canRead && dropOperation == .above) ? .generic : .init()
				
			case tableViewFilenames:
				let canRead = info.draggingPasteboard.canReadObject(forClasses: [DraggedFilename.self], options: nil)
				return (canRead && dropOperation == .above) ? .generic : .init()
				
			default:
				return .init()
		}
		
	}
	
	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
		switch tableView {
			case tableViewFiles:
				if let draggedFiles = info.draggingPasteboard.readObjects(forClasses: [DraggedFile.self], options: nil) as? [DraggedFile], !draggedFiles.isEmpty {
					let draggedRows = Set(draggedFiles.map{ $0.sourceRow }).sorted()
					
					let delta = draggedRows.firstIndex{ $0 >= row } ?? draggedRows.count
					let added = draggedRows.map{ (arrayControllerFiles.arrangedObjects as! [URL])[$0] }
					
					arrayControllerFiles.remove(atArrangedObjectIndexes: IndexSet(draggedRows))
					arrayControllerFiles.insert(contentsOf: added, atArrangedObjectIndexes: IndexSet(draggedRows.enumerated().map{ row - delta + $0.offset }))
					
					return true
				}
				if let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: readOptions) as? [URL], !urls.isEmpty {
					urls.reversed().forEach{ arrayControllerFiles.insert($0, atArrangedObjectIndex: row) }
					return true
				}
				return false
				
			case tableViewFilenames:
				if let draggedFilenames = info.draggingPasteboard.readObjects(forClasses: [DraggedFilename.self], options: nil) as? [DraggedFilename], !draggedFilenames.isEmpty {
					let draggedRows = Set(draggedFilenames.map{ $0.sourceRow }).sorted()
					
					let delta = draggedRows.firstIndex{ $0 >= row } ?? draggedRows.count
					let added = draggedRows.map{ (arrayControllerFilenames.arrangedObjects as! [String])[$0] }
					
					arrayControllerFilenames.remove(atArrangedObjectIndexes: IndexSet(draggedRows))
					arrayControllerFilenames.insert(contentsOf: added, atArrangedObjectIndexes: IndexSet(draggedRows.enumerated().map{ row - delta + $0.offset }))
					
					return true
				}
				return false
				
			default:
				return false
		}
		
	}
	
	private let readOptions = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: false]
	
	private func updateStateVars() {
		guard files.count == filenames.count else {
			errorMessage = NSLocalizedString("cannot rename err: files and filenames do not have the same number of elements", value: "⚠️ The files and file names tables do not have the same number of elements.", comment: "Text shown when the number of elements in the files and the file names tables are not equal.")
			canRename = false
			return
		}
		guard !files.isEmpty else {
			errorMessage = nil
			canRename = false
			return
		}
		guard Set(files).count == files.count else {
			errorMessage = NSLocalizedString("cannot rename err: files has duplicates", value: "⚠️ The files table contains the same item more than once.", comment: "Text shown when the files table contains the same item more than once.")
			canRename = false
			return
		}
		guard Set(filenames).count == filenames.count else {
			errorMessage = NSLocalizedString("cannot rename err: filenames has duplicates", value: "⚠️ The file names table contains the same item more than once.", comment: "Text shown when the filenames table contains the same item more than once.")
			canRename = false
			return
		}
		guard !filenames.contains(where: { $0.contains("/") }) else {
			errorMessage = NSLocalizedString("cannot rename err: filenames contains invalid name", value: "⚠️ The file names table contains an item with an invalid name (check for punctuation, etc.)", comment: "Text shown when the filenames table contains an item with an invalid name.")
			canRename = false
			return
		}
		
		errorMessage = nil
		canRename = true
	}
	
	private final class DraggedFile : NSObject, NSPasteboardWriting, NSPasteboardReading {
		
		static var draggedType = NSPasteboard.PasteboardType("com.happn.renamer.main-view-controller.files")
		
		static func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
			[draggedType]
		}
		
		var sourceRow: Int
		
		init(sourceRow: Int) {
			self.sourceRow = sourceRow
		}
		
		init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
			guard type == Self.draggedType, let r = propertyList as? Int else {
				return nil
			}
			self.sourceRow = r
		}
		
		func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
			return [Self.draggedType]
		}
		
		func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
			assert(type == Self.draggedType)
			return sourceRow
		}
		
		static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
			assert(type == Self.draggedType)
			return [.asPropertyList]
		}
		
	}
	
	private final class DraggedFilename : NSObject, NSPasteboardWriting, NSPasteboardReading {
		
		static var draggedType = NSPasteboard.PasteboardType("com.happn.renamer.main-view-controller.filenames")
		
		static func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
			[draggedType]
		}
		
		var sourceRow: Int
		
		init(sourceRow: Int) {
			self.sourceRow = sourceRow
		}
		
		init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
			guard type == Self.draggedType, let r = propertyList as? Int else {
				return nil
			}
			self.sourceRow = r
		}
		
		func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
			return [Self.draggedType]
		}
		
		func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
			assert(type == Self.draggedType)
			return sourceRow
		}
		
		static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
			assert(type == Self.draggedType)
			return [.asPropertyList]
		}
		
	}
	
}
