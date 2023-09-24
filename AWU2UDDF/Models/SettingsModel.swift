//
//  SettingsModel.swift
//  AWU2UDDF
//
//  Created by James Cash on 2023-08-02.
//

import Foundation
import SwiftUI

fileprivate let DISPLAY_UNITS_KEY = "displayUnitsKey"
fileprivate let SHORT_DIVE_DURATION_KEY = "shortDiveDurationKey"
fileprivate let DEEP_DIVE_DEPTH_KEY = "deepDiveDepthKey"
fileprivate let EXPORT_WATER_TEMP_KEY = "exportWaterTempKey"

enum DisplayUnits {
    case imperial
    case metric
    case canadian
    
    fileprivate static func fromDefaults() -> DisplayUnits {
        switch UserDefaults.standard.string(forKey: DISPLAY_UNITS_KEY) ?? "🇺🇸" {
        case "🇺🇸": return .imperial
        case "🌎": return .metric
        case "🇨🇦": return .canadian
        default: return .imperial
        }
    }
    
    private func toString() -> String {
        switch self {
        case .imperial: return "🇺🇸"
        case .metric: return "🌎"
        case .canadian: return "🇨🇦"
        }
    }
    
    fileprivate func save() {
        UserDefaults.standard.set(self.toString(), forKey: DISPLAY_UNITS_KEY)
    }
    
    func dateFormat() -> String {
        switch self {
        case .imperial: return "MM/dd/yy h:mm a"
        case .metric: return "yyyy-MM-dd HH:mm"
        case .canadian: return "dd/MM/yy h:mm a"
        }
    }
    
    func depthUnit() -> String {
        switch self {
        case .imperial, .canadian:
            return "ft"
        case .metric:
            return "m"
        }
    }
    
    func depthUnitLong() -> String {
        switch self {
        case .imperial, .canadian:
            return "feet"
        case .metric:
            return "metres"
        }
    }
    
    func tempUnit() -> String {
        switch self {
        case .imperial:
            return "°F"
        case .metric, .canadian:
            return "°C"
        }
    }
    
    func tempUnitLong() -> String {
        switch self {
        case .imperial:
            return "Fahrenheit"
        case .metric, .canadian:
            return "Celsius"
        }
    }
}

class Settings: ObservableObject {
    @Published var displayUnits: DisplayUnits {
        didSet {
            displayUnits.save()
            dateFormatter.dateFormat = displayUnits.dateFormat()
        }
    }
    
    var dateFormatter: DateFormatter
    
    @AppStorage(SHORT_DIVE_DURATION_KEY) var shortDiveDurationMinutes: Int = 5
    
    @AppStorage(DEEP_DIVE_DEPTH_KEY) var deepDiveDepthMetres: Double = 20
    
    @AppStorage(EXPORT_WATER_TEMP_KEY) var exportTemps: Bool = true
    init() {
        displayUnits = DisplayUnits.fromDefaults()
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = displayUnits.dateFormat()
    }
    
    func distanceToMetres(_ distance: Double) -> Double {
        switch displayUnits {
        case .imperial, .canadian:
            return distance / 3.28
        case .metric:
            return distance
        }
    }
    
    func metresToDistance(_ metres: Double) -> Double {
        switch displayUnits {
        case .imperial, .canadian:
            return metres * 3.28
        case .metric:
            return metres
        }
    }
    
    func celsiusToTemp(_ celsius: Double) -> Double {
        switch displayUnits {
        case .imperial:
            return (celsius*(9.0/5.0)) + 32
        case .metric, .canadian:
            return celsius
        }
    }
    
    func displayDepth(metres: Double, shortUnits: Bool = true) -> String {
        let nf = NumberFormatter()
        nf.allowsFloats = true
        nf.maximumFractionDigits = 1
        return "\(nf.string(for: metresToDistance(metres))!) \(shortUnits ? displayUnits.depthUnit() : displayUnits.depthUnitLong())"
    }
    
    func displayTemp(celsius: Double, shortUnits: Bool = true) -> String {
        let nf = NumberFormatter()
        nf.allowsFloats = true
        nf.maximumFractionDigits = 0
        return "\(nf.string(for: celsiusToTemp(celsius))!) \(shortUnits ? displayUnits.tempUnit() : displayUnits.tempUnitLong())"
    }
}
