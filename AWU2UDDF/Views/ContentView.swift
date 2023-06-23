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

                        Text("Dive Tracker")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    
                        Text("Total  \(vm.allDivesList.count) dives (\(vm.onlyDeeperThan10mList.count) deep, \(vm.onlyShallowList.count) shallow)")
                        HStack {
                            
                            Button(action: {vm.shownDivesList = vm.onlyDeeperThan10mList}, label: {
                                Text("Deep")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 30)
                                    .background(Color(.orange))
                                    .cornerRadius(10)
                                    .padding()
                                    
                            })
                            Button(action: {vm.shownDivesList = vm.onlyShallowList
                            }, label: {
                                Text("Shallow")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 30)
                                    .background(Color(.orange))
                                    .cornerRadius(10)
                                    .padding()
                                    
                            })
                            Button(action: {vm.shownDivesList = vm.allDivesList}, label: {
                                Text("All")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 30)
                                    .background(Color(.orange))
                                    .cornerRadius(10)
                                    .padding()
                                    
                            })
                        }
                        HStack {
                            Text("Dive Time")
                                .frame(width: 140, alignment: .leading)
                            
                            Text("Duration")
                                .frame(width: 70, alignment: .trailing)

                            Text("Depth")
                                .frame(width: 60, alignment: .trailing)
                        }

                        if (vm.queriesCompleted) {
                            if vm.shownDivesList.count > 0 {
                                List (vm.shownDivesList, id: \.self) { dive in
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
                        } else {
                            Spacer()
                            Text("Populating dive data...").fontWeight(.bold)
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
                    }
                    .frame(width: 320, height: 55)
                    .background(Color(.orange))
                    .cornerRadius(10)
                }
            }
            
        }
        .padding()
        .onAppear {
            vm.readDiveData()
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
