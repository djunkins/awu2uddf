//
//  AWU2UDDFApp.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import SwiftUI

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

let awu2uddf_version = "1.2(2)"

@main
struct AWU2UDDFApp: App {
    var healthVM = HealthKitViewModel()
    
    var settings = Settings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthVM)
                .environmentObject(settings)
       }
    }
}
