/*
 * UntouchablePathControl.swift
 * Renamer
 *
 * Created by François Lamboley on 01/03/2022.
 */

import AppKit
import Foundation



final class UntouchablePathControl : NSPathControl {
	
	override func hitTest(_ point: NSPoint) -> NSView? {
		return nil
	}
	
}
