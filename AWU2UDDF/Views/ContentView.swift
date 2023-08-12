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
    
    @EnvironmentObject var settings: Settings
    
    @State private var showFilter: Bool = false
    @State private var filterShortDives: Bool = false
    @State private var filterDeepDives: Bool = false
    @State private var filterDateStart: Date = Date.distantPast
    @State private var filterDateEnd: Date = Date.now
    
    private var displayedDives: [Dive] {
        get {
            return vm.diveList
                .filter({ dive in !filterShortDives || dive.duration() > Double(settings.shortDiveDurationMinutes) * 60 })
                .filter({ dive in !filterDeepDives || dive.maxDepth() > settings.deepDiveDepthMetres })
                .filter({ dive in dive.startTime >= filterDateStart && dive.startTime <= filterDateEnd})
        }
    }
    
    var body: some View {
        VStack {
            if vm.isAuthorized {
                NavigationView {
                    
                    ZStack {
                        
                        NavigationLink {
                            SettingsView()
                                .navigationTitle("Settings")
                        } label: {
                            Image(systemName: "gear")
                        }.position(x: 10, y: 10)
                        
                        VStack {
                            
                            Text("Dive List")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Total Dive Count: \(vm.diveList.count)")
                            
                            Text("Displayed Dive Count: \(displayedDives.count)")
                                .font(.subheadline)
                                .foregroundColor(vm.diveList.count == displayedDives.count
                                                 ? Color.white.opacity(0)
                                                 : .primary)
                                .accessibilityHidden(vm.diveList.count == displayedDives.count)
                            
                            HStack {
                                Spacer()
                                Button {
                                    if !showFilter {
                                        filterDateStart = max(filterDateStart, vm.diveList.last?.startTime ?? Date.now)
                                    }
                                    showFilter = !showFilter
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle\(showFilter ? ".fill" : "")")
                                }
                            }
                            
                            if showFilter {
                                VStack {
                                    
                                    Toggle("Longer than \(settings.shortDiveDurationMinutes) minutes", isOn: $filterShortDives)
                                    
                                    Toggle("Deeper than \(settings.displayDepth(metres: settings.deepDiveDepthMetres))", isOn: $filterDeepDives)
                                    
                                    HStack {
                                        DatePicker("", selection: $filterDateStart,
                                                   in: Date.distantPast...filterDateEnd,
                                                   displayedComponents: .date)
                                        Text(" to ").minimumScaleFactor(0.5)
                                        DatePicker("", selection: $filterDateEnd,
                                                   in: filterDateStart...Date.now,
                                                   displayedComponents: .date)
                                    }
                                }.padding(.horizontal, 10)
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
                                List (displayedDives, id: \.self) { dive in
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
            .environmentObject(Settings())
            .environmentObject(HealthKitViewModel())
    }
}
