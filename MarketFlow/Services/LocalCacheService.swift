//
//  LocalCacheService.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

class LocalCacheService {
    
    static let shared = LocalCacheService()
    private let fileManager = FileManager.default
    private let cacheFileName = "exchanges_cache.json"
    
    private init() {}
    
    private var cacheFileURL: URL? {
        // Securely point to the App's Documents Directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(cacheFileName)
    }
    
    func saveExchanges(_ exchanges: [Exchange]) {
        guard let url = cacheFileURL else { return }
        
        do {
            let data = try JSONEncoder().encode(exchanges)
            try data.write(to: url, options: Data.WritingOptions.atomic)
        } catch {
            print("Failed to save exchanges to local cache: \(error.localizedDescription)")
        }
    }
    
    func loadExchanges() -> [Exchange]? {
        guard let url = cacheFileURL, fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let exchanges = try JSONDecoder().decode([Exchange].self, from: data)
            return exchanges
        } catch {
            print("Failed to load exchanges from local cache: \(error.localizedDescription)")
            return nil
        }
    }
    
    func clearCache() {
        guard let url = cacheFileURL else { return }
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        } catch {
            print("Failed to clear local cache: \(error.localizedDescription)")
        }
    }
}
