//
//  IceResourceLocator.swift
//  Ice
//

import Cocoa

enum IceResourceLocator {
    #if SWIFT_PACKAGE
    static let resourceBundle = Bundle.module
    #else
    static let resourceBundle = Bundle.main
    #endif

    static func nsImage(named name: String) -> NSImage? {
        if let image = NSImage(named: name) {
            return image
        }

        guard let resourceURL = resourceBundle.resourceURL else {
            return nil
        }

        let fileManager = FileManager.default
        let resourceName = "\(name).png"
        guard let enumerator = fileManager.enumerator(at: resourceURL, includingPropertiesForKeys: nil) else {
            return nil
        }

        for case let fileURL as URL in enumerator where fileURL.lastPathComponent == resourceName {
            let image = NSImage(contentsOf: fileURL)
            image?.isTemplate = true
            return image
        }

        return nil
    }
}
