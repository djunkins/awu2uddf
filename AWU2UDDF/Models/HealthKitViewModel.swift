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
    @Published var temps: [Temp_Sample] = []
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
    
    func readDiveDepths() {
        print ("Reading Dive Depths")
        var diveCount: Int = 0
        
        healthKitManager.readUnderwaterDepths(forToday: Date(), healthStore: healthStore) {
            diveQuery in
            if diveQuery.count > diveCount {
                DispatchQueue.main.async {
                    self.diveList = diveQuery
                }
                diveCount = diveQuery.count
            } else {
                if self.debug {
                    DispatchQueue.main.async {
                        self.diveList = self.previewData()
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
        
        return sampleDives
    }
}
