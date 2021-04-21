//
//  Imgur.swift
//  Imgurer
//
//  Created by Deyvid Lopes on 21/04/21.
//

import UIKit

let clientId = "1ceddedc03a5d71"

class Imgur {
    enum Error: Swift.Error {
        case unknownAPIResponse
        case generic
    }
    
    func searchImgur(for searchTerm: String, page: Int, completion: @escaping (Result<[ImgurPhoto], Swift.Error>) -> Void) {
        guard let searchURL = searchURL(for: searchTerm, page: page) else {
            completion(.failure(Error.unknownAPIResponse))
            return
        }
        
        var request = URLRequest(url: searchURL)
        request.httpMethod = "GET"
        request.addValue("Client-ID \(clientId)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard
                (response as? HTTPURLResponse) != nil,
                let data = data
            else {
                completion(.failure(Error.unknownAPIResponse))
                return
            }
            
            do {
                guard
                    let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
                    let stat = resultsDictionary["status"] as? Int
                else {
                    completion(.failure(Error.unknownAPIResponse))
                    return
                }
                
                switch stat {
                case 200:
                    print("Results processed OK")
                case 401:
                    completion(.failure(Error.generic))
                    return
                default:
                    completion(.failure(Error.unknownAPIResponse))
                    return
                }
                
                guard
                    let galleries = resultsDictionary["data"] as? [[String: AnyObject]]
                else {
                    completion(.failure(Error.unknownAPIResponse))
                    return
                }
                var imagesReceived: [[String: AnyObject]] = []
                
                for gallery in galleries {
                    if gallery.keys.contains("images") {
                        guard let images = gallery["images"] as? [[String: AnyObject]] else { print ("error parsing image"); return }
                        for image in images {
                            if image["type"] as! String == "image/jpeg" && (image["size"] as! Int) <= 100000 {
                                imagesReceived.append(image)
                            }
                            
                        }
                    }
                    
                }
                
                let photos = self.getPhotos(photoData: imagesReceived)
                completion(.success(photos))
            } catch {
                
                completion(.failure(error))
                return
            }
        }
        .resume()
    }
    
    private func getPhotos(photoData: [[String: AnyObject]]) -> [ImgurPhoto] {
        let photos: [ImgurPhoto] = photoData.compactMap { photoObject in
            guard
                let id = photoObject["id"] as? String,
                let link = photoObject["link"] as? String
            else {
                print("error parsing photoData")
                return nil
            }
            
            let imgurPhoto = ImgurPhoto(id: id, link: link)
            
            guard
                let url = imgurPhoto.imgurImageURL(),
                let imageData = try? Data(contentsOf: url as URL)
            else {
                return nil
            }
            
            if let image = UIImage(data: imageData) {
                let resizedImage = image.jpeg(.lowest)
                imgurPhoto.photo = UIImage(data: resizedImage!)
                return imgurPhoto
            } else {
                return nil
            }
        }
        return photos
    }
    
    private func searchURL(for searchTerm: String, page: Int) -> URL? {
        guard let escapedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics) else {
            return nil
        }
        
        let URLString = "https://api.imgur.com/3/gallery/search/\(page)/?q=\(escapedTerm)"
        return URL(string: URLString)
    }
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}
