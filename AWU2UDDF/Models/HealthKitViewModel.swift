//
//  HealthKitViewModel.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import Foundation
import HealthKit

class HealthKitViewModel: ObservableObject {
    
    private var healthStore = HKHealthStore()
    private var healthKitManager = HealthKitManager()
    @Published var shownDivesList: [Dive] = []
    @Published var allDivesList: [Dive] = []
    @Published var onlyDeeperThan10mList: [Dive] = []
    @Published var onlyShallowList: [Dive] = []
    @Published var temps: [Temp_Sample] = []
    @Published var isAuthorized = false
    @Published var queriesCompleted = false
    
    let debug: Bool = false
    
    init() {
        temps = .init()
        changeAuthorizationStatus()
    }
    
    func healthRequest() {
        healthKitManager.setUpHealthRequest(healthStore: healthStore) {
            self.changeAuthorizationStatus()
            self.readDiveData()
        }
    }
    
    func changeAuthorizationStatus() {
        guard let depthQtyType = HKObjectType.quantityType(forIdentifier: .underwaterDepth) else { return }
        let status = self.healthStore.authorizationStatus(for: depthQtyType)
        
        print("Status is:", status)
        
        switch status {
        case .notDetermined:
            isAuthorized = false
        case .sharingDenied:
            isAuthorized = false
        case .sharingAuthorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        @unknown default:
            isAuthorized = false
        }
    }
    
    func readDiveData() {
        print ("Reading Dive Data")
        var diveCount: Int = 0
        var tempCount: Int = 0
        
        let healthKitQueriesGroup = DispatchGroup()
        
        healthKitQueriesGroup.enter()
        healthKitManager.readUnderwaterDepths(forToday: Date(), healthStore: healthStore) {
            diveQuery in
            if diveQuery.count > diveCount {
                let sortedDives = diveQuery.sorted(by: { $0.startTime.compare($1.startTime) == .orderedDescending })
                DispatchQueue.main.async {
                    self.allDivesList = sortedDives
                }
                diveCount = diveQuery.count
            } else {
                if self.debug {
                    let sampleDives = self.previewData()
                    let sortedDives = sampleDives.sorted(by: { $0.startTime.compare($1.startTime) == .orderedDescending })
                    
                    DispatchQueue.main.async {
                        self.allDivesList = sortedDives
                        diveCount = self.allDivesList.count
                    }
                }
            }
            print("Completed dives query with ", diveCount, " samples.")
            healthKitQueriesGroup.leave()
        }
        
        healthKitQueriesGroup.enter()
        healthKitManager.readWaterTemps(forToday: Date(), healthStore: healthStore) {
            tempSamples in
            print("Querying for temperatures...")
            
            DispatchQueue.main.async {
                self.temps = tempSamples
                tempCount = tempSamples.count
                print("Completed temperature query with ", tempCount, " samples.")
            }
            healthKitQueriesGroup.leave()
        }
        
        healthKitQueriesGroup.notify(queue: .main) {
            self.finishAssemblingData()
        }
    }
    
    func finishAssemblingData() {
        print("Finishing assembling dive profiles with ", allDivesList.count, " dives and ", temps.count, " temperature samples...")
        
        for dive in allDivesList {
            for depthSample in dive.profile {
                let sampleTemperature = searchTemps(date: depthSample.start, temps: temps)
                if (sampleTemperature > 0) { // Temperatures are in Kelvin, so anything under zero is an error.
                    depthSample.temperature = sampleTemperature
                    
                    if (sampleTemperature < dive.minTemp) {
                        dive.minTemp = sampleTemperature
                    }
                    if (sampleTemperature > dive.maxTemp) {
                        dive.maxTemp = sampleTemperature
                    }
                }
            }
            // Classify dives into deep ( >10m) and shallow
            if dive.MaxDepth() > 9.9 {
                onlyDeeperThan10mList.append(dive)
            } else {
                onlyShallowList.append(dive)
            }
        }
        if !onlyDeeperThan10mList.isEmpty {
            shownDivesList = onlyDeeperThan10mList
        } else {
            shownDivesList = onlyShallowList
        }
        print("Finished assembling dive profiles.")
        
        
        queriesCompleted = true
    }

    
    
    // Search for a temperature sample that has a particular start to the time interval
    func searchTemps(date: Date, temps: [Temp_Sample]) -> Double {
        for tempSample in temps {
            if tempSample.start == date {
                // matched a sample start time so return temperature
                return tempSample.temp
            }
        }
        
        // return -999.9 if no matching sample is found
        return -999.9
    }
    
    
    func previewData() -> [Dive] {
        var sampleDive: Dive
        var sampleDives: [Dive] = []
        
        let dateString = "10/28/2000 14:38"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy HH:mm"
        guard let startDate: Date = dateFormatter.date(from: dateString) else {
            print ("Error making date")
            return([])
        }
 
        var curDate = startDate

        for _ in stride (from: 1, to: 40, by: 1) {
            
            sampleDive = .init(startTime: curDate)

            for i in stride(from: 1, to: 80, by: 1) {
                let depth: Double = Double(i)
                let endDate = curDate.addingTimeInterval(10)
                
                let sample: Depth_Sample = .init(start: curDate, end: endDate, depth: depth)
                sampleDive.profile.append(sample)
                curDate = endDate
            }
            for i in stride(from: 1, to: 80, by: 1) {
                let depth: Double = Double(80-i)
                let endDate = curDate.addingTimeInterval(10)
                
                let sample: Depth_Sample = .init(start: curDate, end: endDate, depth: depth)
                sampleDive.profile.append(sample)
                curDate = endDate
            }

            sampleDives.append(sampleDive)
            curDate = curDate.addingTimeInterval(120)

        }
        print ("Sample Dive Count: ", sampleDives.count)
        return sampleDives
    }
}
