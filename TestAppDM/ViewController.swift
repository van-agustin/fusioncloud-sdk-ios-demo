//
//  ViewController.swift
//  TestAppDM

import UIKit
import Alamofire
import Starscream
import ObjectMapper
import SVProgressHUD
import FusionCloud
import WebKit

class ViewController: UIViewController , WebSocketDelegate, FusionCloudDelegate{

    @IBOutlet weak var vwRequest: UIView!
    @IBOutlet weak var vwLoading: UIView!
    @IBOutlet weak var vwResult: UIView!
    
    @IBOutlet weak var wvReceipt: WKWebView!
    @IBOutlet weak var btnPurchase: UIButton!
    @IBOutlet weak var btnRefund: UIButton!
    @IBOutlet weak var btnAbort: UIButton!
    
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnClear: UIButton!
    @IBOutlet weak var btnBottom: UIButton!
    @IBOutlet weak var btnSelectAll: UIButton!
    
    @IBOutlet weak var txtRequestedAmount: UITextField!
    @IBOutlet weak var txtTipAmount: UITextField!
    @IBOutlet weak var txtPaymentResult: UILabel!
    
    @IBOutlet weak var txtProductCode: UITextField!
    @IBOutlet weak var txtPaymentUIDisplay: UILabel!
    
    @IBOutlet weak var txtErrorCondition: UILabel!
    @IBOutlet weak var txtLogs: UITextView!
    
    
    @IBOutlet weak var txtResultAuthorizedAmount: UITextField!
    @IBOutlet weak var txtResultSurchargeAmount: UITextField!
    @IBOutlet weak var txtResultTipAmount: UITextField!
    @IBOutlet weak var txtResultMaskedPAN: UITextField!
    @IBOutlet weak var txtCardAccount: UITextField!
    @IBOutlet weak var txtPaymentBrand: UITextField!
    @IBOutlet weak var txtEntryMode: UITextField!
    @IBOutlet weak var txtPaymentType: UITextField!
    @IBOutlet weak var txtTransactionID: UITextField!
    @IBOutlet weak var txtApprovalCode: UITextField!
    
    
    @IBOutlet weak var txtTimer: UILabel!
    @IBOutlet weak var imgLoading: UIActivityIndicatorView!
    
    var productCode: String?
    var inErrorHandling = false
    var isIncorrectServiceID = false
    var inLogin = false
    
    /// ServiceId of the current request in progress
    var currentPaymentServiceId: String?
    var currentTransactionServiceID: String?
    var currentTransaction: String?
    var incorrectValue: String?
    var warningMessage: String?
//    var paymentBrands = [String]()
    
    var timoutLimit = 0
    var ErrorHandlingLimit = 0
    var secondsRemaining = 0
    
    //for testing
    var transactionStatusRequestCount = 0
    
    
    func clearResults(){
        txtResultAuthorizedAmount.text = ""
        txtResultTipAmount.text = ""
        txtResultSurchargeAmount.text = ""
        txtResultMaskedPAN.text = ""
        txtCardAccount.text = ""
        txtPaymentBrand.text = ""
        txtEntryMode.text = ""
        txtPaymentType.text = ""
        txtTransactionID.text = ""
        
        txtErrorCondition.text = ""
        inErrorHandling=false
    }
    
    func initValues(){
        timoutLimit = 60// 60 seconds as per documentation
        ErrorHandlingLimit = 90 //90 seconds
        
        inLogin = false
        //initValues = false
        isIncorrectServiceID = false
        txtTimer.text = "0"
        transactionStatusRequestCount = 0
        warningMessage = nil
        
        txtErrorCondition.textColor = UIColor.systemYellow
    }
    
    
    var timer = Timer()
    
    /** Do call after sending message to Socket*/
    func timeoutStart(){
//        timer = Timer()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
        imgLoading.isHidden=false
        imgLoading.startAnimating()
    }
    
    @objc func updateCounter(){
        if secondsRemaining > 0 {
            txtTimer.text=String(secondsRemaining)
            
            if(isIncorrectServiceID){
                if inErrorHandling {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)){
                        self.doTransactionStatus()
                    }
                }
                
                print("Received an incorrect service ID in transaction: \(String(describing: currentTransaction ?? "NULL"))")
                print("\(currentTransactionServiceID ?? "NULL") -- Current Transaction Service ID")
                print("\(incorrectValue ?? "NULL") -- Incorrect Service ID")
                logErrorMessage(errorMessage: "incorrect service ID -- ignored")
                isIncorrectServiceID=false
            }
            secondsRemaining -= 1
        }
        else if !inLogin {
            if (!inErrorHandling) {
                resetTimer()
                doAbort(abortReason: "Transaction Cancel")
                self.doTransactionStatus()
            }
            else{
                print("transactionStatusRequestCount: \(transactionStatusRequestCount)")
                stopTimer()
                txtPaymentUIDisplay.text="" //update this
                txtPaymentResult.backgroundColor = UIColor.systemRed;
                txtPaymentResult.textColor = UIColor.white;
                txtPaymentResult.text = "TRANSACTION TIMEOUT"
                txtErrorCondition.text = "Please check pinpad transaction history"
                btnAbort.isHidden=true
                btnPurchase.isEnabled=true
                btnRefund.isEnabled=true
                btnLogin.isEnabled=true
            }
            
        }
        else if inLogin {
            print("inLogin")
            stopTimer()
        }
    }
    
    
    func resetTimer(){
        stopTimer()
        
        secondsRemaining = ErrorHandlingLimit //reset the timer to 60 again
        timeoutStart()
    }
    
    func stopTimer(){
        
        self.timer.invalidate()
        imgLoading.stopAnimating()
        imgLoading.isHidden=true
        
        initValues()
    }
    
    var receiverDelegate: FusionCloudDelegate?
    
    var socket: WebSocket!
    var isConnected = true
    let server = WebSocketServer()
    var isCertPin = false
    let crypto = Crypto()
    var session: Session?
    
    let fusionCloudConfig = FusionCloudConfig(testEnvironmentui: true)
//    let fusionCloudConfig = FusionCloudConfig(testEnvironmentui: false) //FOR PRODUCTION ONLY
    var fusionClient = FusionClient()
    
    var logs: String = ""

    public func initConfig() {
        // Construct configurabation helper
        fusionCloudConfig.saleID = "<<SALE ID>>"
        fusionCloudConfig.poiID = "<<POI ID>>"
        self.fusionClient = FusionClient(fusionCloudConfig: fusionCloudConfig)
        socket = fusionClient.socket
        
    }
    
    func showReceipt(doShow: Bool){
        vwLoading.isHidden = doShow
        wvReceipt.isHidden = !doShow
    }
    
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtLogs.isEditable = false
        
        initConfig()
        socket.delegate = self
        socket.connect()
        self.receiverDelegate = self
        
        btnAbort.isHidden=true
        imgLoading.isHidden=true;
        showReceipt(doShow: false)
    }
    
    @IBAction func btnSelectAll(_ sender: Any) {
        txtLogs.selectAll(self)
    }
    
    @IBAction func btnClear(_ sender: Any) {
        self.txtLogs.text=""
        self.logs = ""
    }
    
    
    @IBAction func btnBottom(_ sender: Any) {
        let textCount: Int = txtLogs.text.count
        guard textCount >= 1 else { return }
        txtLogs.scrollRangeToVisible(NSRange(location: textCount - 1, length: 1))
    }
    
    @IBAction func btnDoAbort(_ sender: Any) {
        currentTransaction="Abort"
        btnAbort.isEnabled=false
        btnLogin.isEnabled=false
        btnPurchase.isEnabled=false
        btnRefund.isEnabled=false
        if !inErrorHandling{
            txtPaymentUIDisplay.text = "CANCELLING TRANSACTION"
            doAbort(abortReason: "Transaction Cancel")
        }
        else {
            secondsRemaining=0
        }
        
    }
    
    @IBAction func btnDoLogin(_ sender: UIButton) {
        btnLogin.isEnabled = false
        SSlPinningManager.shared.callAnyApi(urlString: fusionCloudConfig.serverDomain ?? "",
                                            isCertificatePinning: true,
                                            testEnvironment: fusionCloudConfig.testEnvironment ){
            (response) in DispatchQueue.main.async {
                if response.contains("successful") {
                    self.isCertPin = true
                    self.doLogin()
                    }
                }
            }
    }
    
    @IBAction func btnDoPayment(_ sender: UIButton) {
        initValues()
        showReceipt(doShow: false)
        wvReceipt.loadHTMLString("", baseURL: Bundle.main.bundleURL)
        btnAbort.isEnabled = true
        currentTransaction = "Payment"
//        txtErrorCondition.text = ""
        clearResults()
        let requestedAmount = NSDecimalNumber(string: txtRequestedAmount.text)
        let tipAmount = NSDecimalNumber(string: txtTipAmount.text)
        self.doPayment(paymentType: "Normal", requestedAmount: requestedAmount, tipAmount: tipAmount)
    }
    
    @IBAction func btnDoRefund(_ sender: UIButton) {
        currentTransaction = "Payment"
        //wvReceipt.loadHTMLString("", baseURL: Bundle.main.bundleURL)
        let requestedAmount = NSDecimalNumber(string: txtRequestedAmount.text)
        let tipAmount = NSDecimalNumber(string: txtResultTipAmount.text)
        clearResults()
        self.doPayment(paymentType: "Refund", requestedAmount: requestedAmount, tipAmount: tipAmount)
        
    }
    
    func doTransactionStatus() {
        currentTransaction = "TransactionStatus"
        transactionStatusRequestCount+=1
        showReceipt(doShow: false)
        if (secondsRemaining > 0)
        {
            inErrorHandling = true
            txtPaymentUIDisplay.text = "CHECKING TRANSACTION STATUS"
            
            btnLogin.isEnabled = false
            btnPurchase.isEnabled = false
            btnRefund.isEnabled = false
            //btnAbort.isHidden=true //still showing
            
            currentTransactionServiceID = UUID().uuidString
            fusionClient.messageHeader?.messageCategory = "TransactionStatus"
            fusionClient.messageHeader?.serviceID =  currentTransactionServiceID
            
            let transactionStatusRequest = TransactionStatusRequest()
            let messageReference = MessageReference()
            messageReference.serviceID = currentPaymentServiceId
            messageReference.saleID = fusionCloudConfig.saleID
            messageReference.poiID = fusionCloudConfig.poiID
            messageReference.messageCategory = "Payment"
            
            transactionStatusRequest.messageReference = messageReference
            //add catch here if sendmessage fails
            fusionClient.sendMessage(requestBody: transactionStatusRequest, type: "TransactionStatusRequest")
        }
    }
    
    func doLogin() {
        currentTransaction = "Login"
        if (!self.isCertPin) {
            print("pinning required")
            return
        }
        clearResults()
        currentTransactionServiceID = UUID().uuidString
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
            
        fusionClient.messageHeader?.serviceID = currentTransactionServiceID
        fusionClient.messageHeader?.messageCategory = "Login"
                
        let loginRequest = LoginRequest()
            loginRequest.dateTime = Date()
            loginRequest.operatorID = "sfsuper"
            loginRequest.operatorLanguage = "en"
            
        let saleSoftware = SaleSoftware()
            saleSoftware.providerIdentification = fusionCloudConfig.providerIdentification
            saleSoftware.ApplicationName = fusionCloudConfig.applicationName
            saleSoftware.softwareVersion = fusionCloudConfig.softwareVersion
            saleSoftware.certificationCode = fusionCloudConfig .certificationCode
                
        let saleTerminalData = SaleTerminalData()
            saleTerminalData.terminalEnvironment = "Attended"
            saleTerminalData.saleCapabilities = ["CashierStatus","CashierError","CashierInput","CustomerAssistance","PrinterReceipt"]
                
        loginRequest.saleTerminalData = saleTerminalData
        loginRequest.saleSoftware = saleSoftware
        
        inLogin = true
        timeoutStart()
        fusionClient.sendMessage(requestBody: loginRequest, type: "LoginRequest")
    }
    
    func doAbort(abortReason: String) {
        fusionClient.messageHeader?.messageCategory = "Abort"
        fusionClient.messageHeader?.serviceID = UUID().uuidString
        
        let abortRequest = AbortRequest()
        let messageReference = MessageReference()
            messageReference.messageCategory = "Payment"
            messageReference.serviceID = currentPaymentServiceId
            messageReference.saleID = fusionCloudConfig.saleID
            messageReference.poiID = fusionCloudConfig.poiID
        
        abortRequest.messageReference = messageReference
        abortRequest.abortReason = abortReason
        
        //timeoutStart()
        fusionClient.sendMessage(requestBody: abortRequest, type: "AbortRequest")
    }
    
    func doPayment(paymentType: String, requestedAmount: NSDecimalNumber, tipAmount: NSDecimalNumber){
        
        // Set default dialog
        txtPaymentResult.backgroundColor = UIColor.systemBackground
        txtPaymentResult.textColor = UIColor.black
        txtPaymentResult.text = ""
        txtErrorCondition.text = ""
        txtPaymentUIDisplay.text = "PAYMENT IN PROGRESS"
        
        //Disable other buttons, show abort
        btnAbort.isHidden=false
        btnPurchase.isEnabled=false
        btnRefund.isEnabled=false
        btnLogin.isEnabled=false
        
        currentPaymentServiceId = UUID().uuidString
        currentTransactionServiceID = currentPaymentServiceId
        fusionClient.messageHeader?.serviceID = currentPaymentServiceId
        fusionClient.messageHeader?.messageCategory = "Payment"
        var productCode = txtProductCode.text
        if (productCode?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
            productCode = "productCode"
        }
        
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
                    saleItem1.productCode = productCode
                    saleItem1.unitOfMeasure = "Unit"
                    saleItem1.quantity = 1
                    saleItem1.unitPrice = 42.50
                    saleItem1.productLabel = "NVIDIA GEFORCE RTX 3090"
        
                paymentTransaction.amountsReq = amountsReq
                paymentTransaction.saleItem = [saleItem1]
            
            let paymentData = PaymentData(paymentType: paymentType) // paymentType = Normal|Refund
        
        paymentRequest.saleData = saleData
        paymentRequest.paymentTransaction = paymentTransaction
        paymentRequest.paymentData  = paymentData
        
        fusionClient.sendMessage(requestBody: paymentRequest, type: "PaymentRequest")
        

        secondsRemaining=timoutLimit
        timeoutStart()
    }
    
//    /** WebSocket Delegate functions */
//    func startSocketConnection(){
//        var request = URLRequest(url: URL(string: fusionCloudConfig.serverDomain!)!)
//                      request.timeoutInterval = 10
//                      socket = WebSocket(request: request)
//                      socket.delegate = self
//                      socket.connect()ß
//    }
//
    
    
    ///  Implementation of Starscream WebSocketDelegate
    /// - Parameter response: content received on the websocket
    func didReceive(event: WebSocketEvent, client: WebSocket) {
       switch event {
       case .connected(_):
           isConnected = true
           //logErrorMessage (errorMessage: "Connected!")
       case .disconnected(_, _):
           isConnected = false
       case .text(let string):
           receiverDelegate?.dataReceive(response: string)
           isConnected=true
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
           print("here")
           handleError(error)
       case .pong(_):
           break;
       case .ping(_):
           break;
       }
        // Detect if websocket is disconnected
        if !isConnected{
            if !inErrorHandling{
                logErrorMessage (errorMessage: "Connection lost! Reconnecting...")
                secondsRemaining = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [self] in
                if self.secondsRemaining>0{
                    initConfig()
                    socket.delegate = self
                    socket.connect()
                    self.doTransactionStatus()
                }
            }
        }
    }
    

    func dataReceive(response: String) {
        print("rx---")
        //print("\(response)")
        parseResponse(str: response)
    }
    
    func handleError(_ error: Error?) {
       if let e = error as? WSError {
           print("websocket encountered an WS-error --check: \(e.message)")
       } else if let e = error {
           print("websocket encountered an error--check: \(e.localizedDescription)")
       } else {
           print("websocket encountered an error--check")
       }
    }
    
    func disconnectSocket() {
        if isConnected {
            socket.disconnect()
        } else {
            socket.connect()
        }
    }

    
    func parseResponse(str: String) {
        let strFormatted = str.data(using: .utf8)!.prettyPrintedJSONString!
        appendLog(content: "\n\n Response \(strFormatted)")
        
        let rc = SaleToPOI(JSONString: str)
        do{
            // validate security trailer
            try crypto.validateSecurityTrailer(securityTrailer: (rc!.saleToPOIResponse?.securityTrailer ?? rc!.saleToPOIRequest?.securityTrailer)!, kek: fusionCloudConfig.kekValue!, raw: str)


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
            let acceptableResponse = [mh!.messageCategory, currentTransaction, "Display", "Abort"]
            if(!acceptableResponse.contains(mh!.messageCategory))
            {
                print("ignoring response")
                return
            }
            if(currentTransaction == "Abort" && mh!.messageCategory == "Display"){
                print("ignoring display queue")
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
                if inLogin{
                    handleLoginResponse(messageHeader: mh!, loginResponse: r!)
                }
               
                break
            case "Payment":
                if !inErrorHandling && secondsRemaining > 0 {
                    let r = poiResp?.paymentResponse;
                    if(r == nil) {
                        appendLog(content: "Invalid response. Payload == nil")
                        return
                    }
                    
                    handlePaymentResponse(messageHeader: mh!, paymentResponse: r!)
                }
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
        catch is MacValidation {
            print("Incorrect MAC")
            logErrorMessage(errorMessage: "Incorrect MAC --ignored")
        }
        catch {
            print("OTHER ERROR")
            logErrorMessage(errorMessage: "Other parsing error --ignored")
        }

    }
    
    func handleLoginResponse(messageHeader: MessageHeader, loginResponse: LoginResponse) {
        var enableButtons = true
        showReceipt(doShow: false)
        if(messageHeader.serviceID != currentTransactionServiceID){
            incorrectValue = messageHeader.serviceID
            isIncorrectServiceID = true
            inLogin=true
            return
        }
        if (loginResponse.response?.result != "Success") {
            enableButtons = false
            appendLog(content: "Login error")
        }
        else{
            txtPaymentUIDisplay.text = "LOGIN SUCCESSFUL"
            self.btnPurchase.isEnabled = enableButtons
            self.btnAbort.isEnabled = enableButtons
            self.btnRefund.isEnabled = enableButtons
        }
        btnLogin.isEnabled = true
        stopTimer()
    }
    
    func handleDisplayRequest(messageHeader: MessageHeader, displayRequest: DisplayRequest) {
        showReceipt(doShow: false)
        if(messageHeader.serviceID != currentTransactionServiceID){
            print("ignoring incorrect service id display request")
            incorrectValue = messageHeader.serviceID
            isIncorrectServiceID=true
            return
        }
        txtPaymentUIDisplay.text = displayRequest.getCashierDisplayAsPlainText()
        if (!inErrorHandling) {
            stopTimer()
            secondsRemaining = timoutLimit
            timeoutStart()
        }
       
    }
    
    func handlePaymentResponse(messageHeader: MessageHeader, paymentResponse: PaymentResponse) {
        if(messageHeader.serviceID != currentPaymentServiceId){
            incorrectValue = messageHeader.serviceID
            isIncorrectServiceID=true
            return
        }
        showReceipt(doShow: true)
        // Format decimal as currency
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.currencyCode = "AUD"
        numberFormatter.numberStyle = .currency
        
        let paymentResult = paymentResponse.paymentResult ?? nil
        let cardData = paymentResponse.paymentResult?.paymentInstrumentData?.cardData ?? nil
        
        let authorizedAmount = paymentResponse.paymentResult?.amountsResp?.authorizedAmount ?? 0;
        let tipAmount = paymentResponse.paymentResult?.amountsResp?.tipAmount ?? 0;
        let surchargeAmount = paymentResponse.paymentResult?.amountsResp?.surchargeAmount ?? 0;
        let maskedPAN = paymentResponse.paymentResult?.paymentInstrumentData?.cardData?.maskedPan ?? "";
        let success = paymentResponse.response?.isSuccess() == true;
        let cardAccount = paymentResult?.paymentInstrumentData?.cardData?.getAccount()
        let paymentBrand = cardData?.getPaymentBrand()
        let entryMode = cardData?.entryMode ?? "not specified"
        let paymentInstrumentType = paymentResult?.paymentInstrumentData?.paymentInstrumentType ?? "not specified"
        let transactionId = paymentResult?.paymentAcquirerData?.acquirerTransactionID?.transactionID ?? "not specified"
        let approvalCode = paymentResult?.paymentAcquirerData?.approvalCode ?? "not specified"
        
        let receiptHTML = (paymentResponse.paymentReceipt?[0].getReceiptAsPlainText())
        
        
        if(success) {
            //Internal validation for masked pan + payment brand validation
            let isValidCard = FusionCloud.isCardValid(cardNumber: maskedPAN, cardBrand: paymentBrand ?? "unknown")
            if !isValidCard.isValid{
                print(Date().ISO8601Format() + "\n\n WARNING: \(isValidCard.errorMessage)")
            }
            txtPaymentResult.backgroundColor = UIColor.systemGreen;
            txtPaymentResult.textColor = UIColor.white;
            txtPaymentResult.text = "PAYMENT SUCCESSFUL"
            txtPaymentUIDisplay.text = ""
            
        }
        else if(paymentResponse.response?.errorCondition=="Cancel"){
            txtPaymentResult.backgroundColor = UIColor.systemYellow;
            txtPaymentResult.textColor = UIColor.white;
            txtPaymentResult.text = "PAYMENT CANCELLED"
            txtPaymentUIDisplay.text=""
            txtErrorCondition.text = paymentResponse.response?.errorCondition
        }
        else {
            txtPaymentResult.backgroundColor = UIColor.systemRed;
            txtPaymentResult.textColor = UIColor.white;
            txtPaymentResult.text = "PAYMENT FAILED"
            txtPaymentUIDisplay.text=""
            txtErrorCondition.text = paymentResponse.response?.errorCondition
        }
        
        txtResultAuthorizedAmount.text = numberFormatter.string(from: authorizedAmount);
        txtResultTipAmount.text = numberFormatter.string(from: tipAmount);
        txtResultSurchargeAmount.text = numberFormatter.string(from: surchargeAmount);
        txtResultMaskedPAN.text = maskedPAN;
        txtCardAccount.text = cardAccount
        txtPaymentBrand.text = paymentBrand
        txtEntryMode.text = entryMode
        txtPaymentType.text = paymentInstrumentType
        txtTransactionID.text = transactionId
        txtApprovalCode.text = approvalCode
        
        wvReceipt.loadHTMLString(receiptHTML ?? "", baseURL: Bundle.main.bundleURL)
        
        //Enable other buttons, hide abort
        btnAbort.isHidden=true
        btnPurchase.isEnabled=true
        btnRefund.isEnabled=true
        btnLogin.isEnabled=true
        
        stopTimer()

    }
    
    func handleTransactionStatusResponse(messageHeader: MessageHeader, transactionStatusResponse: TransactionStatusResponse) {
        if((messageHeader.serviceID != currentTransactionServiceID)){
            incorrectValue = messageHeader.serviceID
            isIncorrectServiceID=true
            return
        }
        
        let pResponse = transactionStatusResponse.repeatedMessageResponse?.repeatedResponseMessageBody?.paymentResponse ?? nil
        let pResult = pResponse?.paymentResult ?? nil
        let cardData = pResult?.paymentInstrumentData?.cardData ?? nil
        
        let success = transactionStatusResponse.response!.isSuccess() == true;
        let errorCondition = transactionStatusResponse.response?.errorCondition ?? pResponse?.response?.errorCondition
        
        
        // Handle transactionStatusResponse
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.currencyCode = "AUD"
        numberFormatter.numberStyle = .currency
        
        let amountsResp = pResponse?.paymentResult?.amountsResp
        
        let authorizedAmount = amountsResp?.authorizedAmount ?? 0;
        let tipAmount = amountsResp?.tipAmount ?? 0;
        let surchargeAmount = amountsResp?.surchargeAmount ?? 0;
        
        
        
        let maskedPAN = pResponse?.paymentResult?.paymentInstrumentData?.cardData?.maskedPan ?? "";
        let cardAccount = cardData?.getAccount()
        let paymentBrand = cardData?.getPaymentBrand()
        let entryMode = cardData?.entryMode ?? "not specified"
        let paymentInstrumentType = pResult?.paymentInstrumentData?.paymentInstrumentType ?? "not specified"
        let transactionId = pResult?.paymentAcquirerData?.acquirerTransactionID?.transactionID ?? "not specified"
        let approvalCode = pResult?.paymentAcquirerData?.approvalCode ?? "not specified"
        let receiptHTML = pResponse?.paymentReceipt?[0].getReceiptAsPlainText()!
        
        
        txtResultAuthorizedAmount.text = numberFormatter.string(from: authorizedAmount);
        txtResultTipAmount.text = numberFormatter.string(from: tipAmount);
        txtResultSurchargeAmount.text = numberFormatter.string(from: surchargeAmount);
        txtResultMaskedPAN.text = maskedPAN;
        txtCardAccount.text = cardAccount
        txtPaymentBrand.text = paymentBrand
        txtEntryMode.text = entryMode
        txtPaymentType.text = paymentInstrumentType
        txtTransactionID.text = transactionId
        txtApprovalCode.text = approvalCode
        
        
        if(success && errorCondition==nil) {
            //Internal validation for masked pan + payment brand validation
            let isValidCard = FusionCloud.isCardValid(cardNumber: maskedPAN, cardBrand: paymentBrand ?? "Unknown" )
            if !isValidCard.isValid{
                print("WARNING: \(isValidCard.errorMessage)")
            }
            
            showReceipt(doShow: true)
            if(currentPaymentServiceId != transactionStatusResponse.repeatedMessageResponse?.messageHeader!.serviceID){
                incorrectValue = transactionStatusResponse.repeatedMessageResponse?.messageHeader!.serviceID ?? "NULL" + "--payment service id"
                isIncorrectServiceID=true
                return
            }
            txtPaymentResult.backgroundColor = UIColor.systemMint; //UIColor.systemGreen;
            txtPaymentResult.textColor = UIColor.white;
            txtPaymentResult.text = "PAYMENT SUCCESSFUL"
            txtPaymentUIDisplay.text=""
            stopTimer()
            btnAbort.isHidden=true
            btnPurchase.isEnabled=true
            btnRefund.isEnabled=true
            btnLogin.isEnabled=true
            wvReceipt.loadHTMLString(receiptHTML ?? "", baseURL: Bundle.main.bundleURL)
        }
        else {
            
            if(errorCondition=="InProgress" && secondsRemaining>0){
                showReceipt(doShow: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                    self.doTransactionStatus()
//                    inErrorHandling = false
                }
            } else if(errorCondition=="Cancel"){
                showReceipt(doShow: true)
                txtPaymentResult.backgroundColor = UIColor.systemYellow;
                txtPaymentResult.textColor = UIColor.white;
                txtPaymentResult.text = "PAYMENT CANCELLED"
                txtPaymentUIDisplay.text=""
                stopTimer()
                btnAbort.isHidden=true
                btnPurchase.isEnabled=true
                btnRefund.isEnabled=true
                btnLogin.isEnabled=true
            }
            else if (secondsRemaining>0){
                showReceipt(doShow: true)
                txtPaymentResult.backgroundColor = UIColor.systemRed;
                txtPaymentResult.textColor = UIColor.white;
                txtPaymentResult.text = "PAYMENT FAILED"
                txtPaymentUIDisplay.text=""
                txtErrorCondition.text = transactionStatusResponse.response!.errorCondition
                stopTimer()
                btnAbort.isHidden=true
                btnPurchase.isEnabled=true
                btnRefund.isEnabled=true
                btnLogin.isEnabled=true
            }
            wvReceipt.loadHTMLString(receiptHTML ?? "", baseURL: Bundle.main.bundleURL)
        }
       
    }
    
    func appendLog(content: String) {
        logs.append(contentsOf: Date().ISO8601Format() + " " + content + "\n\n")
        self.txtLogs.text = logs
    }
    func logErrorMessage(errorMessage: String){
        let content =
        "------------------------------------------------------------\n------------------------------------------------------------\n \(errorMessage) \n------------------------------------------------------------\n------------------------------------------------------------"
        logs.append(contentsOf: Date().ISO8601Format() + "\n" + content + "\n\n")
        self.txtLogs.text = logs
    }
    
}
extension String {
     var htmlToAttributedString: NSAttributedString? {
         guard let data = data(using: .utf8) else { return nil }
         do {
             return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
         } catch {
             return nil
         }
     }
     var htmlToString: String {
         return htmlToAttributedString?.string ?? ""
     }
 }
extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}
