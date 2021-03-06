//
//  RwaUtilities.swift
//  rwa client
//
//  Created by Admin on 07/01/16.
//  Copyright © 2016 beryllium design. All rights reserved.
//

import Foundation
import CoreLocation
let RWA_EARTHRADIUS:Double = 6378137

class MovingAverage {
    var samples: Array<Double>
    var period = 128
    var currentSample = 127;
    var oldestSample = 0;
    var sum: Double = 0;
    
    init(period: Int = 127) {
        self.period = period
        samples = [Double](repeating: 0.0, count: 128)
    }
    
    func average(value: Double) -> Double {
        samples[currentSample] = value;
        sum = sum + samples[currentSample] - samples[oldestSample]
        let average = sum / Double(period);
        currentSample = (currentSample + 1) & 127
        oldestSample = (oldestSample + 1) & 127
        
        return average
    }
}

func degrees2radians(_ degrees:Double) ->Double
{
    return degrees * (Double.pi/180)
}

func radians2degrees(_ radians:Double) -> Double
{
    return radians * (180/Double.pi);
}

func calculateDestination(_ coordinates:CLLocationCoordinate2D, _ radius:Double, _ bearingInDegrees: Double) -> CLLocationCoordinate2D
{
    let bearing = degrees2radians(bearingInDegrees)
    let lat1 = degrees2radians(coordinates.latitude)
    let long1 = degrees2radians(coordinates.longitude)
    let delta = radius/RWA_EARTHRADIUS
    
    let lat2 = radians2degrees(asin(sin(lat1) * cos(delta) + cos(lat1) * sin(delta) * cos(bearing)));
    let long2:Double = radians2degrees(fmod( (long1 - asin(sin(bearing)*sin(delta) / cos(lat1)) + Double.pi), (2*Double.pi)) - Double.pi);
    
    //print("\(long2) \(coordinates.longitude)")
    return CLLocationCoordinate2D(latitude: lat2, longitude: long2)
}

func calculateDistance(_ p1:CLLocationCoordinate2D, p2:CLLocationCoordinate2D) -> Double
{
    let R = 6373.0
    let lat1 = degrees2radians(p1.latitude)
    let lat2 = degrees2radians(p2.latitude)
    let dlon = degrees2radians(p2.longitude-p1.longitude)
    let dlat = degrees2radians(p2.latitude-p1.latitude)
    let a = pow((sin(dlat/2)),2) + cos(lat1) * cos(lat2) * pow((sin(dlon/2)),2)
    let c = 2 * atan2( sqrt(a), sqrt(1-a) ) ;
    let d = R * c;
    return d;
}

func calculateBearing(_ p1:CLLocationCoordinate2D, p2:CLLocationCoordinate2D) -> Double
{
    let phi1 = degrees2radians(p1.latitude);
    let phi2 = degrees2radians(p2.latitude);
    let lam1 = degrees2radians(p1.longitude);
    let lam2 = degrees2radians(p2.longitude);
    
    let radians = atan2(sin(lam2-lam1)*cos(phi2),cos(phi1)*sin(phi2) - sin(phi1)*cos(phi2)*cos(lam2-lam1));
    let degrees = radians2degrees(radians);
    return (degrees+180).truncatingRemainder(dividingBy: 360);
}

func calculateBearing(_ p1:CLLocationCoordinate2D, p2:CLLocationCoordinate2D, headDirection: Double) -> Double
{
    let phi1 = degrees2radians(p1.latitude);
    let phi2 = degrees2radians(p2.latitude);
    let lam1 = degrees2radians(p1.longitude);
    let lam2 = degrees2radians(p2.longitude);
    
    let radians = atan2(sin(lam2-lam1)*cos(phi2),cos(phi1)*sin(phi2) - sin(phi1)*cos(phi2)*cos(lam2-lam1));
    var degrees = radians2degrees(radians);
    degrees -= headDirection
    degrees += 360
    return (degrees+180).truncatingRemainder(dividingBy: 360);
}

func coordinateWithinPolygon(_ p:CLLocationCoordinate2D,_ corners: [CLLocationCoordinate2D]) -> Bool
{
    var oddNodes: Bool = false
    var j:Int = corners.count-1
    
    for i in 0 ..< corners.count
    {
        if ( (corners[i].latitude < p.latitude && corners[j].latitude >= p.latitude) ||  (corners[j].latitude<p.latitude && corners[i].latitude>=p.latitude ))
        {
            if (corners[i].longitude+(p.latitude-corners[i].latitude)/(corners[j].latitude-corners[i].latitude)*(corners[j].longitude - corners[i].longitude) < p.longitude)
            {
                oddNodes = !oddNodes;
            }
        }
        j=i;
    }
    
    return oddNodes;
}



func coordinateWithinRectangle(_ p:CLLocationCoordinate2D,_ center:CLLocationCoordinate2D,_ width: Double,_ height: Double) -> Bool
{
    let testx = p.longitude
    let testy = p.latitude
    
    let w = calculateDestination(center, width/2, 90);
    let e = calculateDestination(center, width/2, 270);
    
    var nw:CLLocationCoordinate2D =  calculateDestination(w, height/2, 0) ;
    
    if(nw.longitude < 0)
    {
        nw.longitude = nw.longitude + 360;
    }
    
    var sw:CLLocationCoordinate2D = (calculateDestination(w, height/2, 180) );
    if(sw.longitude < 0)
    {
        sw.longitude = sw.longitude + 360;
    }
    
    var ne:CLLocationCoordinate2D = (calculateDestination(e, height/2, 0) );
    if(ne.longitude < 0)
    {
        ne.longitude = ne.longitude + 360;
    }
    
    var se = (calculateDestination(e, height/2, 180) );
    if(se.longitude < 0)
    {
        se.longitude = se.longitude + 360;
    }
    
    if(testx > nw.longitude && testx < ne.longitude && testy > se.latitude && testy < ne.latitude) {
        return true }
    else {
        return false }
}

func boolean2Double(_ booleanValue: Bool) -> Double
{
    if(booleanValue) {
        return 1.0 }
    else {
        return 0.0 }
}

extension String {
    func toBool() -> Bool? {
        switch self {
        case "True", "true", "yes", "1":
            return true
        case "False", "false", "no", "0":
            return false
        default:
            return nil
        }
    }
}

extension String {
    func isEmptyOrWhitespace() -> Bool
    {
        
        if(self.isEmpty || self.trimmingCharacters(in: .whitespaces).isEmpty) {
            return true
        }
        
        return false
    }
}

extension String {
    
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
}

extension String  {
    func isNumber() -> Bool
    {
        
        if( !self.isEmpty &&  self.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil ) {
            return true
        }
        return false
        
        
    }
}









