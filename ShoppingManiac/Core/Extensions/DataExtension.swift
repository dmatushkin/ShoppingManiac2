//
//  DataExtension.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 25.01.2022.
//

import Foundation
import CommonError

extension Data {
    
    func store(fileExtension: String = ".smstorage") throws -> URL {
        let fileManager = FileManager.default
        let normalizedExtension = fileExtension.hasPrefix(".") ? fileExtension : ".\(fileExtension)"
        let exportsURL = fileManager.temporaryDirectory.appendingPathComponent("ShoppingManiacExports", isDirectory: true)
        do {
            try fileManager.createDirectory(at: exportsURL, withIntermediateDirectories: true)
            let filesList = try fileManager.contentsOfDirectory(at: exportsURL, includingPropertiesForKeys: nil)
            for file in filesList where file.lastPathComponent.hasSuffix(normalizedExtension) {
                try fileManager.removeItem(at: file)
            }
        } catch {
            throw CommonError(description: "Unable to prepare export folder: \(error.localizedDescription)")
        }

        let fileName = UUID().uuidString + normalizedExtension
        let fileURL = exportsURL.appendingPathComponent(fileName)
        try write(to: fileURL, options: .atomic)
        return fileURL
    }
}
