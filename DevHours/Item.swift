//
//  Item.swift
//  DevHours
//
//  Created by Tobias Fu on 12/13/25.
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
