//
//  SecurityTrailer.swift
//  TestApplication
//
//  Created by loey on 1/30/22.
//  Copyright © 2022 loey. All rights reserved.
//

import Foundation
import ObjectMapper

class SecurityTrailer: Mappable{
    
    var contentData: String?
    var authenticationData: AuthenticationData?
    
    required init?(map: Map) {}
    required init(){}
    func mapping(map: Map) {
        contentData         <- map["ContentType"]
        authenticationData  <- map["AuthenticatedData"]
    }
    
}

class AuthenticationData: Mappable {
    
    var version: String?
    var recipient: Recipient?
    required init(){}
    
    required init?(map: Map) {}
    func mapping(map: Map) {
         version    <- map["AuthenticatedData"]
         recipient  <- map["Recipient"]
    }
}


class Recipient: Mappable {
    var mac: String?
    var kek: KEK?
    var macAlgorithm: MACAlgorithm?
    var encapContent: EncapsulatedContent?
    
    required init(){}
    required init?(map: Map) {}
    func mapping(map: Map) {
        mac             <- map["MAC"]
        kek             <- map["KEK"]
        macAlgorithm    <- map["MACAlgorithm"]
        encapContent    <- map["EncapsulatedContent"]
    }
}

//Security Data ===============================

class KEK : Mappable{
    
    var version:String?
    var encryptedKey: String?
    var kekIdentifier: KEKIdentifier?
    var kekAlgorithm: KeyEncryptionAlgorithm?
    
    func mapping(map: Map) {
        version         <- map["Version"]
        encryptedKey    <- map["EncryptedKey"]
        kekIdentifier   <- map["KEKIdentifier"]
        kekAlgorithm    <- map["KeyEncryptionAlgorithm"]
    }
    
    required init?(map: Map) {}
    required init(){}
}


class KEKIdentifier: Mappable{
    
    var keyIdentifier: String?
    var keyVersion: String?
    
    required init?(map: Map) {}
    required init(){}
    func mapping(map: Map) {
        keyVersion      <- map["KeyVersion"]
        keyIdentifier  <- map["KeyIdentifier"]
    }
}

class KeyEncryptionAlgorithm: Mappable{
    
    var algorithm: String?
    required init?(map: Map) {}
    required init(){}
    func mapping(map: Map) {
        algorithm   <- map["Algorithm"]
    }
}


//Security Data ===============================

class MACAlgorithm : Mappable {
    var algorithm: String?
    func mapping(map: Map) {
        algorithm   <- map["Algorithm"]
    }
    required init?(map: Map) {}
    required init(){}
}

//Security Data ===============================

class EncapsulatedContent : Mappable{
    
    var contentType: String?
    
    func mapping(map: Map) {
        contentType     <-  map["ContentType"]
    }
    
    required init?(map: Map) {}
    required init(){}
}
