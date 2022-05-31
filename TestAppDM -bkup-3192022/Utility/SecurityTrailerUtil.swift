//
//  SecurityTrailerUtil.swift
//  TestAppDM
//
//  Created by Loey Agdan on 3/12/22.
//

import Foundation
import IDZSwiftCommonCrypto

//todo:- do singleton

class SecurityTrailerUtil {
    
    func generateSecurityTrailer(KEK: String)-> SecurityTrailer{
        
        let crypto = Crypto()
        
        //KEK
        let key = crypto.generate16ByteKey()
        let encryptedKey = crypto.generateEncryptedKey(randomKey: key, KEK: KEK)
        let encryptedHexKey = Data(encryptedKey).hexEncodedString() //use this to build KEK object
        
        //MAC
        let macBody = buildMacBody(messageHeader: "blahblahblah", request: "123455667")
        let hexKey = Data(key).hexEncodedString()
        let MAC = crypto.generateMAC(request: macBody, randomKeyHex: hexKey)
        
        
        print("MAC => \(MAC)")
        
        return SecurityTrailer()
    }
    
    //todo:- buidl mac body
    //get from json request
    func buildMacBody(messageHeader: String, request: String)-> String{
        return ""
    }
    
}
