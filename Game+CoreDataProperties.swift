//
//  Game+CoreDataProperties.swift
//  Collectomundo
//
//  Created by Michael Main on 10/18/16.
//  Copyright © 2016 Michael Main. All rights reserved.
//

import Foundation
import CoreData


extension Game {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Game> {
        return NSFetchRequest<Game>(entityName: "Game");
    }

    @NSManaged public var name: String?
    @NSManaged public var platform: String?
    @NSManaged public var releaseDate: NSDate?
    @NSManaged public var coverArt: NSData?
    @NSManaged public var inCollection: Bool
    @NSManaged public var inWishList: Bool

}
