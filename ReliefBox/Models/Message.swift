//
//  Message.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 01/02/2025.
//


import Foundation
import UIKit
struct Message: Hashable {
    let id = UUID()
    var content: String
    var isCurrentUser: Bool
    var image: UIImage? = nil
}
struct DataSource {
    static let messages: [Message] = []
}
