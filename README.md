# ``fusionCloud-framework-ios-demoapp``

## Overview

This app demonstrates how to send login, payment and transaction status requests using the Fusion Cloud SDK.

## Getting Started

### First-time setup

* Ensure [cocoapods](https://guides.cocoapods.org/using/getting-started.html) is installed
* Navigate to project diretory and run `pod install` to install pods

### Settings

FusionClientConfig

* certificateLocation (root CA location e.g., 'src/main/resources/root.crt')<!--@END_MENU_TOKEN@-->

POS settings (static settings provided by DataMesh)

* providerIdentification
* application Name
* softwareVersion
* certificationCode

Sale system settings (different for each instance)

* kekValue (KEK provided by DataMesh)
* saleID
* poiID


## Dependencies

This project uses the following dependencies

- [FusionCloud](https://github.com/datameshgroup/fusioncloud-sdk-ios)- contains all the models necessary to create request and response messages to the Fusion websocket server


## Usage

The com.dmg.fusion.client.WebSocketClient.connect(URI) method expects a valid wss URI to connect to. Unify utilises a self-signed root CA provided by DataMesh. The certificate must be added to the project directory and its location must be specified in the properties file (see Getting Started) with key certificate.location.
