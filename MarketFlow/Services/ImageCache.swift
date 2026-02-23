//
//  ImageCache.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import UIKit

class ImageCache {
    
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Optional: configure cache limits
        // cache.countLimit = 100
        // cache.totalCostLimit = 1024 * 1024 * 50 // 50 MB
    }
    
    func loadImage(from url: URL) async throws -> UIImage? {
        // 1. Check if the image is already cached
        let cacheKey = NSString(string: url.absoluteString)
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // 2. Download from network
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // 3. Store in cache and return
        cache.setObject(image, forKey: cacheKey)
        return image
    }
}
