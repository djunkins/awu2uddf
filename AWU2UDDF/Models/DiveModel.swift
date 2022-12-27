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
    
    func MaxDepth () -> Double {
        var maxDepth = 0.0
        
        for sample in self.profile {
            if sample.depth > maxDepth {
                maxDepth = sample.depth
            }
        }
        return maxDepth
        
    }
    
    func AvgDepth () {
        
    }
    
    func Duration () -> Double {
        guard let endTime = profile.last?.end else {
            return 0.0
        }
        
        let duration = endTime.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
        
        return duration
    }
       
    func buildUDDF () -> String {
        return uddfFile.buildUDDFString(startTime: self.startTime, profile: self.profile)
    }
    
    func defaultUDDFFilename () -> String {
        let filename = "UDDF_" + self.startTime.getFormattedDate(format: "yyyyMMdd_HHmm")
        return filename
    }
    
}
