//
//  TempModel.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/29/22.
//

import Foundation

class Temp_Sample {
    var start : Date
    var end : Date
    var temp: Double
    
    init (start: Date, end: Date, temp: Double) {
        self.start = start
        self.end = end
        self.temp = temp
    }
}
