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
    @Published var diveList: [Dive] = []
    @Published var temps: [TemperatureSample] = []
    @Published var isAuthorized = false
    
    let debug: Bool = false
    
    init() {
        temps = .init()
        changeAuthorizationStatus()
    }
    
    func healthRequest() {
        healthKitManager.setUpHealthRequest(healthStore: healthStore) {
            self.changeAuthorizationStatus()
            self.readDiveDepths()
        }
    }
    
    func changeAuthorizationStatus() {
        guard let depthQtyType = HKObjectType.quantityType(forIdentifier: .underwaterDepth) else { return }
        let status = self.healthStore.authorizationStatus(for: depthQtyType)
        
        print("Status is:", status)
        
        DispatchQueue.main.async { [self] in
            // Because the app only asks for read permission, not to write ("share") anything, status will either be `notDetermined` or `sharingDenied`
            isAuthorized = status != .notDetermined
        }
    }
    
    func readDiveDepths() {
        print ("Reading Dive Depths")
        var diveCount: Int = 0
        
        healthKitManager.readUnderwaterDepths(forToday: Date(), healthStore: healthStore) {
            diveQuery in
            if diveQuery.count > diveCount {
                let sortedDives = diveQuery.sorted(by: { $0.startTime.compare($1.startTime) == .orderedDescending })
                DispatchQueue.main.async {
                    self.diveList = sortedDives
                }
                diveCount = diveQuery.count
            } else {
                if self.debug {
                    let sampleDives = self.previewData()
                    let sortedDives = sampleDives.sorted(by: { $0.startTime.compare($1.startTime) == .orderedDescending })

                    DispatchQueue.main.sync {
                        self.diveList = sortedDives
                    }
                    diveCount = self.diveList.count
                }
            }
        }
        healthKitManager.readWaterTemps(forToday: Date(), healthStore: healthStore) {
            tempSamples in
            DispatchQueue.main.async {
                self.temps = tempSamples
            }
        }
    }
    
    // Preview Data is used to build sample data when in Debug mode and Healthkit datastore does not have Depth information.
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
                
                let sample: DepthSample = .init(start: curDate, end: endDate, depth: depth)
                sampleDive.profile.append(sample)
                curDate = endDate
            }
            for i in stride(from: 1, to: 80, by: 1) {
                let depth: Double = Double(80-i)
                let endDate = curDate.addingTimeInterval(10)
                
                let sample: DepthSample = .init(start: curDate, end: endDate, depth: depth)
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
