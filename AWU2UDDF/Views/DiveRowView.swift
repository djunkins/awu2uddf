//
//  DiveRowView.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import SwiftUI

struct DiveRowView: View {
    let dive: Dive

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy h:mm a"
        return formatter
    }()
    
    var body: some View {
        let duration = Int((dive.Duration() + 59.0) / 60.0)
        HStack {
            Text(DiveRowView.dateFormatter.string(from:dive.startTime))
                .frame(width: 150, alignment: .leading)
            
            Text("\(duration) min")
                .frame(width: 60, alignment: .trailing)

            Text(String(format: "%.1f m",dive.MaxDepth()))
                .frame(width: 60, alignment: .trailing)
        }
    }
}

struct DiveRowView_Previews: PreviewProvider {
    static var previews: some View {
        DiveRowView(dive: Dive(startTime: Date.now))
    }
}
