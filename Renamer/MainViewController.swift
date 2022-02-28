/*
 * ViewController.swift
 * Renamer
 *
 * Created by François Lamboley on 2022/02/23.
 */

import Cocoa



class MainViewController : NSViewController, NSTableViewDataSource {
	
	@IBOutlet var tableViewFiles: NSTableView!
	@IBOutlet var tableViewFilenames: NSTableView!
	
	@IBOutlet var arrayControllerFiles: NSArrayController!
	@IBOutlet var arrayControllerFilenames: NSArrayController!
	
	@objc dynamic var files = [URL]()
	@objc dynamic var filenames = [String]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableViewFiles.registerForDraggedTypes([.fileURL])
		
		files = []
		filenames = ["Amazing New Name"]
	}
	
	override var representedObject: Any? {
		didSet {
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
	
}
