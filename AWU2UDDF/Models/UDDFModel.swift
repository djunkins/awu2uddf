//
//  UDDFModel.swift
//  AWU2UDDF
//
//  Created by Doug Junkins on 12/26/22.
//

import Foundation

// Class for building a UDDF XML string to store in file.
class UDDF {
    var uddfString: String
    
    init() {
        self.uddfString = ""
    }
    
    // Search for a temperature sample that has a particular start to the time interval
    func searchTemps(date: Date, temps: [Temp_Sample]) -> Double {
        for tempSample in temps {
            if tempSample.start == date {
                // matched a sample start time so return temperature
                return tempSample.temp
            }
        }
        
        // return -999.9 if no matching sample is found
        return -999.9
    }

    // Build the <generator> section of UDDF
    func generatorString() -> String {
        var xmlString = ""
        
        xmlString += "  <generator>\n"
        xmlString += "    <name>awu2uddf</name>\n"
        xmlString += "    <manufacturer id=\"Foghead\">\n"
        xmlString += "      <name>Doug Junkins</name>\n"
        xmlString += "    </manufacturer>\n"
        xmlString += "    <version>0.1</version>\n"
        xmlString += "  </generator>\n"

        return xmlString
    }

    // Build the <diver> section of UDDF
    func diverString() -> String {
        var xmlString = ""
        
        xmlString += "  <diver>\n"
        xmlString += "    <owner id=\"owner\">\n"
        xmlString += "      <personal>\n"
        xmlString += "        <firstname/>\n"
        xmlString += "        <lastname/>\n"
        xmlString += "      </personal>\n"
        xmlString += "      <equipment>\n"
        xmlString += "        <divecomputer id=\"81333b70\">\n"
        xmlString += "          <name>Apple Watch Ultra</name>\n"
        xmlString += "          <model>Apple Watch Ultra</model>\n"
        xmlString += "        </divecomputer>\n"
        xmlString += "      </equipment>\n"
        xmlString += "    </owner>\n"
        xmlString += "    <buddy/>\n"
        xmlString += "  </diver>\n"

        return xmlString

    }

    // Build the <profile> section of UDDF by matching depth samples with temperature samples
    func profileDataString(startTime: Date, profile: [Depth_Sample], temps: [Temp_Sample]) -> String {
        var xmlString = ""

        xmlString += "  <profiledata>\n"
        xmlString += "    <repetitiongroup id=\"" + startTime.ISO8601Format() + "\">\n"
        xmlString += "      <dive id=\"" + startTime.ISO8601Format() + "\">\n"
        xmlString += "        <informationbeforedive>\n"

        // Use the Dive class start time as the UDDF <datetime> field
        xmlString += "          <datetime>" + startTime.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ssZ") + "</datetime>\n"
        xmlString += "        </informationbeforedive>\n"
        xmlString += "        <samples>\n"
        
        for sample in profile {
            // for each sample, convert the to a divetime offset by subtracting the dive start time
            // from the sample end time. Maybe this should be changed to the average of the sample
            // start time and sample end time?
            let sampleTime = sample.end.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate

            let depthMeters = sample.depth

            // find the matching temperature sample if it exists
            let tempCelcius = searchTemps(date: sample.start, temps: temps)

            xmlString += "          <waypoint>\n"
            xmlString += "            <depth>" + String(format: "%.3f", depthMeters) + "</depth>\n"
            xmlString += "            <divetime>" + String(format: "%.3f",sampleTime) + "</divetime>\n"

            // Check if temperature sample exists, and if so add the <temperature> reading to UDDF
            // string. UDDF measures temperatures in Kelvin, so add 273.15 to centrigrade temperature
            if tempCelcius != -999.9 {
                xmlString += "            <temperature>" + String(format: "%.1f", (tempCelcius + 273.15)) + "</temperature>\n"
            }
            xmlString += "          </waypoint>\n"
        }
        
        xmlString += "        </samples>\n"
        xmlString += "      </dive>\n"
        xmlString += "    </repetitiongroup>\n"
        xmlString += "  </profiledata>\n"

        return xmlString
    }
    
    func buildUDDFString (startTime: Date, profile: [Depth_Sample], temps: [Temp_Sample]) -> String {
        print ("Total Temps: \(temps.count)")
        self.uddfString = ""
        uddfString =  "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        uddfString += "<uddf xmlns=\"http://www.streit.cc/uddf/3.2/\" version=\"3.2.0\">\n"
        uddfString += generatorString()
        uddfString += diverString()
        uddfString += "  <divesite/>\n"
        uddfString += "  <gasdefinitions/>\n"
        uddfString += profileDataString(startTime: startTime, profile: profile, temps: temps)
        uddfString += "</uddf>\n"
        return self.uddfString
    }
}
