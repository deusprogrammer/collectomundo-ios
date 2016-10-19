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
    @IBOutlet weak var gameImage: UIImageView!
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
        return []
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
        if (game.coverArt != nil) {
            cell.gameImage.image = UIImage(data: game.coverArt as! Data)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name
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
        return []
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
        
        if (game.coverArt != nil) {
            cell.gameImage.image = UIImage(data: game.coverArt as! Data)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name
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
        "3DO", "JAG",
        "PS1", "PS2", "PS3", "PS4", "PSP", "VITA"
    ]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var titleSearch: UITextField!
    
    var context = DataLayerService.managedObjectContext
    
    var results = [GBGame]()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = self.results[indexPath.row]

        let app = UIApplication.shared
        if (result.detailUrl != nil) {
            app.openURL(URL(string: result.detailUrl)!)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let result = self.results[indexPath.row]
        
        let collection = UITableViewRowAction(style: .normal, title: "Collect") { action, index in
            DispatchQueue.main.async {
                self.saveToCollection(gbGame: result)
                tableView.isEditing = false
            }
        }
        collection.backgroundColor = UIColor(red: 0, green: 0.898, blue: 0.7922, alpha: 1.0)
        
        let wishList = UITableViewRowAction(style: .normal, title: "Wishlist") { action, index in
            self.saveToWishList(gbGame: result)
            tableView.isEditing = false
        }
        wishList.backgroundColor = UIColor(red: 0, green: 1, blue: 0.7333, alpha: 1.0)
        
        return [collection, wishList]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTableCell") as! GameSearchTableCell
        
        let result = self.results[indexPath.row]
        let index = indexPath.row
        
        cell.gameImage.contentMode = UIViewContentMode.scaleAspectFit
        cell.titleLabel.text = result.name
        cell.platformLabel.text = result.platformKey
        cell.releaseDateLabel.text = "N/A"
        
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
                        self.results[index].coverArtData = data
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

    @IBAction func searchPressed(_ sender: AnyObject) {
        setLoadingScreen()
        sdk.getGamesByName(
            name: titleSearch.text!,
            platformFilter: GameSearchViewController.consoleFilter,
            completionHandler: {(games: [GBGame], pages: Int) -> Void in
                self.results = games
                self.pages = pages
                
                DispatchQueue.main.async {
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

