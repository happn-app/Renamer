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
		
		tableViewFiles.registerForDraggedTypes([.fileURL])
		
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
				
			default:
				return false
//				return super.validateUserInterfaceItem(item)
		}
	}
	
	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		guard tableView == tableViewFiles else {return nil}
		
		return (arrayControllerFiles.arrangedObjects as! [URL])[row] as NSURL
	}
	
	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		guard tableView == tableViewFiles else {return .init()}
		
		let allow = info.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: readOptions)
		return allow ? .generic : .init()
	}
	
	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
		guard tableView == tableViewFiles else {return false}
		
		guard let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: readOptions) as? [URL] else {
			return false
		}
		urls.reversed().forEach{ arrayControllerFiles.insert($0, atArrangedObjectIndex: row) }
		return true
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
	
}
