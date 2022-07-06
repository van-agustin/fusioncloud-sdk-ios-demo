# ``fusionCloud-framework-ios-demoapp``

## Overview

This app demonstrates how to send login, payment and transaction status requests using the Fusion Cloud SDK.

## Getting Started

#### Configuration

Use cocoapods to download repositories.

#### Configuration

FusionClientConfig

- <!--@START_MENU_TOKEN@-->certificateLocation (root CA location e.g., 'src/main/resources/root.crt')<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->serverDomain (domain/server URI)<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->socketProtocol (defaults to 'TLSv1.2' if not provided)<!--@END_MENU_TOKEN@-->

KEKConfig

- <!--@START_MENU_TOKEN@-->value (KEK provided by DataMesh)<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->keyIdentifier (SpecV2TestMACKey or SpecV2ProdMACKey)<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->keyVersion (version)<!--@END_MENU_TOKEN@-->

SalesSystemConfig (static sale system settings - provided by DataMesh)

- <!--@START_MENU_TOKEN@-->value (KEK provided by DataMesh)<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->keyIdentifier (SpecV2TestMACKey or SpecV2ProdMACKey)<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->keyVersion (version)<!--@END_MENU_TOKEN@-->

## Dependencies

This project uses the following dependencies

- [FusionCloud Framework](https://fusioncloud.framework)- contains all the models necessary to create request and response messages to the Fusion websocket server


## Usage

The com.dmg.fusion.client.WebSocketClient.connect(URI) method expects a valid wss URI to connect to. Unify utilises a self-signed root CA provided by DataMesh. The certificate must be added to the project directory and its location must be specified in the properties file (see Getting Started) with key certificate.location.
