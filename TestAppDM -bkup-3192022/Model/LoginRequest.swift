//
//  LoginRequest.swift
//  TestApplication
//
//  Created by loey on 2/6/22.
//  Copyright © 2022 loey. All rights reserved.
//

import Foundation
import ObjectMapper

class LoginRequest: Mappable{
    
    var dateTime: String?
    var saleSoftware : SaleSoftware?
    var saleTerminalData : SaleTerminalData?
    var trainingModeFlag: Bool?
    
    required init?(map: Map) {}
    required init(){}
    func mapping(map: Map) {
        dateTime            <- map["DateTime"]
        saleSoftware        <- map["SaleSoftware"]
        saleTerminalData    <- map["SaleTerminalData"]
        trainingModeFlag    <- map["TrainingModeFlag"]
    }
    
}


class SaleSoftware: Mappable {
    
    var providerIdentification: String?
    var ApplicationName: String?
    var softwareVersion: String?
    var certificationCode: String?
    var componentType: String?
    
    required init(){}
    required init?(map: Map) {}
       func mapping(map: Map) {
           providerIdentification   <- map["ProviderIdentification"]
           ApplicationName          <- map["ApplicationName"]
           softwareVersion          <- map["SoftwareVersion"]
           certificationCode        <- map["CertificationCode"]
           componentType            <- map["ComponentType"]
       }
}

class SaleTerminalData: Mappable {
    
    var terminalEnvironment: String?
    var saleCapabilities: [String]?
    var saleProfile: SaleProfile?
    
    required init(){}
     required init?(map: Map) {}
     func mapping(map: Map) {
        terminalEnvironment     <- map["TerminalEnvironment"]
        saleCapabilities        <- map["SaleCapabilities"]
        saleProfile             <- map["SaleProfile"]
     }
}

class SaleProfile: Mappable {
    
    var genericProfile: String?
    var serviceProfiles: [String]?
    
    required init(){}
      required init?(map: Map) {}
      func mapping(map: Map) {
         genericProfile <- map["GenericProfile"]
         serviceProfiles <- map["ServiceProfiles"]
      }
}
