//
//  SettingsView.swift
//  AWU2UDDF
//
//  Created by James Cash on 2023-08-02.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var settings: Settings
     
    private enum EditingField: Int, CaseIterable {
        case shortTime, deepDepth
    }
    
    @FocusState private var focusedField: EditingField?
    
    private var numberFormatter = {
        let nf = NumberFormatter()
        nf.allowsFloats = true
        nf.maximumFractionDigits = 1
        return nf
    }()
    
    private var localizedDeepDepth: Binding<Double> {
        Binding(get: { self.settings.metresToDistance(self.settings.deepDiveDepthMetres)},
                set: { val in
            print("depth \(val)")
            self.settings.deepDiveDepthMetres = settings.distanceToMetres(val) })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Display Units")
                Spacer()
                Picker("Units", selection: $settings.displayUnits) {
                    Text("🇺🇸 ft °F m/d/y").tag(DisplayUnits.imperial)
                    Text("🌎 m °C y-m-d").tag(DisplayUnits.metric)
                    Text("🇨🇦 ft °C d/m/y").tag(DisplayUnits.canadian)
                }
            }
            
            HStack {
                Toggle("Export Water Temperatures", isOn: $settings.exportTemps)
                Spacer()
                
            }
            HStack {
                Text("\"Short dive\" time")
                Spacer()
                TextField("", value: $settings.shortDiveDurationMinutes, formatter: NumberFormatter())
                    .focused($focusedField, equals: .shortTime)
                    .frame(width: 30)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text("minutes")
                Stepper(value: $settings.shortDiveDurationMinutes) { EmptyView() }.labelsHidden()
            }
            
            HStack {
                Text("\"Deep dive\" depth")
                Spacer()
                TextField("", value: localizedDeepDepth, formatter: numberFormatter)
                    .focused($focusedField, equals: .deepDepth)
                    .frame(width: 60)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text(settings.displayUnits.depthUnit())
                Stepper(value: localizedDeepDepth) { EmptyView() }.labelsHidden()
            }
            
            Spacer()
            
        }.toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(Settings())
    }
}
