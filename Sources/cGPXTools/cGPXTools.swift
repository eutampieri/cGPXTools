//
//  cGPX.swift
//  cGPXTools
//
//  Created by Eugenio Tampieri on 26/06/18.
//  Copyright © 2018 Eugenio Tampieri. All rights reserved.
//

import Foundation
public class GPX {
    let version = "0.1"
    func info()->String{
        return "GPXLib \(version)"
    }
    enum Errors: Error{
        case XmlParseFailed
        case InvalidGPXType
        case EleDataFailed
    }
    enum ErrorCodes:Int32{
        case XmlParseFailed = 2
        case InvalidGPXType = 3
        case EleDataFailed = 4
    }
    enum GPXType: Int {
        case wpt = 0
        case trk = 1
        case none = -1
    }
    var gpxTree:XMLDocument
    init(){
        gpxTree=XMLDocument()
    }
    init(gpx: String) throws{
        do{
            try gpxTree=XMLDocument(xmlString: gpx)
        }
        catch{
            throw Errors.XmlParseFailed
        }
    }
    func type()->GPXType{
        let wptLen = gpxTree.rootElement()?.elements(forName: "wpt").count
        let trkLen = gpxTree.rootElement()?.elements(forName: "trk").count
        if wptLen!>0{
            return GPXType.wpt
        }
        else if trkLen!>0{
            return GPXType.trk
        }
        return GPXType.none
    }
    func dump()->XMLDocument{
        return gpxTree
    }
    func reverse() throws ->XMLDocument{
        var newGPX:XMLDocument
        do{
            newGPX=try XMLDocument(xmlString: gpxTree.xmlString)
        }
        catch{
            throw GPX.Errors.XmlParseFailed
        }
        if type()==GPXType.wpt{
            throw GPX.Errors.InvalidGPXType
        }
        else if type()==GPXType.trk{
            let listaTrkDel = newGPX.rootElement()?.elements(forName: "trk")
            for trk in listaTrkDel!{
                newGPX.rootElement()?.removeChild(at: trk.index)
            }
            //print(newGPX)
            guard let listaTrks:[XMLElement]=gpxTree.rootElement()?.elements(forName: "trk")
                else{
                    throw Errors.XmlParseFailed
            }
            for trk in listaTrks.reversed(){
                //print("Aggiungo trk")
                let trkNode=XMLNode(kind: XMLNode.Kind.element)
                trkNode.name="trk"
                newGPX.rootElement()?.addChild(trkNode)
                let trkNodesListFromTree = newGPX.rootElement()?.elements(forName: "trk")
                let trkNodeFromTree = trkNodesListFromTree![trkNodesListFromTree!.count-1]
                for additional in trk.children!{
                    if additional.name!=="trkseg"{
                        continue
                    }
                    let additionalNode:XMLElement
                    do{
                        additionalNode=try XMLElement(xmlString: additional.xmlString)
                    }catch{
                        throw Errors.XmlParseFailed
                    }
                    trkNodeFromTree.addChild(additionalNode)
                }
                for trkseg in trk.elements(forName: "trkseg").reversed(){
                    let trksegNode=XMLNode(kind: XMLNode.Kind.element)
                    trksegNode.name="trkseg"
                    trkNodeFromTree.addChild(trksegNode)
                    let trksegNodesListFromTree = trkNodeFromTree.elements(forName: "trkseg")
                    let trksegNodeFromTree = trksegNodesListFromTree[trksegNodesListFromTree.count-1]
                    for trkpt in trkseg.elements(forName: "trkpt").reversed(){
                        let trkptClone:XMLElement
                        do{
                            trkptClone=try XMLElement(xmlString: trkpt.xmlString)
                        }catch{
                            throw Errors.XmlParseFailed
                        }
                        trksegNodeFromTree.addChild(trkptClone)
                    }
                }
            }
        }
        return newGPX
    }
    func flatten() throws ->XMLDocument{
        var newGPX:XMLDocument
        do{
            newGPX=try XMLDocument(xmlString: gpxTree.xmlString)
        }
        catch{
            throw Errors.XmlParseFailed
        }
        if type()==GPXType.wpt || type()==GPXType.none{
            throw Errors.InvalidGPXType
        }
        else if type()==GPXType.trk{
            let listaTrkDel = newGPX.rootElement()?.elements(forName: "trk")
            for trk in listaTrkDel!{
                newGPX.rootElement()?.removeChild(at: trk.index)
            }
            guard let listaTrks:[XMLElement]=gpxTree.rootElement()?.elements(forName: "trk")
                else{
                    throw Errors.XmlParseFailed
            }
            for trk in listaTrks{
                let trkNode=XMLNode(kind: XMLNode.Kind.element)
                trkNode.name="trk"
                newGPX.rootElement()?.addChild(trkNode)
                let trkNodesListFromTree = newGPX.rootElement()?.elements(forName: "trk")
                let trkNodeFromTree = trkNodesListFromTree![trkNodesListFromTree!.count-1]
                for additional in trk.children!{
                    if additional.name!=="trkseg"{
                        continue
                    }
                    let additionalNode:XMLElement
                    do{
                        additionalNode=try XMLElement(xmlString: additional.xmlString)
                    }catch{
                        throw Errors.XmlParseFailed
                    }
                    trkNodeFromTree.addChild(additionalNode)
                }
                let trksegNode=XMLNode(kind: XMLNode.Kind.element)
                trksegNode.name="trkseg"
                trkNodeFromTree.addChild(trksegNode)
                let trksegNodesListFromTree = trkNodeFromTree.elements(forName: "trkseg")
                let trksegNodeFromTree = trksegNodesListFromTree[trksegNodesListFromTree.count-1]
                for trkseg in trk.elements(forName: "trkseg"){
                    for trkpt in trkseg.elements(forName: "trkpt"){
                        let trkptClone:XMLElement
                        do{
                            trkptClone=try XMLElement(xmlString: trkpt.xmlString)
                        }catch{
                            throw Errors.XmlParseFailed
                        }
                        trksegNodeFromTree.addChild(trkptClone)
                    }
                }
            }
        }
        return newGPX
    }
    func combine(others: [GPX]) throws -> XMLDocument{
        var newGPX:XMLDocument
        do{
            newGPX=try XMLDocument(xmlString: flatten().xmlString)
        }
        catch{
            throw Errors.XmlParseFailed
        }
        if type()==GPXType.wpt || type()==GPXType.none{
            throw Errors.InvalidGPXType
        }
        else if type()==GPXType.trk{
            for other in others{
                guard let listaTrks:[XMLElement] = try other.flatten().rootElement()?.elements(forName: "trk")
                    else{
                        throw Errors.XmlParseFailed
                }
                for trk in listaTrks{
                    let trkNodesListFromTree = newGPX.rootElement()?.elements(forName: "trk")
                    let trkNodeFromTree = trkNodesListFromTree![trkNodesListFromTree!.count-1]
                    /*let trksegNode=XMLNode(kind: XMLNode.Kind.element)
                     trksegNode.name="trkseg"
                     trkNodeFromTree.addChild(trksegNode)*/
                    let trksegNodesListFromTree = trkNodeFromTree.elements(forName: "trkseg")
                    let trksegNodeFromTree = trksegNodesListFromTree[trksegNodesListFromTree.count-1]
                    for trkseg in trk.elements(forName: "trkseg"){
                        for trkpt in trkseg.elements(forName: "trkpt"){
                            let trkptClone:XMLElement
                            do{
                                trkptClone=try XMLElement(xmlString: trkpt.xmlString)
                            }catch{
                                throw Errors.XmlParseFailed
                            }
                            trksegNodeFromTree.addChild(trkptClone)
                        }
                    }
                }
            }
        }
        return newGPX
    }
    func splice(lat:Double, lon:Double, backwards:Bool=false)throws ->XMLDocument{
        var newGPX:XMLDocument
        var distanze:[Int:Double] = [:]
        do{
            newGPX=try XMLDocument(xmlString: flatten().xmlString)
        }
        catch{
            throw GPX.Errors.XmlParseFailed
        }
        if type()==GPXType.wpt{
            throw GPX.Errors.InvalidGPXType
        }
        else if type()==GPXType.trk{
            let trkNodesListFromTree = newGPX.rootElement()?.elements(forName: "trk")
            let trk = trkNodesListFromTree![trkNodesListFromTree!.count-1]
            for trkseg in trk.elements(forName: "trkseg"){
                //print("trkseg")
                for trkpt in trkseg.elements(forName: "trkpt"){
                    let nodeLat = Double(trkpt.attribute(forName: "lat")!.stringValue!)!
                    let nodeLon = Double(trkpt.attribute(forName: "lon")!.stringValue!)!
                    let distanza=pow(lat-nodeLat,2)+pow(lon-nodeLon,2)
                    distanze[trkpt.index] = distanza
                }
                var min=["index":0, "distance":distanze[0]]
                for (index, distance) in distanze{
                    if distance<min["distance"]!!{
                        min["index"]=Double(index)
                        min["distance"]=Double(distance)
                    }
                }
                for _ in (backwards ? Int(min["index"]!!)+1..<trkseg.childCount : 0..<Int(min["index"]!!)){
                    trkseg.removeChild(at: (backwards ? trkseg.childCount-1 : 0))
                }
            }
        }
        return newGPX
    }

    func getAltitude(BingAPIKey: String = "")throws ->XMLDocument{
        func getPointElevation(lat: Double, lon: Double, BingApiKey: String)->Int{
            var url:URL
            let decoder = JSONDecoder()
            if BingApiKey != ""{
                url = URL(string: "https://dev.virtualearth.net/REST/v1/Elevation/List?points=\(String(lat)),\(String(lon))&key=\(BingApiKey)")!;
                struct Resource: Codable {
                    var __type: String
                    var elevations:[Int]
                    var zoomLevel:Int
                }
                struct ResourceSet: Codable {
                    var estimatedTotal: Int
                    var resources: [Resource]
                }
                struct Response: Codable{
                    var authenticationResultCode: String
                    var brandLogoUri: String
                    var copyright: String
                    var resourceSets: [ResourceSet]
                    var statusCode: Int
                    var statusDescription: String
                    var traceId: String
                }
                do{
                    let decoded = try decoder.decode(Response.self, from: String(contentsOf: url).data(using: .utf8)!)
                    return decoded.resourceSets[0].resources[0].elevations[0]
                }catch{
                    print(error)
                    return -1
                }
            }
            else{
                url = URL(string: "https://api.open-elevation.com/api/v1/lookup?locations=\(String(lat)),\(String(lon))")!
                struct DatiPunto: Codable{
                    var latitude: Double
                    var longitude: Double
                    var elevation: Int
                }
                struct Response: Codable{
                    var results: [DatiPunto]
                }
                do{
                    let decoded = try decoder.decode(Response.self, from: String(contentsOf: url).data(using: .utf8)!)
                    return decoded.results[0].elevation
                }catch{
                    return -1
                }
            }
        }
        var newGPX:XMLDocument
        do{
            newGPX=try XMLDocument(xmlString: flatten().xmlString)
        }
        catch{
            throw GPX.Errors.XmlParseFailed
        }
        if type()==GPXType.wpt{
            throw GPX.Errors.InvalidGPXType
        }
        else if type()==GPXType.trk{
            let trkNodesListFromTree = newGPX.rootElement()?.elements(forName: "trk")
            let trk = trkNodesListFromTree![trkNodesListFromTree!.count-1]
            for trkseg in trk.elements(forName: "trkseg"){
                //print("trkseg")
                for trkpt in trkseg.elements(forName: "trkpt"){
                    if trkpt.elements(forName: "ele").count == 0{
                        let eleAttr = XMLNode(kind: XMLNode.Kind.element)
                        eleAttr.name="ele"
                        eleAttr.stringValue=String(getPointElevation(lat: Double(trkpt.attribute(forName: "lat")!.stringValue!)!, lon: Double(trkpt.attribute(forName: "lon")!.stringValue!)!, BingApiKey: BingAPIKey))
                        trkpt.addChild(eleAttr)
                    }
                }
            }
        }
        return newGPX
    }
    func getEleList()throws ->[String:[Double]]{
        func deg2rad(_ alpha: Double)->Double{
            return alpha/180.0*Double.pi;
        }
        func ptsDistance(lat1:Double, lon1:Double, lat2:Double, lon2:Double)->Double{
            let R:Double = 6371; // Radius of the earth in km
            let dLat = deg2rad(lat2-lat1);  // deg2rad below
            let dLon = deg2rad(lon2-lon1);
            let a =
                sin(dLat/2.0) * sin(dLat/2.0) +
                cos(deg2rad(lat1)) * cos(deg2rad(lat2)) *
                sin(dLon/2.0) * sin(dLon/2.0)
            ;
            let c = 2 * atan2(sqrt(a), sqrt(1-a));
            let d = R * c; // Distance in km
            return d;

        }
        var elevation = [Double]();
        var distance = [Double]();
        var lastDistance:Double = 0;
        var lastLat: Double? = nil;
        var lastLon: Double?;
        var newGPX:XMLDocument
        do{
            newGPX=try XMLDocument(xmlString: flatten().xmlString)
        }
        catch{
            throw GPX.Errors.XmlParseFailed
        }
        if type()==GPXType.wpt{
            throw GPX.Errors.InvalidGPXType
        }
        else if type()==GPXType.trk{
            let trkNodesListFromTree = newGPX.rootElement()?.elements(forName: "trk")
            let trk = trkNodesListFromTree![trkNodesListFromTree!.count-1]
            for trkseg in trk.elements(forName: "trkseg"){
                //print("trkseg")
                for trkpt in trkseg.elements(forName: "trkpt"){
                    if lastLat == nil{
                        lastLat = Double(trkpt.attribute(forName: "lat")!.stringValue!)!
                    }
                    if lastLon == nil{
                        lastLon = Double(trkpt.attribute(forName: "lon")!.stringValue!)!
                    }
                    let lat = Double(trkpt.attribute(forName: "lat")!.stringValue!)!
                    let lon = Double(trkpt.attribute(forName: "lon")!.stringValue!)!
                    lastDistance += ptsDistance(lat1: lastLat!, lon1: lastLon!, lat2: lat, lon2: lon)
                    distance.append(lastDistance);
                    let elevationTags = trkpt.elements(forName: "ele")
                    if elevationTags.count >= 1{
                        elevation.append(Double(elevationTags[0].stringValue!)!)
                    }
                    else{
                        elevation.append(0)
                    }
                    lastLat = lat
                    lastLon = lon
                }
            }
        }
        return ["distance":distance, "elevation": elevation]
    }
}
