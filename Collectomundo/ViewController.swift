//
//  ViewController.swift
//  Collectomundo
//
//  Created by Michael Main on 10/18/16.
//  Copyright © 2016 Michael Main. All rights reserved.
//

import UIKit
import CoreData

class GameSearchTableCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var platformLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var inCollectionLabel: UILabel!
    @IBOutlet weak var gameImage: UIImageView!
    
    override func prepareForReuse() {
        titleLabel.text = ""
        platformLabel.text = ""
        releaseDateLabel.text = ""
        inCollectionLabel.text = ""
        gameImage.image = nil
    }
}

class GameWishListViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var context = DataLayerService.managedObjectContext
    
    lazy var fetchedResultsController : NSFetchedResultsController<Game> = {
        let fetchRequest = NSFetchRequest<Game>(entityName: "Game")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "platform", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "inWishList == true", argumentArray: [])
        
        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.context,
            sectionNameKeyPath: "platform",
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let game = fetchedResultsController.object(at: indexPath)
        let remove = UITableViewRowAction(style: .normal, title: "Remove") { action, index in
            self.removeGame(game: game)
        }
        remove.backgroundColor = UIColor.red
        let move = UITableViewRowAction(style: .normal, title: "Collect") { action, index in
            game.inCollection = true
            game.inWishList = false
            self.updateGame(game: game)
        }
        move.backgroundColor = UIColor(red: 0, green: 0.898, blue: 0.7922, alpha: 1.0)
        return [move, remove]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let game = fetchedResultsController.object(at: indexPath)
        
        let app = UIApplication.shared
        if (game.detailUrl != nil) {
            app.openURL(URL(string: game.detailUrl!)!)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableCell") as! GameSearchTableCell
        
        let game = fetchedResultsController.object(at: indexPath) 
        
        cell.gameImage.contentMode = UIViewContentMode.scaleAspectFit
        cell.titleLabel.text = game.name
        cell.platformLabel.text = game.platform
        cell.releaseDateLabel.text = "N/A"
        cell.inCollectionLabel.text = "In Wishlist"
        if (game.coverArt != nil) {
            cell.gameImage.image = UIImage(data: game.coverArt as! Data)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }
    
    private func removeGame(game: Game) {
        DispatchQueue.main.async {
            do {
                self.context.delete(game)
                try self.context.save()
            } catch {
                print(error)
            }
        }
    }
    
    private func updateGame(game: Game) {
        DispatchQueue.main.async {
            do {
                game.inCollection = true
                game.inWishList = false
                try self.context.save()
            } catch {
                print(error)
            }
        }
    }
}

class GameCollectionViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var context = DataLayerService.managedObjectContext
    
    lazy var fetchedResultsController : NSFetchedResultsController<Game> = {
        let fetchRequest = NSFetchRequest<Game>(entityName: "Game")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "platform", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "inCollection == true", argumentArray: [])
        
        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.context,
            sectionNameKeyPath: "platform",
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
    }()

    override func viewWillAppear(_ animated: Bool) {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let game = fetchedResultsController.object(at: indexPath)
        let remove = UITableViewRowAction(style: .normal, title: "Remove") { action, index in
            self.removeGame(game: game)
        }
        remove.backgroundColor = UIColor.red
        return [remove]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let game = fetchedResultsController.object(at: indexPath)
        
        let app = UIApplication.shared
        if (game.detailUrl != nil) {
            app.openURL(URL(string: game.detailUrl!)!)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableCell") as! GameSearchTableCell
        
        let game = fetchedResultsController.object(at: indexPath)
        
        cell.gameImage.contentMode = UIViewContentMode.scaleAspectFit
        cell.titleLabel.text = game.name
        cell.platformLabel.text = game.platform
        cell.releaseDateLabel.text = "N/A"
        cell.inCollectionLabel.text = "In Collection"
        if (game.coverArt != nil) {
            cell.gameImage.image = UIImage(data: game.coverArt as! Data)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }
    
    private func removeGame(game: Game) {
        DispatchQueue.main.async {
            do {
                self.context.delete(game)
                try self.context.save()
            } catch {
                print(error)
            }
        }
    }
}

class GameSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var sdk = GiantBombSDK()
    static var consoleFilter : [String] = [
        "LYNX", "2600", "5200", "7800", "A800",
        "NES", "FDS", "SNES", "N64", "64DD", "GCN", "WII", "WIIU", "GB", "GBC", "GBA", "DS", "3DS", "VBOY",
        "SG1K", "SMS", "GEN", "SCD", "32X", "SAT", "DC", "GG",
        "TG16", "TGCD",
        "NEO", "NGCD", "NGP", "NGPC",
        "PS1", "PS2", "PS3", "PS4", "PSP", "VITA",
        "XBOX", "X360", "XONE",
        "3DO", "JAG", "CDI"
    ]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var titleSearch: UITextField!
    
    var context = DataLayerService.managedObjectContext
    
    var platformMap = [String:[GBGame]]()
    var platformList = [String]()
    var pages   = 0
    
    var emptyLabel : UILabel?
    var noResultsLabel : UILabel?
    var loadingLabel : UILabel?
    
    override func viewWillAppear(_ animated: Bool) {
        self.emptyLabel = UILabel()
        self.emptyLabel?.text = "Search for Games"
        self.emptyLabel?.textAlignment = .center
        
        self.noResultsLabel = UILabel()
        self.noResultsLabel?.text = "No results"
        self.noResultsLabel?.textAlignment = .center
        
        self.loadingLabel = UILabel()
        self.loadingLabel?.text = "Loading"
        self.loadingLabel?.textAlignment = .center
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.backgroundView = emptyLabel
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = getGameAt(indexPath: indexPath)

        let app = UIApplication.shared
        if (result.detailUrl != nil) {
            app.openURL(URL(string: result.detailUrl)!)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let result = getGameAt(indexPath: indexPath)
        
        if (!result.inCollection && !result.inWishList) {
            let collection = UITableViewRowAction(style: .normal, title: "Collect") { action, index in
                var result = self.getGameAt(indexPath: index)
                
                result.inCollection = true
                result.inWishList = false
                
                self.placeGameAt(indexPath: index, game: result)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.saveToCollection(gbGame: result)
            }
            collection.backgroundColor = UIColor(red: 0, green: 0.898, blue: 0.7922, alpha: 1.0)
            let wishList = UITableViewRowAction(style: .normal, title: "Wishlist") { action, index in
                var result = self.getGameAt(indexPath: index)
                
                result.inCollection = false
                result.inWishList = true
                
                self.placeGameAt(indexPath: index, game: result)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.saveToWishList(gbGame: result)
            }
            wishList.backgroundColor = UIColor(red: 0, green: 1, blue: 0.7333, alpha: 1.0)
            return [collection, wishList]
        } else if (result.inCollection) {
            let remove = UITableViewRowAction(style: .normal, title: "Remove") { action, index in
                var result = self.getGameAt(indexPath: index)
                
                result.inWishList = false
                result.inCollection = false
                
                self.placeGameAt(indexPath: index, game: result)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.removeGame(gbGame: result)
            }
            remove.backgroundColor = UIColor.red
            return [remove]
        } else if (result.inWishList) {
            let remove = UITableViewRowAction(style: .normal, title: "Remove") { action, index in
                var result = self.getGameAt(indexPath: index)
                
                result.inCollection = false
                result.inWishList = false
                
                self.placeGameAt(indexPath: index, game: result)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.removeGame(gbGame: result)
            }
            remove.backgroundColor = UIColor.red
            let move = UITableViewRowAction(style: .normal, title: "Collect") { action, index in
                var result = self.getGameAt(indexPath: index)
                
                self.removeGame(gbGame: result)
                
                result.inCollection = true
                result.inWishList = false
                
                self.placeGameAt(indexPath: index, game: result)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.saveToCollection(gbGame: result)
            }
            move.backgroundColor = UIColor(red: 0, green: 0.898, blue: 0.7922, alpha: 1.0)
            return [move, remove]
        }
        
        return []
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableCell") as! GameSearchTableCell
        let index = indexPath
        var result = getGameAt(indexPath: indexPath)
        
        cell.gameImage.contentMode = UIViewContentMode.scaleAspectFit
        cell.titleLabel.text = result.name
        cell.platformLabel.text = result.platformKey
        cell.releaseDateLabel.text = "N/A"
        
        if (result.inCollection) {
            cell.inCollectionLabel.text = "In Collection"
        } else if (result.inWishList) {
            cell.inCollectionLabel.text = "In Wishlist"
        } else {
            cell.inCollectionLabel.text = ""
        }
        
        if (result.coverArtData != nil) {
            cell.gameImage.image = UIImage(data: result.coverArtData)
        } else {
            let concurrentQueue = DispatchQueue(label: "queuename", attributes: .concurrent)
            concurrentQueue.async {
                do {
                    // Load image asynchronously
                    if (result.coverArtUrl != nil) {
                        let url = URL(string: result.coverArtUrl)
                        let data = try Data(contentsOf: url!)
                        result.coverArtData = data
                        self.placeGameAt(indexPath: index, game: result)
                        DispatchQueue.main.async {
                            cell.gameImage.image = UIImage(data: data)
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(platformMap.keys)[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Array(platformMap.keys).count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return platformMap[Array(platformMap.keys)[section]]!.count
    }

    @IBAction func searchPressed(_ sender: AnyObject) {
        if (titleSearch.text!.isEmpty) {
            return
        }
        setLoadingScreen()
        sdk.getGamesByName(
            name: titleSearch.text!,
            platformFilter: GameSearchViewController.consoleFilter,
            completionHandler: {(games: [GBGame], pages: Int) -> Void in
                self.platformList = [String]()
                self.platformMap = [String:[GBGame]]()
                self.pages = pages
                
                DispatchQueue.main.async {
                    for var game in games {
                        let fetchRequest = NSFetchRequest<Game>(entityName: "Game")
                        fetchRequest.predicate = NSPredicate(format: "gameId == %@", game.gameId)
                        
                        do {
                            let result = try self.context.fetch(fetchRequest)
                            if (result.count > 0) {
                                game.inCollection = result[0].inCollection
                                game.inWishList = result[0].inWishList
                            }
                        } catch {
                            print(error)
                        }
                        if (self.platformMap[game.platformKey] == nil) {
                            self.platformMap[game.platformKey] = [GBGame]()
                        }
                        self.platformMap[game.platformKey]?.append(game)
                    }
                    
                    self.platformList = Array(self.platformMap.keys)
                    
                    self.tableView.reloadData()
                    self.removeLoadingScreen()
                }
            },
            errorHandler: {(error: Error) -> Void in
                print("Error: \(error)")
                DispatchQueue.main.async {
                    self.removeLoadingScreen()
                    self.tableView.backgroundView = self.noResultsLabel
                }
            })
    }
    
    private func getPlatformBy(section: Int) -> String! {
        if (section < 0 || section > self.platformList.count) {
            return nil
        }
        return self.platformList[section]
    }
    
    private func getGameListForPlatform(platform: String!) -> [GBGame] {
        if (platform == nil) {
            return []
        }
        return self.platformMap[platform]!
    }
    
    private func getGameAt(indexPath : IndexPath) -> GBGame {
        let key = getPlatformBy(section: indexPath.section)
        let list = getGameListForPlatform(platform: key)
        return list[indexPath.row]
    }
    
    private func placeGameAt(indexPath : IndexPath, game : GBGame) {
        let key = getPlatformBy(section: indexPath.section)
        
        if (key == nil) {
            return
        }
        
        self.platformMap[key!]![indexPath.row] = game
    }
    
    private func removeGame(gbGame: GBGame) {
        DispatchQueue.main.async {
            let fetchRequest = NSFetchRequest<Game>(entityName: "Game")
            fetchRequest.predicate = NSPredicate(format: "gameId == %@", gbGame.gameId)
            
            do {
                var results = try self.context.fetch(fetchRequest)
                if (results.count > 0) {
                    self.context.delete(results[0])
                    try self.context.save()
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func saveToCollection(gbGame: GBGame) {
        DispatchQueue.main.async {
            do {
                let game = NSEntityDescription.insertNewObject(forEntityName: "Game", into: self.context) as! Game
                game.gameId = gbGame.gameId
                game.name = gbGame.name
                game.releaseDate = gbGame.releaseDate as NSDate?
                game.platform = gbGame.platformKey
                game.inCollection = true
                game.inWishList = false
                game.detailUrl = gbGame.detailUrl
                game.coverArt = gbGame.coverArtData as NSData?
                
                try self.context.save()
            } catch {
                print(error)
            }
        }
    }
    
    private func saveToWishList(gbGame: GBGame) {
        DispatchQueue.main.async {
            do {
                let game = NSEntityDescription.insertNewObject(forEntityName: "Game", into: self.context) as! Game
                game.gameId = gbGame.gameId
                game.name = gbGame.name
                game.releaseDate = gbGame.releaseDate as NSDate?
                game.platform = gbGame.platformKey
                game.inCollection = false
                game.inWishList = true
                game.detailUrl = gbGame.detailUrl
                game.coverArt = gbGame.coverArtData as NSData?
                
                try self.context.save()
            } catch {
                print(error)
            }
        }
    }
    
    // Set the activity indicator into the main view
    private func setLoadingScreen() {
        self.platformMap = [String:[GBGame]]()
        self.tableView.reloadData()
        self.titleSearch.isEnabled = false
        self.searchButton.isEnabled = false
        self.tableView.backgroundView = loadingLabel
    }
    
    // Remove the activity indicator from the main view
    private func removeLoadingScreen() {
        self.titleSearch.isEnabled = true
        self.searchButton.isEnabled = true
        self.tableView.backgroundView = nil
    }
}

