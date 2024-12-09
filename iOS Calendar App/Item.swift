//
//  Item.swift
//  iOS Calendar App
//
//  Created by Fadi Al Eliwi on 09.12.24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
