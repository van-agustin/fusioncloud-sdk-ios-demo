//
//  ViewController.swift
//  TestAppDM
//
//  Created by Loey Agdan on 2/27/22.
//


import UIKit
import Alamofire
import Starscream
import ObjectMapper

class ViewController: UIViewController , WebSocketDelegate{
    
    var socket: WebSocket!
    var isConnected = false
    let server = WebSocketServer()
    var isCertPin = false
     
     var session: Session?

    override func viewDidLoad() {
        super.viewDidLoad()
        pinSSL()
        //test mac
        //let crypto = Crypto()
        //rypto.generateSecurityTrailer()
    }

    @IBAction func btnLogin(_ sender: Any) {
        if self.isCertPin {
            //startSocketConnection()
            writeMessage(message: "")
        } else {
            print("pinning required")
        }
    }
    
    @IBAction func generateMac(_ sender: UIButton) {
        var sec = SecurityTrailerUtil()
        sec.generateSecurityTrailer(KEK: "44DACB2A22A4A752ADC1BBFFE6CEFB589451E0FFD83F8B21")
    }
    
    
    
    /** WebSocket Delegate functions */
    func startSocketConnection(){
        var request = URLRequest(url: URL(string: "wss://www.cloudposintegration.io/nexodev")!)
                      request.timeoutInterval = 10
                      socket = WebSocket(request: request)
                      socket.delegate = self
                      socket.connect()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
           switch event {
           case .connected(let headers):
               isConnected = true
               print("websocket is connected: \(headers)")
               // writeMessage(message: "")
           case .disconnected(let reason, let code):
               isConnected = false
               print("websocket is disconnected: \(reason) with code: \(code)")
           case .text(let string):
               print("Received text: \(string)")
                parseJson(str: string)
           case .binary(let data):
               print("Received data: \(data.count)")
           case .ping(_):
               break
           case .pong(_):
               break
           case .viabilityChanged(_):
               break
           case .reconnectSuggested(_):
               break
           case .cancelled:
               isConnected = false
           case .error(let error):
               isConnected = false
               handleError(error)
           }
       }
       
       func handleError(_ error: Error?) {
           if let e = error as? WSError {
               print("websocket encountered an WS-error: \(e.message)")
           } else if let e = error {
               print("websocket encountered an error: \(e.localizedDescription)")
           } else {
               print("websocket encountered an error")
           }
       }
    
        func disconnectSocket(){
            if isConnected {
                socket.disconnect()
            } else {
                socket.connect()
            }
        }
    
    func writeMessage(message: String){
        //todo:- find the writing part
        /*String MAC = Crypto.generateMAC(String.format("\"MessageHeader\":%s,\"%s%s\":%s", stps.getMessageHeader(),
         messageCategory, messageType, stps.getBody()), hexKey).toUpperCase();*/
        
        let crypto = Crypto()
        //KEK
        let key = crypto.generate16ByteKey()
        let encryptedKey = crypto.generateEncryptedKey(randomKey: key, KEK: "44DACB2A22A4A752ADC1BBFFE6CEFB589451E0FFD83F8B21")
        let encryptedHexKey = Data(encryptedKey).hexEncodedString()
        let hexKey = Data(key).hexEncodedString()
        
        //parameter
        let messageHeader = ""
        let messageCategory = "Login"
        let messageType = "Request"
        let messageBody = ""
        let requestRaw = "\"MessageHeader\":\(messageHeader), \"\(messageCategory)\(messageType)\": \(messageBody)"
        print("Request Raw : \(requestRaw)")
        //let mac = crypto.generateMAC(request:requestRaw, randomKeyHex: encryptedKey)
        let mac = crypto.generateMAC(request:requestRaw, randomKeyHex: hexKey)
        
        
        let keys = crypto.generateSecurityTrailer()
        
        //sample: working
        //EncryptedKey: 19B4FE6F8F5EE2725C7E02DD04D31D0B
        //Mac: 21347A272A992252
        
        //sample from android
        //encrypted key  29A33E8A9CAB5F56FBFBCD66674CF029
        //Mac   A1FA81301F2B3AB4
        
        var login1 = "{\"LoginRequest\":{\"DateTime\":\"2022-03-19T15:46:17+08:00\",\"OperatorLanguage\":\"en\",\"SaleSoftware\":{\"ApplicationName\":\"POS Retail\",\"CertificationCode\":\"98cf9dfc-0db7-4a92-8b8cb66d4d2d7169\",\"ProviderIdentification\":\"Company A\",\"SoftwareVersion\":\"01.00.00\"},\"SaleTerminalData\":{\"SaleCapabilities\":[\"CashierStatus\",\"CustomerAssistance\",\"PrinterReceipt\"],\"TerminalEnvironment\":\"SemiAttended\"}},\"MessageHeader\":{\"MessageCategory\":\"Login\",\"MessageClass\":\"Service\",\"MessageType\":\"Request\",\"POIID\":\"POI ID\",\"ProtocolVersion\":\"3.1-dmg\",\"SaleID\":\"SALE ID\",\"ServiceID\":\"\(crypto.serviceId)\"},\"SecurityTrailer\":{\"AuthenticatedData\":{\"Recipient\":{\"EncapsulatedContent\":{\"ContentType\":\"iddata\"},\"KEK\":{\"EncryptedKey\":\"\(keys.0)\",\"KEKIdentifier\":{\"KeyIdentifier\":\"SpecV2TestMACKey\",\"KeyVersion\":\"20191122164326.594\"},\"KeyEncryptionAlgorithm\":{\"Algorithm\":\"des-ede3-cbc\"},\"Version\":\"v4\"},\"MAC\":\"\(keys.1)\",\"MACAlgorithm\":{\"Algorithm\":\"id-retail-cbc-mac-sha-256\"}},\"Version\":\"v0\"},\"ContentType\":\"id-ctauthData\"}}"
        
        
        var sale1 = "{\"SaleToPOIRequest\":{\"MessageHeader\":{\"ProtocolVersion\":\"3.1-dmg\",\"MessageClass\":\"Service\",\"MessageCategory\":\"Login\",\"MessageType\":\"Request\",\"ServiceID\":\"6E260F6CB\",\"SaleID\":\"BlackLabelUAT1\",\"POIID\":\"BLBPOI01\"},\"LoginRequest\":{\"DateTime\":\"2021-12-09T13:17:06.851Z\",\"SaleSoftware\":{\"ProviderIdentification\":\"BlackLabel\",\"ApplicationName\":\"BlackLabel\",\"SoftwareVersion\":\"1.0.0\",\"CertificationCode\":\"0x47CD40C6C54D9A\",\"ComponentType\":\"Unknown\"},\"SaleTerminalData\":{\"TerminalEnvironment\":\"Attended\",\"SaleCapabilities\":[\"PrinterReceipt\",\"CashierStatus\",\"CashierError\"],\"SaleProfile\":{\"GenericProfile\":\"Basic\",\"ServiceProfiles\":[]}},\"TrainingModeFlag\":false},\"SecurityTrailer\":{\"ContentType\":\"id-ct-authData\",\"AuthenticatedData\":{\"Version\":\"v0\",\"Recipient\":{\"KEK\":{\"Version\":\"v4\",\"KEKIdentifier\":{\"KeyIdentifier\":\"SpecV2TestMACKey\",\"KeyVersion\":\"20191122164326.594\"},\"KeyEncryptionAlgorithm\":{\"Algorithm\":\"des-ede3-cbc\"},\"EncryptedKey\":\"19B4FE6F8F5EE2725C7E02DD04D31D0B\"},\"MACAlgorithm\":{\"Algorithm\":\"id-retail-cbc-mac-sha-256\"},\"EncapsulatedContent\":{\"ContentType\":\"id-data\"},\"MAC\":\"21347A272A992252\"}}}}}"
        
        print(login1)
        
         socket.write(string: "\(login1)", completion: {})
    }
    
    func parseJson(str: String){
        
        _ = str.data(using: .utf8)!
        
    }
    
    func randomString(length: Int) -> String {

        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
    
    func pinSSL(){
        SSlPinningManager.shared.callAnyApi(urlString: "https://www.cloudposintegration.io", isCertificatePinning: true) { (response) in
                   print("pinning => \(response)")
            // print all response html
                if response.contains("successful"){
                    self.isCertPin = true
                    self.startSocketConnection()
                }
            
        }
    }
    
}

