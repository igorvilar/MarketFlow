//
//  FormatterUtils.swift
//  MarketFlow
//
//  Created by Igor Vilar on 22/02/26.
//

import Foundation

extension String {
    /// Parses an ISO8601 string attempting fractional seconds first, then gracefully falling back.
    func parseISODate() -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: self) {
            return date
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: self)
    }
}
