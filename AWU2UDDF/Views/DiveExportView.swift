//
//  DiveExportView.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import SwiftUI
import UniformTypeIdentifiers

struct DiveExportView: View {
    let dive: Dive
    let temps: [TemperatureSample]
    
    @State private var isExporting = false
    
    @State private var exportDocument: UDDFFile? = nil
    
    @EnvironmentObject var settings: Settings
    
    private func generateExportDocument() {
        if (settings.exportTemps) {
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                let document = UDDFFile(initialText: dive.buildUDDF(temps: temps))
                DispatchQueue.main.async { [self] in
                    self.exportDocument = document
                }
            }
        } else {
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                let document = UDDFFile(initialText: dive.buildUDDF(temps: []))
                DispatchQueue.main.async { [self] in
                    self.exportDocument = document
                }
            }

        }
    }
    
    private func setTemperatures() {
        let tempsByDate = Dictionary(grouping: temps, by: { temp in temp.start }).mapValues({ $0.first! })
        dive.setTemperatures(temps: tempsByDate)
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Export UDDF File")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            Text("Dive Time: \(settings.dateFormatter.string(from: dive.startTime))")
                .font(.title3).padding()
            Text("Duration: \(Int((dive.duration() + 59.0) / 60.0)) min").padding()
            VStack {
                Text("Max Depth: \(settings.displayDepth(metres: dive.maxDepth(), shortUnits: false))").padding()
                Text("Average Depth: \(settings.displayDepth(metres: dive.avgDepth(), shortUnits: false))").padding()
                if (settings.exportTemps) {
                    Text("Min Temperature: \(settings.displayTemp(celsius: dive.minTemp, shortUnits: true))").padding()
                    Text("Max Temperature: \(settings.displayTemp(celsius: dive.maxTemp, shortUnits: true))").padding()
                }
            }
    
            ZStack {
                Button {
                    isExporting = true
                } label: {
                    Text("Export Dive")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 320, height: 55)
                }
                .background(.orange)
                .cornerRadius(10)
                .padding()
                .opacity(exportDocument == nil ? 0.5 : 1)
                .disabled(exportDocument == nil)
                .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: UTType.xml, defaultFilename: dive.defaultUDDFFilename()) { result in
                    switch result {
                    case .success(let url):
                        print("Saved to \(url)")
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                if exportDocument == nil {
                    ProgressView()
                }
            }
            Spacer()
            Spacer()
        }
        .onAppear(perform: {
            self.setTemperatures()
            self.generateExportDocument()
        })
    }
}

struct DiveExportView_Previews: PreviewProvider {
    static var previews: some View {
        DiveExportView(dive: Dive(startTime: Date.now), temps: [])
            .environmentObject(Settings())
    }
}

struct UDDFFile: FileDocument {
    // tell the system we support only plain text
    static var readableContentTypes = [UTType.xml]
    static var writableContentTypes = [UTType.xml]

    // by default our document is empty
    var text = ""

    // a simple initializer that creates new, empty documents
    init(initialText: String = "") {
        text = initialText
    }

    // this initializer loads data that has been saved previously
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    // this will be called when the system wants to write our data to disk
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
