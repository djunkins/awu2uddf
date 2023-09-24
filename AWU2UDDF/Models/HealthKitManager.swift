//
//  HealthKitManager.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import Foundation
import HealthKit

class HealthKitManager {
    
    func setUpHealthRequest(healthStore: HKHealthStore, readDepths: @escaping () -> Void) {
        
        if HKHealthStore.isHealthDataAvailable(), let underwaterDepth = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.underwaterDepth) {

            guard let waterTemp = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.waterTemperature) else {
                print ("Water Temp Error")
                return
            }
        
            let healthKitTypesToRead: Set<HKObjectType> = [
                underwaterDepth,
                waterTemp
            ]
            
            healthStore.requestAuthorization(toShare: [], read: healthKitTypesToRead ) { success, error in
                if success {
                    readDepths()
                } else if error != nil {
                    print(error ?? "Error")
                }
            }
        }
    }
    
    func readUnderwaterDepths(forToday: Date, healthStore: HKHealthStore, completion: @escaping ([Dive]) -> Void) {
        
        var diveList: [Dive] = []
        var lastDiveEnd: Date? = nil
        var thisDiveStart: Date?
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mmZ"
        
        guard let underwaterDepthType = HKQuantityType.quantityType(forIdentifier: .underwaterDepth) else { return }

        let query = HKQuantitySeriesSampleQuery(quantityType: underwaterDepthType, predicate: nil) {
            query, result, dates, samples, done, error  in

            guard let result = result else {
                completion([])
                return
            }

            if let diveDates = dates {
                var diffSeconds: Double
                if let lastDive = lastDiveEnd {
                    diffSeconds = diveDates.start.timeIntervalSinceReferenceDate - lastDive.timeIntervalSinceReferenceDate
                } else {
                    diffSeconds = 99
                }
                if diffSeconds > 60 {
                    if (diveList.isEmpty == false) {
                        print ("Dive Summary")
                        print ("  Start Time: ", dateFormatter.string(from: thisDiveStart!))
                        print ("  Duration: ", Int((diveList.last!.duration()+59.0)/60.0) as Any, "minutes")
                        print ("  Max Depth: ", Int(diveList.last!.maxDepth()) as Any, "meters")
                    }
                    thisDiveStart = diveDates.start
                    diveList.append(Dive(startTime: thisDiveStart!))
                }
                lastDiveEnd = diveDates.end
                let currentDive = diveList.last
                
                currentDive?.profile.append(DepthSample(start: diveDates.start, end: diveDates.end, depth: (result.doubleValue(for: HKUnit.meter()))))
            }

            completion(diveList)
        
        }
        
        healthStore.execute(query)
        
    }

    func readWaterTemps(forToday: Date, healthStore: HKHealthStore, completion: @escaping ([TemperatureSample]) -> Void) {
        
        var temps: [TemperatureSample] = []

        guard let waterTempType = HKQuantityType.quantityType(forIdentifier: .waterTemperature) else { return }
        
        let query = HKQuantitySeriesSampleQuery(quantityType: waterTempType, predicate: nil) {
            query, result, dates, samples, done, error  in

            guard let result = result else {
                print ("Nil Result to temperature query")
                completion([])
                return
            }
 
            if let sampleDate = dates {
                temps.append(TemperatureSample(start: sampleDate.start, end: sampleDate.end ,temp: result.doubleValue(for: HKUnit.degreeCelsius())))
            }
            completion(temps)
        }
        
        healthStore.execute(query)
        
    }
}
