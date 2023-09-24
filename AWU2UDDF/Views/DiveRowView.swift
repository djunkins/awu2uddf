//
//  DiveRowView.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import SwiftUI

struct DiveRowView: View {
    let dive: Dive
    
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        let duration = Int((dive.duration() + 59.0) / 60.0)
        HStack {
            Text(settings.dateFormatter.string(from: dive.startTime))
                .frame(width: 150, alignment: .leading)
            
            Text("\(duration) min")
                .frame(width: 60, alignment: .trailing)

            Text(settings.displayDepth(metres: dive.maxDepth()))
                .frame(width: 60, alignment: .trailing)
        }
    }
}

struct DiveRowView_Previews: PreviewProvider {
    static var previews: some View {
        DiveRowView(dive: Dive(startTime: Date.now))
            .environmentObject(Settings())
    }
}
