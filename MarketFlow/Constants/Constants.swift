//
//  Constants.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

struct Constants {
    struct API {
        static let baseURL = "https://pro-api.coinmarketcap.com"
        static let apiKey = "b4d525845fff44deaf556abcfe123f77"
    }
}

// MARK: - Dependency Injection Infrastructure

/// Centralized thread-safe IoC Container to manage app dependencies
final class DIContainer {
    
    // Shared Singleton instance
    static let shared = DIContainer()
    
    // Dictionary tracking memory registries
    private var dependencies: [String: Any] = [:]
    // Concurrency Lock
    private let queue = DispatchQueue(label: "com.marketflow.dicontainer", attributes: .concurrent)
    
    private init() {} // Prevent direct instantiation
    
    /// Register a component
    func register<T>(type: T.Type, component: Any) {
        queue.sync(flags: .barrier) {
            let key = String(describing: type)
            self.dependencies[key] = component
        }
    }
    
    /// Resolve a formally registered component
    func resolve<T>(type: T.Type) -> T {
        var component: T?
        
        queue.sync {
            let key = String(describing: type)
            component = self.dependencies[key] as? T
        }
        
        guard let resolvedComponent = component else {
            let keys = queue.sync { self.dependencies.keys.joined(separator: ", ") }
            fatalError("Dependency '\(T.self)' not found! Available keys: [\(keys)]. Object in dictionary for this key: \(String(describing: queue.sync { self.dependencies[String(describing: type)] }))")
        }
        
        return resolvedComponent
    }
}

/// Swift 5.1 Property Wrapper enabling lazy magic parameter injection.
/// Usage: `@Inject var service: MarketDataServiceProtocol`
@propertyWrapper
class Inject<T> {
    
    private var dependency: T?
    
    var wrappedValue: T {
        if let resolvedDependency = dependency {
            return resolvedDependency
        }
        let resolvedDependency = DIContainer.shared.resolve(type: T.self)
        self.dependency = resolvedDependency
        return resolvedDependency
    }
    
    init() {}
}
