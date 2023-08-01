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
    let temps: [Temp_Sample]
    
    @State var isExporting = false
    
    var body: some View {
        VStack {
            Spacer()
            Text("Export UDDF File")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            Text("Dive Time: \(dive.startTime.formatted())").font(.title3).padding()
            Text("Duration: \(Int((dive.Duration() + 59.0) / 60.0)) min").padding()
            Text("Max Depth: \(Int(dive.MaxDepth())) meters").padding()
    
            Button {
                isExporting = true
            } label: {
                Text("Export Dive")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 320, height: 55)
            }
            .background(Color(.orange))
            .cornerRadius(10)
            .padding()
            .fileExporter(isPresented: $isExporting, document: UDDFFile(initialText: dive.buildUDDF(temps: temps)), contentType: UTType.xml, defaultFilename: dive.defaultUDDFFilename()) {      result in
                    switch result {
                    case .success(let url):
                        print("Saved to \(url)")
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            Spacer()
            Spacer()
        }
    }
}

struct DiveExportView_Previews: PreviewProvider {
    static var previews: some View {
        DiveExportView(dive: Dive(startTime: Date.now), temps: [])
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
