//
//  ViewController.swift
//  Imgurer
//
//  Created by Deyvid Lopes on 21/04/21.
//

import UIKit

final class ImgurerViewController: UICollectionViewController {
    // MARK: - Properties
    private let reuseIdentifier = "imageCell"
    private let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    private var searches: [SearchResults] = []
    private var photos: [ImgurPhoto] = []
    private let imgur = Imgur()
    private let itemsPerRow: CGFloat = 4
    private var page: Int = 1
    private var term: String = ""
    
    private var isLoading = false
    private var loadingView: LoadingReusableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loadingReusableNib = UINib(nibName: "LoadingReusableView", bundle: nil)
        collectionView.register(loadingReusableNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "loadingresuableview")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingView?.activityIndicator.stopAnimating()
    }
    
    func loadData(for text: String, completion: @escaping () -> ()) {
        self.imgur.searchImgur(for: text, page: self.page) { (searchResults) in
            DispatchQueue.main.async {
                //                activityIndicator.removeFromSuperview()
                
                switch searchResults {
                case .failure(let error):
                    let alert = UIAlertController(title: "Error", message: "Ops! Something went wrong. Check if out device is connected to internet.", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    self.present(alert, animated: true)
                    print("Error searching \(error)")
                case .success(let results) :
                    print("Found \(results.count) matching")
                    self.photos.append(contentsOf: results)
                    self.collectionView?.reloadData()
                }
                completion()
            }
        }
    }
}

// MARK: - Private
private extension ImgurerViewController {
    func photo(for indexPath: IndexPath) -> ImgurPhoto {
        return photos[indexPath.row]
    }
}

// MARK: - Text Field Delegate
extension ImgurerViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard
            let text = textField.text,
            !text.isEmpty
        else {return true}
        
        self.photos = []
        self.collectionView?.reloadData()
        self.page = 1
        self.term = text
        
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        
        self.loadData(for: text) {
            activityIndicator.removeFromSuperview()
        }
        
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UICollectionViewDataSource
extension ImgurerViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        return photos.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImgurCollectionViewCell
        
        let imgurPhoto = photo(for: indexPath)
        cell.backgroundColor = .white
        cell.imageView.image = imgurPhoto.photo
        cell.imageView.clipsToBounds = true
        cell.imageView.frame = cell.bounds
        cell.imageView.contentMode = .scaleAspectFit
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if self.isLoading || self.photos.count == 0 {
            return CGSize.zero
        } else {
            return CGSize(width: collectionView.bounds.size.width, height: 55)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let aFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "loadingresuableview", for: indexPath) as! LoadingReusableView
            loadingView = aFooterView
            loadingView?.backgroundColor = UIColor.clear
            return aFooterView
        }
        return UICollectionReusableView()
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter && self.photos.count > 0 {
            self.loadingView?.activityIndicator.startAnimating()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            self.loadingView?.activityIndicator.stopAnimating()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == self.photos.count - 4 && !self.isLoading {
            self.page += 1
            loadMoreData()
        }
    }
    
    func loadMoreData() {
        if !self.isLoading {
            self.isLoading = true
            DispatchQueue.global().async {
                self.loadData(for: self.term) {
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.isLoading = false
                    }
                }
                
            }
        }
    }
}

// MARK: - Collection View Flow Layout Delegate
extension ImgurerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        
        let paddingSpace = insets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return insets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return insets.left
    }
    
    
}
