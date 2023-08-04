//
//  UDDFModel.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import Foundation

extension String {
    func repeating(times: Int) -> String {
        Array(repeating: self, count: times).joined(separator: "")
    }
}

struct XMLNode {
    enum Child {
        case text(String)
        case xml(XMLNode)
        
        func emit(depth: Int = 0) -> String {
            switch self {
            case let .text(content):
                return "    ".repeating(times: depth) + content
            case let .xml(xml):
                return xml.emit(depth: depth)
            }
        }
    }
    let title: String
    let attributes: [String:String]?
    let children: [Child]
    
    init(title: String, attributes: [String : String]? = nil, children: [XMLNode] = []) {
        self.title = title
        self.attributes = attributes
        self.children = children.map({ .xml($0) })
    }
    
    init(title: String, textContent: String) {
        self.title = title
        self.attributes = nil
        self.children = [.text(textContent)]
    }
    
    private func emitAttrs() -> String {
        if let attrs = attributes {
            return attrs.map({ (key, val) in " \(key)=\"\(val)\"" }).joined(separator: "")
        } else {
            return ""
        }
    }
    
    func emit(depth: Int = 0) -> String {
        let open = "\("    ".repeating(times: depth))<\(title)\(emitAttrs())"
        let after: String
        if children.count == 0 {
            after = "/>"
        } else if children.count == 1,
                  case let .text(content) = children.first! {
            after = ">\(content)</\(title)>"
        } else {
            after = """
            >
            \(children.map({ $0.emit(depth: depth + 1) }).joined(separator: "\n"))
            \("    ".repeating(times: depth))</\(title)>
            """
        }
        return open + after
    }
}

struct XMLDocument {
    let rootNode: XMLNode
    
    func emit() -> String {
        return """
        <?xml version="1.0" encoding="utf-8"?>
        \(rootNode.emit())
        """
    }
}

// Class for building a UDDF XML string to store in file.
// TODO: this could now just be a stand-alone function, it has no state...maybe a single static method, maybe a method on UDDFFile instead
class UDDF {
    
    // Build the <generator> section of UDDF
    func generatorElem() -> XMLNode {
        return XMLNode(title: "generator",
                       children: [
                        XMLNode(title: "name", textContent: "awu2uddf"),
                        XMLNode(title: "manufacturer",
                                attributes: ["id": "Foghead"],
                                children: [XMLNode(title: "name", textContent: "Doug Junkins")]),
                        XMLNode(title: "version", textContent: awu2uddf_version)])
    }
    
    // Build the <diver> section of UDDF
    func diverElem() -> XMLNode {
        return XMLNode(title: "diver",
                       children: [
                        XMLNode(title: "owner", attributes: ["id": "owner"],
                                children: [
                                    XMLNode(title: "personal",
                                            children: [XMLNode(title: "firstname"), XMLNode(title: "lastname")]),
                                    XMLNode(title: "equipment",
                                            children: [
                                                XMLNode(title: "divecomputer",
                                                        attributes: ["id": "81333b70"],
                                                        children: [
                                                            XMLNode(title: "name", textContent: "Apple Watch Ultra"),
                                                            XMLNode(title: "model", textContent: "Apple Watch Ultra")])])]),
                        XMLNode(title: "buddy")])
    }
    
    // Build the <profile> section of UDDF by matching depth samples with temperature samples
    func profileDataElements(startTime: Date, profile: [DepthSample], temps: [Date:TemperatureSample]) -> XMLNode {
        let samples = profile.map({ depthSample in
            var children = [XMLNode(title: "depth", textContent: String(format: "%.3f", depthSample.depth)),
                            XMLNode(title: "divetime",
                                    textContent: String(format: "%.3f", depthSample.end.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate))]
            if let tempSample = temps[depthSample.start] {
                // UDDF measures temperatures in Kelvin, so add 273.15 to centrigrade temperature
                children.append(XMLNode(title: "temperature", textContent: String(format: "%.1f", tempSample.temp + 273.15)))
            }
            return XMLNode(title: "waypoint", children: children)
        })
        
        return XMLNode(title: "profiledata",
                       children: [
                        XMLNode(title: "repetitiongroup", attributes: ["id": startTime.ISO8601Format()],
                                children: [
                                    XMLNode(title: "dive", attributes: ["id": startTime.ISO8601Format()],
                                            children: [
                                                XMLNode(title: "informationbeforedive",
                                                        children: [XMLNode(title: "datetime",
                                                                           textContent: startTime.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ssZ"))]),
                                                XMLNode(title: "samples", children: samples)])])])
    }
    
    func buildUDDFString (startTime: Date, profile: [DepthSample], temps: [TemperatureSample]) -> String {
        print ("Total Temps: \(temps.count)")
        let tempsByDate = Dictionary(grouping: temps, by: { temp in temp.start }).mapValues({ $0.first! })
        let doc = XMLDocument(rootNode:
                                XMLNode(title: "uddf",
                                        attributes: ["xmlns": "http://www.streit.cc/uddf/3.2/",
                                                     "version": "3.2.0"],
                                        children: [
                                            generatorElem(),
                                            diverElem(),
                                            XMLNode(title: "divesite"),
                                            XMLNode(title: "gasdefinitions"),
                                            profileDataElements(startTime: startTime, profile: profile, temps: tempsByDate),
                                        ]))
        
        return doc.emit()
    }
}
