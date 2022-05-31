//
//  SaleToPOILoginRequest.swift
//  TestApplication
//
//  Created by loey on 2/6/22.
//  Copyright © 2022 loey. All rights reserved.
//

import Foundation
import ObjectMapper

class SaleToPOILoginRequest: Mappable {
    var saleToPOIRequest: SalePOIRequest?
    required init?(map: Map) {}
    
    init(){
        
    }
      
    func mapping(map: Map) {
          saleToPOIRequest <- map["SaleToPOIRequest"]
    }
}
