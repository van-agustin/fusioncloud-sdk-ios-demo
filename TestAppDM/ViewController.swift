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



class ViewController: UIViewController , WebSocketDelegate, FusionCloudDelegate{
    
   
    let preferences = UserDefaults.standard
    let isSuccessfulLogin = "isLogin"
    
    /**
        Use this as data receiver...
     
            All response is received here, must do parse response or do your own logic inside
     */
    
    
    func dataReceive(response: String) {
        print("\(response)")
        parseResponse(str: response)
        timer.invalidate()
    }
    
    var receiverDelegate: FusionCloudDelegate?
    
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
    var logs: String = ""
    
    var fusionCloudConfig: FusionCloudConfig?
    
    func initConfig(){
       //config settings
        
        fusionCloudConfig = FusionCloudConfig()
        
        
        fusionCloudConfig!.serverDomain = "wss://www.cloudposintegration.io/nexodev"
        fusionCloudConfig!.kekValue = "44DACB2A22A4A752ADC1BBFFE6CEFB589451E0FFD83F8B21"
        fusionCloudConfig!.keyIdentifier = "SpecV2TestMACKey"
        fusionCloudConfig!.keyVersion = "20191122164326"
        fusionCloudConfig!.providerIdentification = "DMG"
        fusionCloudConfig!.applicationName = "EnterprisePos"
        fusionCloudConfig!.softwareVersion = "1.0.1"
        fusionCloudConfig!.certificationCode = "98cf9dfc-0db7-4a92-8b8c-b66d4d2d7169"
       
        fusionCloudConfig?.saleId =  "SALE ID"
        fusionCloudConfig?.poiId =   "POI ID"
        
        let messageHeader = MessageHeader()
            messageHeader.protocolVersion = "3.1-dmg"
            messageHeader.messageClass = "Service"
            messageHeader.messageType = "Request"
            messageHeader.saleId = fusionCloudConfig!.saleId
            messageHeader.poiId = fusionCloudConfig!.poiId
        
        fusionCloudConfig?.messageHeader = messageHeader
        
        let securityTrailer = SecurityTrailer()
            securityTrailer.contentType = "id-ct-authData"
            
            let authenticatedData = AuthenticationData()
                authenticatedData.version = "v0"
                let recipient = Recipient()
                    let KEK = KEK()
                        KEK.version = "v4"
                            
                            //inside kek
                            let kekIdentifier = KEKIdentifier()
                                kekIdentifier.keyIdentifier = fusionCloudConfig!.keyIdentifier
                                kekIdentifier.keyVersion = fusionCloudConfig!.keyVersion
                            
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
        
        fusionCloudConfig?.securityTrailer = securityTrailer
        
    }
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
        initConfig()
        socket = WebSocket(request: URLRequest(url: URL(string: fusionCloudConfig!.serverDomain!)!))
        socket.delegate = self
        socket.connect()
        self.receiverDelegate = self
        
        
    }
    
    
    
    @IBOutlet weak var txtLogs: UITextView!
    
    @IBAction func btnDoLogin(_ sender: UIButton) {
        SSlPinningManager.shared.callAnyApi(urlString: "https://www.cloudposintegration.io", isCertificatePinning: true) { (response) in
                if response.contains("successful"){
                    self.isCertPin = true
                    self.doLogin()
                }
            
        }
    }
    @IBAction func btnDoLogout(_ sender: Any) {
        //optimise login & payment before initiate
        doLogout()
        preferences.set(false, forKey: isSuccessfulLogin)
        btnPaymentBtn.isEnabled = false
        print("Logout")
    }
    
    @IBAction func btnDoPayment(_ sender: UIButton) {
        if self.preferences.bool(forKey: isSuccessfulLogin) == true {
            self.doPayment()
        }else{
            print("do login first...")
        }
    }
    
    var secondsRemaining = 90 //90 seconds as per documentation
    
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
        
        fusionCloudConfig!.messageHeader?.messageCategory = "TransactionStatus"
        fusionCloudConfig!.messageHeader?.serviceId = currentServiceId
        
        
        let transactionStatusRequest = TransactionStatusRequest()
        let messageReference = MessageReference()
            messageReference.serviceId = serviceID
            messageReference.saleID = saleId
            messageReference.poiId = poiId
            messageReference.messageCategory = "TransactionStatus"
        transactionStatusRequest.messageRef = messageReference
        
        sendMessage(message: "", requestBody: transactionStatusRequest, messageHeader: fusionCloudConfig!.messageHeader!, securityTrailer: fusionCloudConfig!.securityTrailer!, type: "TransactionStatusRequest")
    }
    
    func doLogin(){
        
        if self.isCertPin {
            
            let serviceId = crypto.randomString(length: 10)
            let dateFormat = DateFormatter()
                dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
            
            fusionCloudConfig!.messageHeader?.serviceId = serviceId
            fusionCloudConfig!.messageHeader?.messageCategory = "Login"
                
            let loginRequest = LoginRequest()
                loginRequest.dateTime = dateFormat.string(from: Date())
                loginRequest.operatorId = "sfsuper"
                loginRequest.operatorLanguage = "en"
            
                let saleSoftware = SaleSoftware()
                    saleSoftware.providerIdentification = fusionCloudConfig!.providerIdentification
                    saleSoftware.ApplicationName = fusionCloudConfig!.applicationName
                    saleSoftware.softwareVersion = fusionCloudConfig!.softwareVersion
                    saleSoftware.certificationCode = fusionCloudConfig!.certificationCode
                
                let saleTerminalData = SaleTerminalData()
                    saleTerminalData.terminalEnvironment = "Attended"
                    saleTerminalData.saleCapabilities = ["CashierStatus","CashierError","CashierInput","CustomerAssistance","PrinterReceipt"]
                
            loginRequest.saleTerminalData = saleTerminalData
            loginRequest.saleSoftware = saleSoftware
            
            timeoutStart()
            
            sendMessage(message: "", requestBody: loginRequest, messageHeader: fusionCloudConfig!.messageHeader!, securityTrailer: fusionCloudConfig!.securityTrailer!, type: "LoginRequest")
        } else {
            print("pinning required")
        }
    }
    
    func doLogout(){
        let serviceId = crypto.randomString(length: 10)
        fusionCloudConfig!.messageHeader?.messageCategory = "Logout"
        fusionCloudConfig!.messageHeader?.serviceId = serviceId
        
        let logoutRequest = LogoutRequest()
        logoutRequest.maintenanceAllowed = true
        
        sendMessage(message: "", requestBody: logoutRequest, messageHeader: fusionCloudConfig!.messageHeader!, securityTrailer: fusionCloudConfig!.securityTrailer!, type: "LogoutRequest")
    }
    
    var currentServiceId:String?
    
    func doAbort(){
        fusionCloudConfig!.messageHeader?.messageCategory = "Abort"
        fusionCloudConfig!.messageHeader?.serviceId = currentServiceId
        
        let abortRequest = AbortRequest()
        let messageReference = MessageReference()
        
            messageReference.messageCategory = "Payment"
            messageReference.serviceId = currentServiceId
            messageReference.saleID = fusionCloudConfig!.saleId
            messageReference.poiId = fusionCloudConfig!.poiId
        
        abortRequest.messageReference = messageReference
        abortRequest.abortReason = "transaction Cancel"
        
        timeoutStart()
        sendMessage(message: "", requestBody: abortRequest, messageHeader: fusionCloudConfig!.messageHeader!, securityTrailer: fusionCloudConfig!.securityTrailer!, type: "AbortRequest")
        
    }
    
    func doPayment(){
        
        let serviceId = crypto.randomString(length: 10)
            currentServiceId = serviceId
        let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
        
        fusionCloudConfig!.messageHeader?.serviceId = serviceId
        fusionCloudConfig!.messageHeader?.messageCategory = "Payment"
        
        
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
                    amountReq.requestedAmount = 5
        
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
        
        
        sendMessage(message: "", requestBody: paymentRequest, messageHeader: fusionCloudConfig!.messageHeader!, securityTrailer: fusionCloudConfig!.securityTrailer!, type: "PaymentRequest")
        timeoutStart()
    }
    
    /** Do call after sending message to Socket*/
    func timeoutStart(){
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    var timer = Timer()
    
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
           case .disconnected(let reason, let code):
               doAbort()
               isConnected = false
           case .text(let string):
               receiverDelegate?.dataReceive(response: string)
           case .binary(let data):
               break
           case .ping(_):
               break
           case .pong(_):
               break
           case .viabilityChanged(_):
               break
           case .reconnectSuggested(_):
               break
           case .cancelled:
               doAbort()
               isConnected = false
           case .error(let error):
               doAbort()
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
        
        print(fusionCloudConfig!.kekValue!)
        let request = crypto.buildRequest(kek: fusionCloudConfig!.kekValue!, request: requestBody, header: messageHeader, security: securityTrailer, type: type)
        logs.append("\n\nRequest: \(request)")
        txtLogs.text = logs
        socket.write(data: request.data(using: .utf8)!, completion: {
            }
        )
    }
    
    @IBOutlet weak var btnPaymentBtn: UIButton!
    
    func parseResponse(str: String){
        logs.append(contentsOf: "\n\n Response \(str)")
        let saleToPOIResponse = SalePOI(JSONString: str)
        let loginResponse = "\(String(describing: saleToPOIResponse?.salePOIResponse?.loginResponse?.response?.result))"
        
      /** This do the validation */
      try! crypto.validateSecurityTrailer(securityTrailer: (saleToPOIResponse!.salePOIResponse?.securityTrailer)!, kek: fusionCloudConfig!.kekValue!, raw: str)
        self.txtLogs.text = logs
        if str.contains( "LoginResponse") {
            if  saleToPOIResponse?.salePOIResponse?.loginResponse?.response?.result! == "Success"{
                self.btnPaymentBtn.isEnabled = true
                self.preferences.set(true, forKey: isSuccessfulLogin)
            }else{
                self.btnPaymentBtn.isEnabled = false
                logs.append(contentsOf: "Error Login...")
            }
        }
       
        
    }
}

