/*
 * ViewController.swift
 * Renamer
 *
 * Created by François Lamboley on 2022/02/23.
 */

import Cocoa



class MainViewController : NSViewController {
	
	@IBOutlet var tableViewFiles: NSTableView!
	@IBOutlet var tableViewFilenames: NSTableView!
	
	@IBOutlet var arrayControllerFiles: NSArrayController!
	@IBOutlet var arrayControllerFilenames: NSArrayController!
	
	@objc dynamic var files = [URL]()
	@objc dynamic var filenames = [String]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		files = [URL(fileURLWithPath: "/amazing/path")]
		filenames = ["Amazing New Name"]
	}
	
	override var representedObject: Any? {
		didSet {
		}
	}
	
}
