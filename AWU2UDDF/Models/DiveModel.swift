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
    
    func maxDepth() -> Double {
        return profile.max(by: { s1, s2 in s1.depth <= s2.depth })?.depth ?? 0
    }
    
    func avgDepth() -> Double {
        guard profile.count > 0 else { return 0 }
        return profile.reduce(0, { total, sample in total + sample.depth }) / Double(profile.count)
    }
    
    func duration () -> Double {
        guard let endTime = profile.last?.end else {
            return 0.0
        }
        
        let duration = endTime.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
        
        return duration
    }
       
    func buildUDDF (temps: [Temp_Sample]) -> String {
        return uddfFile.buildUDDFString(startTime: self.startTime, profile: self.profile, temps: temps)
    }
    
    func defaultUDDFFilename () -> String {
        let filename = "UDDF_" + self.startTime.getFormattedDate(format: "yyyyMMdd_HHmm")
        return filename
    }
    
}
