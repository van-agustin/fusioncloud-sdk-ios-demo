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
import IDZSwiftCommonCrypto
import SVProgressHUD
import FusionCloud

class ViewController: UIViewController , WebSocketDelegate{
    
    var socket: WebSocket!
    var isConnected = false
    let server = WebSocketServer()
    var isCertPin = false
    let crypto = Crypto()
    var session: Session?

    /** Configuration variable  */
    
    var serverDomain:String?
    var kekValue:String?
    var keyIdentifier:String?
    var keyVersion: String?
    var providerIdentification: String?
    var applicationName: String?
    var softwareVersion: String?
    var certificationCode: String?
    
    var saleId:String?
    var poiId: String?
    
    func initConfig(){
       //config settings
       serverDomain = "wss://www.cloudposintegration.io/nexodev"
       kekValue = "44DACB2A22A4A752ADC1BBFFE6CEFB589451E0FFD83F8B21"
       keyIdentifier = "SpecV2TestMACKey"
       keyVersion = "20191122164326"
       providerIdentification = "DMG"
       applicationName = "EnterprisePos"
       softwareVersion = "1.0.1"
       certificationCode = "98cf9dfc-0db7-4a92-8b8c-b66d4d2d7169"
        
       //id setting
       saleId =  "BlackLabelUAT1"
       poiId =   "BLBPOI01"
        
    }
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        initConfig()
        socket = WebSocket(request: URLRequest(url: URL(string: self.serverDomain!)!))
        socket.delegate = self
        socket.connect()
       
        SSlPinningManager.shared.callAnyApi(urlString: "https://www.cloudposintegration.io", isCertificatePinning: true) { (response) in
                if response.contains("successful"){
                    self.isCertPin = true
                    self.doLogin()
                }
            
        }

        
    }
    
    var secondsRemaining = 60
    
    @objc func updateCounter(){
        if secondsRemaining > 0 {
            print("\(secondsRemaining) seconds.")
            secondsRemaining -= 1
        } else {
            timer.invalidate()
            self.doTransactionStatus(serviceID: currentServiceId!)
        }
    }
    
    func doTransactionStatus(serviceID: String){
        
        let messageHeader = MessageHeader()
            messageHeader.protocolVersion = "3.1"
            messageHeader.messageClass = "Service"
            messageHeader.messageCategory = "TransactionStatus"
            messageHeader.messageType = "Request"
            messageHeader.serviceId = currentServiceId
            messageHeader.saleId = saleId
            messageHeader.poiId = poiId
        
        let transactionStatusRequest = TransactionStatusRequest()
        let messageReference = MessageReference()
            messageReference.serviceId = serviceID
            messageReference.saleID = saleId
            messageReference.poiId = poiId
            messageReference.messageCategory = "TransactionStatus"
        
        transactionStatusRequest.messageRef = messageReference
        let securityTrailer = SecurityTrailer()
            securityTrailer.contentType = "id-ct-authData"
            
            let authenticatedData = AuthenticationData()
                authenticatedData.version = "v0"
                let recipient = Recipient()
                    let KEK = KEK()
                        KEK.version = "v4"
                            
                            //inside kek
                            let kekIdentifier = KEKIdentifier()
                                kekIdentifier.keyIdentifier = keyIdentifier
                                kekIdentifier.keyVersion = keyVersion
                            
                            let keyEncryptionAlgorithm = KeyEncryptionAlgorithm()
                                keyEncryptionAlgorithm.algorithm = "des-ede3-cbc"
            
                        KEK.kekIdentifier = kekIdentifier
                        KEK.kekAlgorithm = keyEncryptionAlgorithm
                        KEK.encryptedKey = ""//encryptedString
                        
                    //inside receipient
                    let macAlgorithm = MACAlgorithm()
                        macAlgorithm.algorithm = "id-retail-cbc-mac-sha-256"
                    
                    let encapsulatedContent = EncapsulatedContent()
                        encapsulatedContent.contentType = "id-data"
            
                recipient.kek = KEK
                recipient.macAlgorithm = macAlgorithm
                recipient.encapContent = encapsulatedContent
                recipient.mac = ""//MAC
            
            authenticatedData.recipient = recipient
        
        securityTrailer.authenticationData = authenticatedData
        sendMessage(message: "", requestBody: transactionStatusRequest, messageHeader: messageHeader, securityTrailer: securityTrailer, type: "TransactionStatusRequest")
    }
    
    func doLogin(){
        
        if self.isCertPin {
            
            let serviceId = crypto.randomString(length: 10)
            let dateFormat = DateFormatter()
                dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
            
            let messageHeader = MessageHeader()
                messageHeader.protocolVersion = "3.1"
                messageHeader.messageClass = "Service"
                messageHeader.messageCategory = "Login"
                messageHeader.messageType = "Request"
                messageHeader.serviceId = serviceId
                messageHeader.saleId = saleId
                messageHeader.poiId = poiId
                
            let loginRequest = LoginRequest()
                loginRequest.dateTime = dateFormat.string(from: Date())
                loginRequest.operatorId = "sfsuper"
                loginRequest.operatorLanguage = "en"
            
                let saleSoftware = SaleSoftware()
                    saleSoftware.providerIdentification = providerIdentification
                    saleSoftware.ApplicationName = applicationName
                    saleSoftware.softwareVersion = softwareVersion
                    saleSoftware.certificationCode = certificationCode
                
                let saleTerminalData = SaleTerminalData()
                    saleTerminalData.terminalEnvironment = "Attended"
                    saleTerminalData.saleCapabilities = ["CashierStatus","CashierError","CashierInput","CustomerAssistance","PrinterReceipt"]
                
            loginRequest.saleTerminalData = saleTerminalData
            loginRequest.saleSoftware = saleSoftware
            
            let securityTrailer = SecurityTrailer()
                securityTrailer.contentType = "id-ct-authData"
                
                let authenticatedData = AuthenticationData()
                    authenticatedData.version = "v0"
                    let recipient = Recipient()
                        let KEK = KEK()
                            KEK.version = "v4"
                                
                                //inside kek
                                let kekIdentifier = KEKIdentifier()
                                    kekIdentifier.keyIdentifier = keyIdentifier
                                    kekIdentifier.keyVersion = keyVersion
                                
                                let keyEncryptionAlgorithm = KeyEncryptionAlgorithm()
                                    keyEncryptionAlgorithm.algorithm = "des-ede3-cbc"
                
                            KEK.kekIdentifier = kekIdentifier
                            KEK.kekAlgorithm = keyEncryptionAlgorithm
                            KEK.encryptedKey = ""//encryptedString
                            
                        //inside receipient
                        let macAlgorithm = MACAlgorithm()
                            macAlgorithm.algorithm = "id-retail-cbc-mac-sha-256"
                        
                        let encapsulatedContent = EncapsulatedContent()
                            encapsulatedContent.contentType = "id-data"
                
                    recipient.kek = KEK
                    recipient.macAlgorithm = macAlgorithm
                    recipient.encapContent = encapsulatedContent
                    recipient.mac = ""//MAC
                
                authenticatedData.recipient = recipient
            
            securityTrailer.authenticationData = authenticatedData
            
            sendMessage(message: "", requestBody: loginRequest, messageHeader: messageHeader, securityTrailer: securityTrailer, type: "LoginRequest")
        } else {
            print("pinning required")
        }
    }
    
    var currentServiceId:String?
    
    func doPayment(){
        
        let serviceId = crypto.randomString(length: 10)
            currentServiceId = serviceId
        let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        
        let messageHeader = MessageHeader()
            messageHeader.protocolVersion = "3.1"
            messageHeader.messageClass = "Service"
            messageHeader.messageCategory = "Payment"
            messageHeader.messageType = "Request"
            messageHeader.serviceId = serviceId
            messageHeader.saleId = saleId
            messageHeader.poiId = poiId
        
        
        let paymentRequest = PaymentRequest()
            
            let saleData = SaleData()
                saleData.tokenReqType = "Unknown"
                
                let saleTransID = SaleTransactionID()
                    saleTransID.timeStamp = dateFormat.string(from: Date())
                    saleTransID.transID = "30000004"
        
                saleData.saleTransID = saleTransID
        
            let paymentTransaction = PaymentTransaction()
        
                let amountReq = AmountsReq()
                    amountReq.currency = "AUD"
                    amountReq.requestedAmount = 2000
        
                let saleItem1 = SaleItem()
                    saleItem1.itemId = 1028903671
                    saleItem1.productCode = "RTX 3090"
                    saleItem1.unitMeasure = "Unit"
                    saleItem1.quantity = 1
                    saleItem1.unitPrice = 1999.99
                    saleItem1.productLabel = "NVIDIA GEFORCE"
        
                paymentTransaction.amountsReq = amountReq
                paymentTransaction.saleItem = [saleItem1]
            
            let paymentData = PaymentData()
                paymentData.paymentType = "Normal" //Refund - for refund
        
        paymentRequest.saleData = saleData
        paymentRequest.paymentTrans = paymentTransaction
        paymentRequest.paymentData  = paymentData
        
        let securityTrailer = SecurityTrailer()
            securityTrailer.contentType = "id-ct-authData"
            
            let authenticatedData = AuthenticationData()
                authenticatedData.version = "v0"
                let recipient = Recipient()
                    let KEK = KEK()
                        KEK.version = "v4"
                            
                            //inside kek
                            let kekIdentifier = KEKIdentifier()
                                kekIdentifier.keyIdentifier = keyIdentifier
                                kekIdentifier.keyVersion = keyVersion
                            
                            let keyEncryptionAlgorithm = KeyEncryptionAlgorithm()
                                keyEncryptionAlgorithm.algorithm = "des-ede3-cbc"
            
                        KEK.kekIdentifier = kekIdentifier
                        KEK.kekAlgorithm = keyEncryptionAlgorithm
                        KEK.encryptedKey = ""//encryptedString
                        
                    //inside receipient
                    let macAlgorithm = MACAlgorithm()
                        macAlgorithm.algorithm = "id-retail-cbc-mac-sha-256"
                    
                    let encapsulatedContent = EncapsulatedContent()
                        encapsulatedContent.contentType = "id-data"
            
                recipient.kek = KEK
                recipient.macAlgorithm = macAlgorithm
                recipient.encapContent = encapsulatedContent
                recipient.mac = ""//MAC
            
            authenticatedData.recipient = recipient
        
        securityTrailer.authenticationData = authenticatedData
        
        sendMessage(message: "", requestBody: paymentRequest, messageHeader: messageHeader, securityTrailer: securityTrailer, type: "PaymentRequest")
        
        //set timer 60 seconds
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    var timer = Timer()

    @IBAction func btnLogin(_ sender: Any) {
        
    }
    
    @IBAction func btnDoSale(_ sender: Any) {
        
        
    }
    
    
    /** WebSocket Delegate functions */
    func startSocketConnection(){
        var request = URLRequest(url: URL(string: serverDomain!)!)
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
           case .disconnected(let reason, let code):
               isConnected = false
               print("websocket is disconnected: \(reason) with code: \(code)")
           case .text(let string):
                print("Received text: \(string)")
               
                parseResponse(str: string)
           case .binary(let data):
               print("Received data: \(data.count)")
           case .ping(_):
               print("ping")
               break
           case .pong(_):
               print("it pong")
               break
           case .viabilityChanged(_):
               break
           case .reconnectSuggested(_):
               break
           case .cancelled:
               print("it cancelled!")
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
    
    func sendMessage<T: Mappable>(message: String, requestBody: T, messageHeader: MessageHeader,securityTrailer: SecurityTrailer, type: String){
        let request = crypto.buildRequest(kek: kekValue!, request: requestBody, header: messageHeader, security: securityTrailer, type: type)
        print(request)
        socket.write(data: request.data(using: .utf8)!, completion: {
            print("write send...")})
    }
    
    func parseResponse(str: String){
        
        let saleToPOIResponse = SalePOI(JSONString: str)
        let loginResponse = "\(String(describing: saleToPOIResponse?.salePOIResponse?.loginResponse?.response?.result))"
        
        print("Header Protocol: \(String(describing: saleToPOIResponse?.salePOIResponse?.messageheader?.protocolVersion))")
        print("Response : \(String(describing: saleToPOIResponse?.salePOIResponse?.loginResponse?.response?.result))")
        
        print("printObject => \(saleToPOIResponse?.toJSONString(prettyPrint: true))")
        
      /** This do the validation */
      try! crypto.validateSecurityTrailer(securityTrailer: (saleToPOIResponse!.salePOIResponse?.securityTrailer)!, kek: kekValue!, raw: str)
        
      print(saleToPOIResponse?.toJSONString(prettyPrint: true)!)
        
        if str.contains( "LoginResponse") {
            self.doPayment()
        }
    }
}

