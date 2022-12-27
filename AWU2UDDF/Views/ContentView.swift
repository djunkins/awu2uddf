//
//  ContentView.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: HealthKitViewModel
    @State private var selection: Dive.ID?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack {
            if vm.isAuthorized {
                NavigationView {

                    VStack {

                        Text("Dive List")
                            .font(.largeTitle)
                    
                        Text("Total Dive Count: \(vm.diveList.count)")
                        Spacer()
                        Spacer()
                        HStack {
                            Text("Dive Time")
                                .frame(width: 160, alignment: .leading)
                            
                            Text("Duration")
                                .frame(width: 70, alignment: .trailing)

                            Text("Max Depth")
                                .frame(width: 60, alignment: .trailing)
                        }

                        List (vm.diveList, id: \.self) { dive in
                            NavigationLink(destination: DiveExportView(dive:dive)) {
                                DiveRowView(dive: dive)
                            }
                        }
                    }
                }
            } else {
                VStack {
                    Text("Please Authorize Access")
                        .font(.title3)
                    Text("to Dive Data").font(.title3)
                    
                    Button {
                        vm.healthRequest()
                    } label: {
                        Text("Authorize HealthKit")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(width: 320, height: 55)
                    .background(Color(.orange))
                    .cornerRadius(10)
                }
            }
            
        }
        .padding()
        .onAppear {
            vm.readDiveDepths()
        }
    
    }
}


struct ContentView_Previews: PreviewProvider {
    let dive: Dive
    
    static var previews: some View {
        ContentView()
            .environmentObject(HealthKitViewModel())
    }
}
