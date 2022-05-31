//
//  SalePOIResponse.swift
//  TestApplication
//
//  Created by loey on 1/30/22.
//  Copyright © 2022 loey. All rights reserved.
//

import Foundation
import ObjectMapper




class SalePOIResponse: Mappable {
    
    var messageheader: MessageHeader?
    
    /** for sale response - uncomment */
    /*var abortTransactionResponse: String?
    var paymentResponse: String?
    var loginResponse: String?
    var cardAquisitionResponse: String?
    var displayResponse: String?
    var inputResponse: String?
    var logoutResponse: String?
    var printResposne: String?
    var reconcillationResponse: String?
    var transactionStatusResponse: String?
    var securityTrailer: SecurityTrailer? */
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        messageheader <- map["MessageHeader"]
    }
    
}
