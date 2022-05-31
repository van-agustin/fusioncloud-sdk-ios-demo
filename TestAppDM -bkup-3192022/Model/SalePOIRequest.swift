//
//  SalePOIRequest.swift
//  TestApplication
//
//  Created by loey on 1/30/22.
//  Copyright © 2022 loey. All rights reserved.
//

import Foundation
import ObjectMapper


class SalePOIRequest : Mappable{
    
    var messageHeader: MessageHeader?
    var loginRequest: LoginRequest?
    var securityTrailer: SecurityTrailer?
    
    required init?(map: Map) {}
    required init() {}
    func mapping(map: Map) {
        messageHeader   <- map["MessageHeader"]
        loginRequest    <- map["LoginRequest"]
        securityTrailer <- map["SecurityTrailer"]
    }
}
