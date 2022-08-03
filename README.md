# ``fusionCloud-framework-ios-demoapp``

## Overview

This app demonstrates how to send login, payment and transaction status requests using the Fusion Cloud SDK.

## Getting started

### Dependencies

The following toolset is required:

* Xcode ~13.4
* CocoaPods ~1.11
* iOS 12

Frameworks are managed by CocoaPods

* [ObjectMapper](https://cocoapods.org/pods/ObjectMapper)- pod dependency that convert JSON into Swift model
* [IDZSwiftCommonCrypto](https://github.com/iosdevzone/IDZSwiftCommonCrypto)- pod dependency that help encryption/decryption
* [StarScream](https://github.com/daltoniam/Starscream) - websockets
* [FusionCloud](https://github.com/datameshgroup/fusioncloud-sdk-ios) - contains all the models necessary to create request and response messages to the Fusion websocket server


### Building the FusionCloud demo app

*To ensure your environment is configured for iOS development, follow the instructions in Appendix A*

Clone the FusionCloud demo app
* `git clone https://github.com/datameshgroup/fusioncloud-sdk-ios-demo.git`

Install CocoaPods managed frameworks:

* Navigate to the project directory
* Run `pod install` to install, and `pod update` to update 
* If you need to reinstall, run `pod cache clean --all` then `pod install` again

Set your build target:
* Select build destination from Product/Destination menu
* Supported destinations are iOS Simulator, or iOS Device arm64 


Build FusionCloud library

* See the [FusionCloud lib](https://github.com/datameshgroup/fusioncloud-sdk-ios) repo for instructions on rebuilding the library


### Running the demo app

Open ViewController and edit the fusionCloudConfig with the values provided to you by DataMesh.

Build & run the app

```
fusionCloudConfig = FusionCloudConfig()
fusionCloudConfig!.initConfig(
testEnvironment: true | false,
providerIdentification: "<<Provided by DataMesh>>",
applicationName: "<<Provided by DataMesh>>",
softwareVersion: "<<Your POS version>>",
certificationCode: "<<Provided by DataMesh>>",
saleID: "<<Provided by DataMesh>>",
poiID: "<<Provided by DataMesh>>",
kekValue: "<<Provided by DataMesh>>")
```
