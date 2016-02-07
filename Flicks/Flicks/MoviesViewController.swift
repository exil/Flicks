//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Max Pappas on 2/3/16.
//  Copyright © 2016 Max Pappas. All rights reserved.
//

import UIKit
import AFNetworking
import EZLoadingActivity

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchResultsUpdating {
    
    @IBOutlet var errorView: UIView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var viewControl: UISegmentedControl!
    //@IBOutlet var searchPlaceholder: UIView!

    var movies: [NSDictionary]?
    var endpoint: String!
    var filteredMovies: [NSDictionary]?
    var searchController: UISearchController!
    
    enum Mode: Int {
        case List = 0, Grid
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.hidden = true
        
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.sizeToFit()
        
        //searchPlaceholder.addSubview(searchController.searchBar)
        tableView.tableHeaderView = searchController.searchBar
        
        searchController.searchBar.barTintColor = UIColor(red: 0.73, green: 0, blue: 0, alpha: 1.0)
        searchController.searchBar.tintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.barTintColor = UIColor(red: 0.73, green: 0, blue: 0, alpha: 1.0)
            navigationBar.tintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            navigationBar.titleTextAttributes = [
                NSFontAttributeName : UIFont.boldSystemFontOfSize(22),
                NSForegroundColorAttributeName : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            ]
        }
        
        definesPresentationContext = true
        
        getMovies()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getMovies(callback: (() -> Void)? = nil) {
        // Do any additional setup after loading the view.
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        EZLoadingActivity.show("Loading...", disableUI: true)
        self.errorView.hidden = true
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                EZLoadingActivity.hide()
                
                if let data = dataOrNil {
                    self.searchController.searchBar.hidden = false
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                        self.movies = responseDictionary["results"] as? [NSDictionary]
                        self.filteredMovies = self.movies
                        self.tableView.reloadData()
                        self.collectionView.reloadData()
                    }
                } else {
                    self.errorView.hidden = false
                }
                
                if let callback = callback {
                    callback()
                }
        });
        task.resume()
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        getMovies({
            refreshControl.endRefreshing()
        })
    }
    
    @IBAction func viewTypeChanged(sender: AnyObject) {
        let viewType = viewControl.selectedSegmentIndex
        
        
        if viewType == 0 {
            tableView.hidden = false
            collectionView.hidden = true
        } else if viewType == 1 {
            tableView.hidden = true
            collectionView.hidden = false
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filteredMovies = filteredMovies {
            return filteredMovies.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        let movie = filteredMovies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        let baseUrl = "http://image.tmdb.org/t/p/"
        let lowResPath = "w45/"
        let highResPath = "original/"
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        cell.overviewLabel.sizeToFit()
        
        cell.selectionStyle = .None
        
        if let posterPath = movie["poster_path"] as? String {
            let posterLowResRequest = NSURLRequest(URL: NSURL(string: baseUrl + lowResPath + posterPath)!)
            let posterHighResRequest = NSURLRequest(URL: NSURL(string: baseUrl + highResPath + posterPath)!)
            
            cell.posterView.setImageWithURLRequest(
                posterLowResRequest,
                placeholderImage: nil,
                success: { (posterLowResRequest, posterLowResResponse, posterLowResImage) -> Void in
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = posterLowResImage
                    
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                        }, completion: { (success) -> Void in
                            
                            cell.posterView.setImageWithURLRequest(posterHighResRequest,
                                placeholderImage: posterLowResImage,
                                success: { (posterHighResRequest, posterHighResResponse, posterHighResImage) -> Void in
                                    cell.posterView.image = posterHighResImage
                                },
                                failure: { (request, response, error) -> Void in
                                }
                            )
                        })
                },
                failure: { (request, response, error) -> Void in
                    cell.posterView.setImageWithURLRequest(posterHighResRequest,
                        placeholderImage: nil,
                        success: { (posterHighResRequest, posterHighResResponse, posterHighResImage) -> Void in
                            cell.posterView.image = posterHighResImage
                        },
                        failure: { (request, response, error) -> Void in
                        }
                    )
                }
            )
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let filteredMovies = filteredMovies {
            return filteredMovies.count
        }
        
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("gridViewCell", forIndexPath: indexPath) as! MovieGridViewCell
        
        let movie = filteredMovies![indexPath.row]
        let baseUrl = "http://image.tmdb.org/t/p/"
        let lowResPath = "w45/"
        let highResPath = "original/"
        
        if let posterPath = movie["poster_path"] as? String {
            let posterLowResRequest = NSURLRequest(URL: NSURL(string: baseUrl + lowResPath + posterPath)!)
            let posterHighResRequest = NSURLRequest(URL: NSURL(string: baseUrl + highResPath + posterPath)!)
            
            cell.posterView.setImageWithURLRequest(
                posterLowResRequest,
                placeholderImage: nil,
                success: { (posterLowResRequest, posterLowResResponse, posterLowResImage) -> Void in
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = posterLowResImage
                    
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        cell.posterView.alpha = 1.0
                        }, completion: { (success) -> Void in
                            
                            cell.posterView.setImageWithURLRequest(posterHighResRequest,
                                placeholderImage: posterLowResImage,
                                success: { (posterHighResRequest, posterHighResResponse, posterHighResImage) -> Void in
                                    cell.posterView.image = posterHighResImage
                                },
                                failure: { (request, response, error) -> Void in
                                }
                            )
                    })
                },
                failure: { (request, response, error) -> Void in
                    cell.posterView.setImageWithURLRequest(posterHighResRequest,
                        placeholderImage: nil,
                        success: { (posterHighResRequest, posterHighResResponse, posterHighResImage) -> Void in
                            cell.posterView.image = posterHighResImage
                        },
                        failure: { (request, response, error) -> Void in
                        }
                    )
                }
            )
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)!.backgroundColor = UIColor(red: 0.73, green: 0, blue: 0, alpha: 0.5)
    }
    
    func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)!.backgroundColor = .None
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filteredMovies = searchText.isEmpty ? movies : movies!.filter({
                if let title = $0["title"] as? String {
                    return title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
                }
                
                return false
            })
            
            tableView.reloadData()
            //collectionView.reloadData()
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender
        var indexPath: NSIndexPath?
        
        if viewControl.selectedSegmentIndex == Mode.List.rawValue {
            indexPath = tableView.indexPathForCell(cell as! UITableViewCell)
        } else {
            indexPath = collectionView.indexPathForCell(cell as! UICollectionViewCell)
        }
        let movie = filteredMovies![indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        
        detailViewController.movie = movie
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
