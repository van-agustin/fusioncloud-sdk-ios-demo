//
//  ViewController.swift
//  TestAppDM

import UIKit
import SVProgressHUD
import FusionCloud
import WebKit

class ViewController: UIViewController, FusionClientDelegate {
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
        txtApprovalCode.text = ""
        
        txtErrorCondition.text = ""
        inErrorHandling=false
    }
    
    func initValues(){
        timoutLimit = 60// 60 seconds as per documentation
        ErrorHandlingLimit = 90 //90 seconds
        
        inLogin = false
        isIncorrectServiceID = false
        secondsRemaining = 0
        txtTimer.text = "0"
        transactionStatusRequestCount = 0
        warningMessage = nil
        
        txtErrorCondition.textColor = UIColor.systemYellow
    }
    
    
    var timer = Timer()
    
    func timeoutStart(){
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
                txtLogs.text.append("\nReceived an incorrect service ID in transaction: \(String(describing: currentTransaction ?? "NULL"))")
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
   ///UNCOMMENT FOR PRODUCTION
//    let testEnvironment = false
//    let fusionCloudConfig = FusionCloudConfig(testEnvironmentui: false)

    ///COMMENT FOR PRODUCTION
    let testEnvironment = true
    let fusionCloudConfig = FusionCloudConfig(testEnvironmentui: true)
    
    
    var fusionClient = FusionClient()
    
    var logs: String = ""
    
    public func initConfig() {
        fusionCloudConfig.allowSelfSigned = true
        //van update this
        fusionCloudConfig.saleID = testEnvironment ? "VA POS"  : "DMGProductionVerificationTest2"
        fusionCloudConfig.poiID = testEnvironment ? "DMGVA001" : "E3330010"
        
        fusionCloudConfig.providerIdentification = testEnvironment ? "Company A" : "H_L"
        fusionCloudConfig.applicationName = testEnvironment ? "POS Retail" : "Exceed"
        fusionCloudConfig.softwareVersion = testEnvironment ? "01.00.00" : "9.0.0.0"
        fusionCloudConfig.certificationCode = testEnvironment ? "98cf9dfc-0db7-4a92-8b8cb66d4d2d7169" : "01c99f18-7093-4d77-b6f6-2c762c8ed698"
        
        /*per pinpad*/
        fusionCloudConfig.kekValue = testEnvironment ? "44DACB2A22A4A752ADC1BBFFE6CEFB589451E0FFD83F8B21" : "ba92ab29e9918943167325f4ea1f5d9b5ee679ea89a82f2c"
        
        self.fusionClient = FusionClient(fusionCloudConfig: fusionCloudConfig)
        fusionClient.fusionClientDelegate = self
        
        
    }
    
    func showReceipt(doShow: Bool){
        vwLoading.isHidden = doShow
        wvReceipt.isHidden = !doShow
    }
    
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtLogs.isEditable = false
        
        initConfig()

        
        btnAbort.isHidden=true
        imgLoading.isHidden=true;
        showReceipt(doShow: false)
    }
    
    @IBAction func btnSelectAll(_ sender: Any) {
        txtLogs.selectAll(self)
    }
    
    @IBAction func btnClear(_ sender: Any) {
        self.txtLogs.text=""
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
        self.doLogin()
    }
    
    @IBAction func btnDoPayment(_ sender: UIButton) {
        initValues()
        showReceipt(doShow: false)
        wvReceipt.loadHTMLString("", baseURL: Bundle.main.bundleURL)
        btnAbort.isEnabled = true
        currentTransaction = "Payment"
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
            
            fusionClient.sendMessage(requestBody: transactionStatusRequest, type: "TransactionStatusRequest")
        }
    }
    
    func doLogin() {
        currentTransaction = "Login"
        
        
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
    func paymentResponseReceived(client: FusionClient, messageHeader: MessageHeader, paymentResponse: PaymentResponse) {
        if inErrorHandling && secondsRemaining <= 0 { return }
        
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
    
    func transactionStatusResponseReceived(client: FusionClient, messageHeader: MessageHeader, transactionStatusResponse: TransactionStatusResponse) {
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
                showReceipt(doShow: true)
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
    
    func displayRequestReceived(client: FusionClient, messageHeader: MessageHeader, displayRequest: DisplayRequest) {

        if(messageHeader.serviceID != currentTransactionServiceID){
            //print("ignoring incorrect service id display request above")
            incorrectValue = messageHeader.serviceID
            isIncorrectServiceID=true
            return
        }
        showReceipt(doShow: false)
        txtPaymentUIDisplay.text = displayRequest.getCashierDisplayAsPlainText()
        if (!inErrorHandling) {
            stopTimer()
            secondsRemaining = timoutLimit
            timeoutStart()
        }
    }
    ///Leaving Event Notification for logs
    func eventNotificationReceived(client: FusionClient, messageHeader: MessageHeader, eventNotification: EventNotification) {
        txtLogs.text.append("Ignoring Event Notification above\r\n")
    }
    
    func reconcilationResponseReceived(client: FusionClient, messageHeader: MessageHeader, reconcilationResponse: ReconciliationResponse) {
        print("reconcilationResponseReceived!")
    }
    
    func cardAcquisitionResponseReceived(client: FusionClient, messageHeader: MessageHeader, cardAcquisitionResponse: CardAcquisitionResponse) {
        print("cardAcquisitionResponseReceived!")
    }
    
    func logoutResponseResponseReceived(client: FusionClient, messageHeader: MessageHeader, logoutResponse: LogoutResponse) {
        print("logoutResponseResponseReceived!")
    }
    
    func socketConnected(client: FusionClient) {
        txtLogs.text.append("\r\nSocket Connected")
        print("Socket Connected")
        if inErrorHandling {
            self.doTransactionStatus()
        }
    }
    
    func socketDisconnected(client: FusionClient) {
        if !inErrorHandling{
            txtLogs.text.append("\r\nConnection lost! Reconnecting...")
            secondsRemaining = 0
        }
        //will try to reconnect to socket
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [self] in
            if self.secondsRemaining>0{
                initConfig()
            }
        }
    }
    
    func socketReceived(client: FusionClient, data: String) {
        let strFormatted = data.data(using: .utf8)!.prettyPrintedJSONString!
        txtLogs.text.append(contentsOf: "\r\n\r\n\(Date().ISO8601Format()) \(strFormatted as String) \n\n")
    }
    
    func socketError(client: FusionClient, error: Error) {
        print("socket error")
        //stopTimer()
    }
    
    func logData(client: FusionClient, type: String, data: String) {
        print("logtype:\(type)")
        print("details:\(data)")
    }
    
    func loginResponseReceived(client: FusionClient, messageHeader: MessageHeader, loginResponse: LoginResponse) {
        if !inLogin {
            txtLogs.text.append("\r\nIgnoring Login Response above")
            return
        }
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
            print("Login Error!")
            txtPaymentUIDisplay.text = "LOGIN FAILED"
            btnLogin.isEnabled = true
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
