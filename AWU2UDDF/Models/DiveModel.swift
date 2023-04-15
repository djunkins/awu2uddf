//
//  DiveModel.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import Foundation
import HealthKit

class Depth_Sample {
    var start : Date
    var end : Date
    var depth: Double
    var temperature: Double = -1
    
    init (start: Date, end: Date, depth: Double) {
        self.start = start
        self.end = end
        self.depth = depth
    }
}

class Dive: Identifiable, Hashable, Equatable {
    var startTime : Date
    var profile: [Depth_Sample] = []
    var uddfFile: UDDF
    var minTemp: Double = 999.9
    var maxTemp: Double = -999.9
    
    init (startTime: Date) {
        self.startTime = startTime
        uddfFile = UDDF()
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(startTime)
    }
    
    static func ==(lhs: Dive, rhs: Dive) -> Bool {
        return lhs.startTime == rhs.startTime
    }
    
    func setTemps(temps: [Temp_Sample]) {
        for tSample in temps {
            if (minTemp > tSample.temp) {
                minTemp = tSample.temp
            }
            if (maxTemp < tSample.temp) {
                maxTemp = tSample.temp
            }
        }
    }
    
    func MaxDepth () -> Double {
        var maxDepth = 0.0
        
        for sample in self.profile {
            if sample.depth > maxDepth {
                maxDepth = sample.depth
            }
        }
        return maxDepth
        
    }
    
    func AvgDepth () -> Double {
        if (self.profile.count < 1) {
            return 0 // Avoid dividing by 0
        }
        
        var depthSum = 0.0
        
        for sample in self.profile {
            depthSum += sample.depth
        }
        return depthSum / Double(self.profile.count)
    }
    
    func Duration () -> Double {
        guard let endTime = profile.last?.end else {
            return 0.0
        }
        
        let duration = endTime.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
        
        return duration
    }
    
    func MinTemp () -> Double {
        return minTemp
    }
    
    func MaxTemp () -> Double {
        return maxTemp
    }
       
    func buildUDDF (temps: [Temp_Sample]) -> String {
        return uddfFile.buildUDDFString(startTime: self.startTime, profile: self.profile, temps: temps)
    }
    
    func defaultUDDFFilename () -> String {
        let filename = "UDDF_" + self.startTime.getFormattedDate(format: "yyyyMMdd_HHmm")
        return filename
    }
    
}
