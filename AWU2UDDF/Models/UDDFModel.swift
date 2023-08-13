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
    let tag: String
    let attributes: [String:String]?
    let children: [Child]
    
    init(tag: String, attributes: [String : String]? = nil, children: [XMLNode] = []) {
        self.tag = tag
        self.attributes = attributes
        self.children = children.map({ .xml($0) })
    }
    
    init(tag: String, textContent: String) {
        self.tag = tag
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
        let open = "\("    ".repeating(times: depth))<\(tag)\(emitAttrs())"
        let after: String
        if children.count == 0 {
            after = "/>"
        } else if children.count == 1,
                  case let .text(content) = children.first! {
            after = ">\(content)</\(tag)>"
        } else {
            after = """
            >
            \(children.map({ $0.emit(depth: depth + 1) }).joined(separator: "\n"))
            \("    ".repeating(times: depth))</\(tag)>
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
        return XMLNode(tag: "generator",
                       children: [
                        XMLNode(tag: "name", textContent: "awu2uddf"),
                        XMLNode(tag: "manufacturer",
                                attributes: ["id": "Foghead"],
                                children: [XMLNode(tag: "name", textContent: "Doug Junkins")]),
                        XMLNode(tag: "version", textContent: awu2uddf_version)])
    }
    
    // Build the <diver> section of UDDF
    func diverElem() -> XMLNode {
        return XMLNode(tag: "diver",
                       children: [
                        XMLNode(tag: "owner", attributes: ["id": "owner"],
                                children: [
                                    XMLNode(tag: "personal",
                                            children: [XMLNode(tag: "firstname"), XMLNode(tag: "lastname")]),
                                    XMLNode(tag: "equipment",
                                            children: [
                                                XMLNode(tag: "divecomputer",
                                                        attributes: ["id": "81333b70"],
                                                        children: [
                                                            XMLNode(tag: "name", textContent: "Apple Watch Ultra"),
                                                            XMLNode(tag: "model", textContent: "Apple Watch Ultra")])])]),
                        XMLNode(tag: "buddy")])
    }
    
    // Build the <profile> section of UDDF by matching depth samples with temperature samples
    func profileDataElements(startTime: Date, profile: [DepthSample], temps: [Date:TemperatureSample]) -> XMLNode {
        let samples = profile.map({ depthSample in
            var children = [XMLNode(tag: "depth", textContent: String(format: "%.3f", depthSample.depth)),
                            XMLNode(tag: "divetime",
                                    textContent: String(format: "%.3f", depthSample.end.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate))]
            if let tempSample = temps[depthSample.start] {
                // UDDF measures temperatures in Kelvin, so add 273.15 to centrigrade temperature
                children.append(XMLNode(tag: "temperature", textContent: String(format: "%.1f", tempSample.temp + 273.15)))
            }
            return XMLNode(tag: "waypoint", children: children)
        })
        
        return XMLNode(tag: "profiledata",
                       children: [
                        XMLNode(tag: "repetitiongroup", attributes: ["id": startTime.ISO8601Format()],
                                children: [
                                    XMLNode(tag: "dive", attributes: ["id": startTime.ISO8601Format()],
                                            children: [
                                                XMLNode(tag: "informationbeforedive",
                                                        children: [XMLNode(tag: "datetime",
                                                                           textContent: startTime.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ssZ"))]),
                                                XMLNode(tag: "samples", children: samples)])])])
    }
    
    func buildUDDFString (startTime: Date, profile: [DepthSample], temps: [TemperatureSample]) -> String {
        print ("Total Temps: \(temps.count)")
        let tempsByDate = Dictionary(grouping: temps, by: { temp in temp.start }).mapValues({ $0.first! })
        let doc = XMLDocument(rootNode:
                                XMLNode(tag: "uddf",
                                        attributes: ["xmlns": "http://www.streit.cc/uddf/3.2/",
                                                     "version": "3.2.0"],
                                        children: [
                                            generatorElem(),
                                            diverElem(),
                                            XMLNode(tag: "divesite"),
                                            XMLNode(tag: "gasdefinitions"),
                                            profileDataElements(startTime: startTime, profile: profile, temps: tempsByDate),
                                        ]))
        
        return doc.emit()
    }
}
