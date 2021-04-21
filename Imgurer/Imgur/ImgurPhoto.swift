//
//  ImgurPhoto.swift
//  Imgurer
//
//  Created by Deyvid Lopes on 21/04/21.
//

import UIKit

class ImgurPhoto: Equatable {
    var photo: UIImage?
    let id: String
    let link: String
    
    
    init (id: String, link: String) {
        self.id = id
        self.link = link
    }
    
    func imgurImageURL() -> URL? {
        return URL(string: self.link)
    }
    
    enum Error: Swift.Error {
        case invalidURL
        case noData
    }
    
    func loadImage(_ completion: @escaping (Result<ImgurPhoto, Swift.Error>) -> Void) {
        guard let loadURL = imgurImageURL() else {
            DispatchQueue.main.async {
                completion(.failure(Error.invalidURL))
            }
            return
        }
        
        let loadRequest = URLRequest(url: loadURL)
        
        URLSession.shared.dataTask(with: loadRequest) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(Error.noData))
                    return
                }
                
                let returnedImage = UIImage(data: data)
                self.photo = returnedImage
                completion(.success(self))
            }
        }
        .resume()
    }
    
    static func == (lhs: ImgurPhoto, rhs: ImgurPhoto) -> Bool {
        return lhs.id == rhs.id
    }
}


