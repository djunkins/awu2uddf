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
    @Published var isAuthorized = false
    
    init() {
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
            }
        }
    }
}
