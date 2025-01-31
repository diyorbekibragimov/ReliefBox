//
//  FeedItem+CoreDataProperties.swift
//  ReliefBox
//
//  Created by Diyorbek Ibragimov on 01/02/2025.
//
//

import Foundation
import CoreData


extension FeedItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeedItem> {
        return NSFetchRequest<FeedItem>(entityName: "FeedItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var content: String?

}

extension FeedItem : Identifiable {

}
