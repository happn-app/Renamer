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
	
	@objc dynamic var canRename = false
	@objc dynamic var filesAndFilenamesCountIsEqual = true
	
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
		filesAndFilenamesCountIsEqual = files.count == filenames.count
		canRename = filesAndFilenamesCountIsEqual && !files.isEmpty
	}
	
}
