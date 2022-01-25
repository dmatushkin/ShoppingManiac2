//
//  DataExtension.swift
//  ShoppingManiac2
//
//  Created by Dmitry Matyushkin on 25.01.2022.
//

import Foundation
import CommonError

extension Data {
    
    func store() throws -> URL {
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            throw CommonError(description: "Unable to get documents path")
        }
        let fileExtension = ".smstorage"
        let documentsURL = URL(fileURLWithPath: documentsPath)
        let filesList = try FileManager.default.contentsOfDirectory(atPath: documentsPath)
        for file in filesList {
            if file.hasSuffix(fileExtension) {
                try FileManager.default.removeItem(at: documentsURL.appendingPathComponent(file))
            }
        }
        let fileName = UUID().uuidString + fileExtension
        let fileURL = documentsURL.appendingPathComponent(fileName)
        try write(to: fileURL)
        return fileURL
    }
}
