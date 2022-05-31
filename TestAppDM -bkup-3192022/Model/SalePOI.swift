//
//  SalePOI.swift
//  TestApplication
//
//  Created by loey on 1/30/22.
//  Copyright © 2022 loey. All rights reserved.
//

import Foundation
import ObjectMapper

class SalePOI : Mappable{
   
    var salePOIResponse: SalePOIResponse?
    
    required init?(map: Map) {}
    func mapping(map: Map) {
          salePOIResponse <- map["SaleToPOIResponse"]
    }
}
