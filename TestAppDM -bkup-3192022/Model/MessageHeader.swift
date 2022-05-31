//
//  MessageHeader.swift
//  TestApplication
//
//  Created by loey on 1/30/22.
//  Copyright © 2022 loey. All rights reserved.
//

import Foundation
import ObjectMapper

class MessageHeader : Mappable{
    
        var messageClass: String?
        var messageCategory: String?
        var messageType: String?
        var serviceId: String?
        var protocolVersion: String?
        var saleId: String?
        var poiId: String?
    
    
    required init?(map: Map) {}
    init(){}
    
     func mapping(map: Map) {
         protocolVersion        <- map["ProtocolVersion"]
         messageClass           <- map["MessageClass"]
         messageCategory        <- map["MessageCategory"]
         messageType            <- map["MessageType"]
         serviceId              <- map["ServiceID"]
         saleId                 <- map["SaleID"]
         poiId                  <- map["POIID"]
     }
    
}
