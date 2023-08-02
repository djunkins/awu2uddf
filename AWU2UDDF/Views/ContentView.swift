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
    
    @State private var showFilter: Bool = false
    @State private var filterShortDives: Bool = false
    @State private var filterDateStart: Date = Date.distantPast
    @State private var filterDateEnd: Date = Date.now
    
    var body: some View {
        VStack {
            if vm.isAuthorized {
                NavigationView {

                    VStack {

                        Text("Dive List")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    
                        Text("Total Dive Count: \(vm.diveList.count)")
                        
                        if showFilter {
                            HStack {
                                VStack {
                                    
                                    Toggle("Longer than five minutes", isOn: $filterShortDives)
                                    
                                    
                                    HStack {
                                        DatePicker("", selection: $filterDateStart,
                                                   in: Date.distantPast...filterDateEnd,
                                                   displayedComponents: .date)
                                        Text(" to ").minimumScaleFactor(0.5)
                                        DatePicker("", selection: $filterDateEnd,
                                                   in: filterDateStart...Date.now,
                                                   displayedComponents: .date)
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    showFilter = false
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                
                                Button {
                                    filterDateStart = vm.diveList.last?.startTime ?? Date.now
                                    showFilter = true
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                }
                            }
                        }
                        
                        HStack {
                            Text("Dive Time")
                                .frame(width: 140, alignment: .leading)
                            
                            Text("Duration")
                                .frame(width: 70, alignment: .trailing)

                            Text("Max Depth")
                                .frame(width: 60, alignment: .trailing)
                        }

                        if vm.diveList.count > 0 {
                            List (vm.diveList
                                .filter({ dive in !filterShortDives || dive.Duration() > 300 })
                                .filter({ dive in dive.startTime > filterDateStart && dive.startTime < filterDateEnd}),
                                  id: \.self) { dive in
                                NavigationLink(destination: DiveExportView(dive:dive, temps: vm.temps)) {
                                    DiveRowView(dive: dive)
                                }
                            }
                        } else {
                            Spacer()
                            Text("No dive data in HealthKit").fontWeight(.bold)
                            Spacer()
                            Spacer()
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
                            .frame(width: 320, height: 55)
                    }
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
