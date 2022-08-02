//
//  ViewController.swift
//  TestAppDM

import UIKit
import Alamofire
import Starscream
import ObjectMapper
import IDZSwiftCommonCrypto
import SVProgressHUD
import FusionCloud

class ViewController: UIViewController , WebSocketDelegate, FusionCloudDelegate{
    
    @IBOutlet weak var btnPurchase: UIButton!
    @IBOutlet weak var btnRefund: UIButton!
    @IBOutlet weak var btnAbort: UIButton!
    @IBOutlet weak var btnTipAmount: UITextField!
    @IBOutlet weak var txtRequestedAmount: UITextField!
    @IBOutlet weak var txtPaymentResult: UILabel!
    
    @IBOutlet weak var txtPaymentUIDisplay: UILabel!
    
    @IBOutlet weak var txtLogs: UITextView!
    
    
    @IBOutlet weak var txtResultAuthorizedAmount: UITextField!
    
    @IBOutlet weak var txtResultMaskedPAN: UITextField!
    @IBOutlet weak var txtResultSurchargeAmount: UITextField!
    @IBOutlet weak var txtResultTipAmount: UITextField!
    /// ServiceId of the current request in progress
    var currentServiceId: String?
    
    func resetTimer(){
        timer.invalidate()
        secondsRemaining = 60 //reset the timer to 60 again
    }
    
    var receiverDelegate: FusionCloudDelegate?
    
    var socket: WebSocket!
    var isConnected = false
    let server = WebSocketServer()
    var isCertPin = false
    let crypto = Crypto()
    var session: Session?

    var logs: String = ""
    
    var fusionCloudConfig: FusionCloudConfig?
    
    func initConfig() {
        // Construct configuration helper
        fusionCloudConfig = FusionCloudConfig()
        fusionCloudConfig!.initConfig(
            testEnvironment: true,
            providerIdentification: "Company A",
            applicationName: "POS Retail",
            softwareVersion: "01.00.00",
            certificationCode: "98cf9dfc-0db7-4a92-8b8cb66d4d2d7169",
            saleID: "<<SaleID>>",
            poiID: "<<POIID>>",
            kekValue: "44DACB2A22A4A752ADC1BBFFE6CEFB589451E0FFD83F8B21")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initConfig()
        socket = WebSocket(request: URLRequest(url: URL(string: fusionCloudConfig!.serverDomain!)!))
        socket.delegate = self
        socket.connect()
        self.receiverDelegate = self
    }
    
    @IBAction func btnDoAbort(_ sender: Any) {
        doAbort(abortReason: "Transaction Cancel")
    }
    
    @IBAction func btnDoLogin(_ sender: UIButton) {
        SSlPinningManager.shared.callAnyApi(urlString: fusionCloudConfig?.serverDomain ?? "", isCertificatePinning: true) { (response) in DispatchQueue.main.async {
                    if response.contains("successful") {
                        self.isCertPin = true
                        self.doLogin()
                    }
                }
            }
    }
    
    @IBAction func btnDoPayment(_ sender: UIButton) {
        let requestedAmount = NSDecimalNumber(string: txtRequestedAmount.text)
        let tipAmount = NSDecimalNumber(string: txtResultTipAmount.text)
        self.doPayment(paymentType: "Normal", requestedAmount: requestedAmount, tipAmount: tipAmount)
    }
    
    @IBAction func btnDoRefund(_ sender: UIButton) {
        let requestedAmount = NSDecimalNumber(string: txtRequestedAmount.text)
        let tipAmount = NSDecimalNumber(string: txtResultTipAmount.text)
        
        self.doPayment(paymentType: "Refund", requestedAmount: requestedAmount, tipAmount: tipAmount)    }
    
    var secondsRemaining = 90 // 90 seconds as per documentation
    
    @objc func updateCounter(){
        if secondsRemaining > 0 {
            print("\(secondsRemaining) seconds.")
            secondsRemaining -= 1
        } else {
            resetTimer()
            self.doTransactionStatus()
        }
    }
    
    func doTransactionStatus() {
        
        fusionCloudConfig!.messageHeader?.messageCategory = "TransactionStatus"
        fusionCloudConfig!.messageHeader?.serviceID = UUID().uuidString
        
        let transactionStatusRequest = TransactionStatusRequest()
        let messageReference = MessageReference()
        messageReference.serviceID = currentServiceId
        messageReference.saleID = fusionCloudConfig!.saleID!
        messageReference.poiID = fusionCloudConfig!.poiID!
        messageReference.messageCategory = "Payment"
        
        transactionStatusRequest.messageReference = messageReference
        
        sendMessage(message: "", requestBody: transactionStatusRequest, messageHeader: fusionCloudConfig!.messageHeader!, securityTrailer: fusionCloudConfig!.securityTrailer!, type: "TransactionStatusRequest")
    }
    
    func doLogin() {
        
        if (!self.isCertPin) {
            print("pinning required")
            return
        }
            
        currentServiceId = UUID().uuidString
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
            
        fusionCloudConfig!.messageHeader?.serviceID = currentServiceId
        fusionCloudConfig!.messageHeader?.messageCategory = "Login"
                
        let loginRequest = LoginRequest()
            loginRequest.dateTime = Date()
            loginRequest.operatorID = "sfsuper"
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
    }
    
    func doAbort(abortReason: String) {
        fusionCloudConfig!.messageHeader?.messageCategory = "Abort"
        fusionCloudConfig!.messageHeader?.serviceID = UUID().uuidString
        
        let abortRequest = AbortRequest()
        let messageReference = MessageReference()
            messageReference.messageCategory = "Payment"
            messageReference.serviceID = currentServiceId
            messageReference.saleID = fusionCloudConfig!.saleID
            messageReference.poiID = fusionCloudConfig!.poiID
        
        abortRequest.messageReference = messageReference
        abortRequest.abortReason = abortReason
        
        timeoutStart()
        sendMessage(message: "", requestBody: abortRequest, messageHeader: fusionCloudConfig!.messageHeader!, securityTrailer: fusionCloudConfig!.securityTrailer!, type: "AbortRequest")
    }
    
    func doPayment(paymentType: String, requestedAmount: NSDecimalNumber, tipAmount: NSDecimalNumber){
        
        // Set default dialog
        txtPaymentResult.backgroundColor = UIColor.systemBackground
        txtPaymentResult.textColor = UIColor.black
        txtPaymentResult.text = ""
        txtPaymentUIDisplay.text = "PAYMENT IN PROGRESS"
        
        
        
        currentServiceId = UUID().uuidString
        fusionCloudConfig!.messageHeader?.serviceID = currentServiceId
        fusionCloudConfig!.messageHeader?.messageCategory = "Payment"
        
        let paymentRequest = PaymentRequest()
            
            let saleData = SaleData()
                saleData.tokenRequestedType = "Customer"
                saleData.saleTransactionID = SaleTransactionID(transactionID: "3000403")
        
            let paymentTransaction = PaymentTransaction()
        
                let amountsReq = AmountsReq()
                    amountsReq.currency = "AUD"
                    amountsReq.requestedAmount = requestedAmount
                    amountsReq.tipAmount = tipAmount
                    
                let saleItem1 = SaleItem()
                    saleItem1.itemID = 1
                    saleItem1.productCode = "SKU00FFDDG"
                    saleItem1.unitMeasure = "Unit"
                    saleItem1.quantity = 1
                    saleItem1.unitPrice = 42.50
                    saleItem1.productLabel = "NVIDIA GEFORCE RTX 3090"
        
                paymentTransaction.amountsReq = amountsReq
                paymentTransaction.saleItem = [saleItem1]
            
            let paymentData = PaymentData(paymentType: paymentType) // paymentType = Normal|Refund
        
        paymentRequest.saleData = saleData
        paymentRequest.paymentTransaction = paymentTransaction
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
        var request = URLRequest(url: URL(string: fusionCloudConfig!.serverDomain!)!)
                      request.timeoutInterval = 10
                      socket = WebSocket(request: request)
                      socket.delegate = self
                      socket.connect()
    }
    
    
    
    ///  Implementation of Starscream WebSocketDelegate
    /// - Parameter response: content received on the websocket
    func didReceive(event: WebSocketEvent, client: WebSocket) {
       switch event {
       case .connected(_):
           isConnected = true
       case .disconnected(_, _):
           isConnected = false
       case .text(let string):
           receiverDelegate?.dataReceive(response: string)
       case .binary(_):
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
       case .pong(_):
           break;
       case .ping(_):
           break;
       }
    }
    

    func dataReceive(response: String) {
        print("\(response)")
        parseResponse(str: response)
        resetTimer()
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
    
    func disconnectSocket() {
        if isConnected {
            socket.disconnect()
        } else {
            socket.connect()
        }
    }
    
    func sendMessage<T: Mappable>(message: String, requestBody: T, messageHeader: MessageHeader,securityTrailer: SecurityTrailer, type: String){
        
        print(fusionCloudConfig!.kekValue!)
        let request = crypto.buildRequest(kek: fusionCloudConfig!.kekValue!, request: requestBody, header: messageHeader, security: securityTrailer, type: type)
        
        appendLog(content: "\n\nRequest: \(request)")
        socket.write(data: request.data(using: .utf8)!, completion: {})
    }
    
    func parseResponse(str: String) {
        appendLog(content: "\n\n Response \(str)")
        
        let rc = SaleToPOI(JSONString: str)
        
        // validate security trailer
        try! crypto.validateSecurityTrailer(securityTrailer: (rc!.saleToPOIResponse?.securityTrailer ?? rc!.saleToPOIRequest?.securityTrailer)!, kek: fusionCloudConfig!.kekValue!, raw: str)


        // Message will be in saleToPOIRequest (for displays) or saleToPOIResponse (for all others)
        let poiResp = rc?.saleToPOIResponse
        let poiRequ = rc?.saleToPOIRequest
        let mh = poiResp?.messageheader ?? poiRequ?.messageHeader

        // Validate response
        if ((poiRequ == nil && poiResp == nil) || mh == nil ||
            mh?.messageCategory == nil) {
            appendLog(content: "Invalid response. Data == nil")
            return
        }
        
        switch(mh!.messageCategory)
        {
        case "Login":
            let r = poiResp?.loginResponse;
            if(r == nil) {
                appendLog(content: "Invalid response. Payload == nil")
                return
            }
            handleLoginResponse(messageHeader: mh!, loginResponse: r!)
            break
        case "Payment":
            let r = poiResp?.paymentResponse;
            if(r == nil) {
                appendLog(content: "Invalid response. Payload == nil")
                return
            }
            handlePaymentResponse(messageHeader: mh!, paymentResponse: r!)
            break
        case "TransactionStatus":
            let r = poiResp?.transactionStatusResponse;
            if(r == nil) {
                appendLog(content: "Invalid response. Payload == nil")
                return
            }
            handleTransactionStatusResponse(messageHeader: mh!, transactionStatusResponse: r!)
            break
        case "Display":
            let r = poiRequ?.displayRequest;
            if(r == nil) {
                appendLog(content: "Invalid response. Payload == nil")
                return
            }
            handleDisplayRequest(messageHeader: mh!, displayRequest: r!)
            break
        default:
            appendLog(content: "Unknown message type: " + mh!.messageCategory!)
        }

    }
    
    func handleLoginResponse(messageHeader: MessageHeader, loginResponse: LoginResponse) {
        var enableButtons = true
        
        if (loginResponse.response?.result != "Success") {
            enableButtons = false
            appendLog(content: "Login error")
        }
        
        self.btnPurchase.isEnabled = enableButtons
        self.btnAbort.isEnabled = enableButtons
        self.btnRefund.isEnabled = enableButtons
    }
    
    func handleDisplayRequest(messageHeader: MessageHeader, displayRequest: DisplayRequest) {
        txtPaymentUIDisplay.text = displayRequest.getCashierDisplayAsPlainText()
    }
    
    func handlePaymentResponse(messageHeader: MessageHeader, paymentResponse: PaymentResponse) {
        // Format decimal as currency
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.currencyCode = "AUD"
        numberFormatter.numberStyle = .currency

        
        let authorizedAmount = paymentResponse.paymentResult?.amountsResp?.authorizedAmount ?? 0;
        let tipAmount = paymentResponse.paymentResult?.amountsResp?.tipAmount ?? 0;
        let surchargeAmount = paymentResponse.paymentResult?.amountsResp?.surchargeAmount ?? 0;
        let maskedPAN = paymentResponse.paymentResult?.paymentInstrumentData?.cardData?.maskPan ?? "";
        let success = paymentResponse.response?.isSuccess() == true;
        
        
        if(success) {
            txtPaymentResult.backgroundColor = UIColor.systemGreen;
            txtPaymentResult.textColor = UIColor.white;
            txtPaymentResult.text = "PAYMENT SUCCESSFUL"
        }
        else {
            txtPaymentResult.backgroundColor = UIColor.systemRed;
            txtPaymentResult.textColor = UIColor.white;
            txtPaymentResult.text = "PAYMENT FAILED"
        }
        
        txtResultAuthorizedAmount.text = numberFormatter.string(from: authorizedAmount);
        txtResultTipAmount.text = numberFormatter.string(from: tipAmount);
        txtResultSurchargeAmount.text = numberFormatter.string(from: surchargeAmount);
        txtResultMaskedPAN.text = maskedPAN;
        
    }
    
    func handleTransactionStatusResponse(messageHeader: MessageHeader, transactionStatusResponse: TransactionStatusResponse) {
        // Handle transactionStatusResponse
    }
    
    func appendLog(content: String) {
        logs.append(contentsOf: Date().ISO8601Format() + " " + content + "\n\n")
        self.txtLogs.text = logs
    }
}
