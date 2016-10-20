//
//  GiantBombSDK.swift
//  Collectomundo
//
//  Created by Michael Main on 10/18/16.
//  Copyright © 2016 Michael Main. All rights reserved.
//

import Foundation

struct GBGame {
    var gameId : String = "none-id"
    var name : String = "Unknown"
    var platform : String = "Unknown"
    var platformKey : String = "N/A"
    var releaseDate : Date?
    var coverArtUrl : String! = nil
    var coverArtData : Data! = nil
    var detailUrl : String! = nil
    
    var inCollection : Bool = false
    var inWishList   : Bool = false
}

class GiantBombConfig {
    static var apiKey = "0d5aa02fcea0a5604aad3cbf1af4fd5acb44fddf"
}

enum GiantBombException : Error {
    case jsonParsingError(message: String)
    case httpError(message: String, statusCode: Int)
    case clientError(message: String)
}

class GiantBombSDK {
    func getGamesByName(
        name: String,
        platformFilter: [String],
        completionHandler: (([GBGame], Int) -> Void)!,
        errorHandler: ((Error) -> Void)!) {
        let client = NBRestClient.get(
            hostname: "www.giantbomb.com",
            uri: "/api/games",
            query: [
                "api_key" : GiantBombConfig.apiKey as AnyObject,
                "format" : "json" as AnyObject,
                "field_list" : "name,company,image,release_date,platforms,original_release_date,id,site_detail_url" as AnyObject,
                "filter" : "name:\(name)" as AnyObject
            ],
            ssl: true)
        
        client.sendAsync(completionHandler: {(response: NBRestResponse!) -> Void in
            do {
                let body : Any = try self.processResponse(response: response)
                
                print(body as! Dictionary<String, Any>)
                
                // Acquire the results from the results key at the root of the returned object
                let results = JSONHelper.search(path: "/results", object: body) as! Array<AnyObject>
                let pages = 0
                
                // On no results
                if (results.count <= 0) {
                    if (completionHandler != nil) {
                        completionHandler([], pages)
                    }
                    return
                }
                
                var games = [GBGame]()
                for result in results {
                    let temp1 = JSONHelper.search(path: "/platforms", object: result)
                    let platforms = temp1 != nil ? temp1 as! Array<AnyObject> : []
                    
                    for platform in platforms {
                        let temp2 = JSONHelper.search(path: "/image/small_url", object: result)
                        
                        var game = GBGame()
                        game.name = result["name"] as! String
                        game.coverArtUrl = temp2 != nil ? temp2 as! String : nil
                        game.platform = platform["name"] as! String
                        game.platformKey = platform["abbreviation"] as! String
                        game.detailUrl = result["site_detail_url"] as! String
                        game.gameId = "\(platform["abbreviation"] as! String):\(result["id"] as! Int)"
                        
                        
                        if (!(result["original_release_date"] is NSNull)) {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            game.releaseDate = dateFormatter.date(from: result["original_release_date"] as! String)!
                        }
                        if (platformFilter.contains(game.platformKey)) {
                            games.append(game)
                        }
                    }
                }
                
                if (completionHandler != nil) {
                    completionHandler(games, pages)
                    return
                }
            } catch {
                if (errorHandler != nil) {
                    errorHandler(error)
                }
            }
        })
    }
    
    private func processResponse(response: NBRestResponse) throws -> Any! {
        // If error is set, display it and fail
        if (response.error != nil) {
            throw GiantBombException.clientError(message: response.error!.localizedDescription)
        }
        
        // Deserialize json
        var data : Any! = nil
        do {
            try data = JSONSerialization.jsonObject(with: response.body, options: .allowFragments)
        } catch {
            throw GiantBombException.jsonParsingError(message: error.localizedDescription)
        }
        
        print("Status Code:  \(response.statusCode)")
        
        // If status code not 201, then fail
        if (response.statusCode != 200) {
            throw GiantBombException.httpError(message: "Non 200 status code", statusCode: response.statusCode)
        }
        
        return data
    }
}
