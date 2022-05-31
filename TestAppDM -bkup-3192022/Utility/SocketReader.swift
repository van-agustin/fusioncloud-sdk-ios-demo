//
//  SocketReader.swift
//  TestApplication
//
//  Created by loey on 1/16/22.
//  Copyright © 2022 loey. All rights reserved.
//
//
//import Foundation
//import SocketIO
//
//class SocketReader {
//        let manager = SocketManager(socketURL: URL(string: "wss://www.cloudposintegration.io/nexouat")!, config: [.log(true), .compress])
//
//    func addHandlers() {
//        manager.defaultSocket.on("myEvent") {data, ack in
//            print(data)
//        }
//    }
//        let socket = manager.defaultSocket
//
//        socket.on(clientEvent: .connect) {data, ack in
//            print("socket connected")
//        }
//
//        /**socket.on("currentAmount") {data, ack in
//            guard let cur = data[0] as? Double else { return }
//
//            socket.emitWithAck("canUpdate", cur).timingOut(after: 0) {data in
//                socket.emit("update", ["amount": cur + 2.50])
//            }
//
//            ack.with("Got your currentAmount", "dude")
//        } */
//
//        socket.connect()
    
//}

/**
 String kekValue = "44DACB2A22A4A752ADC1BBFFE6CEFB589451E0FFD83F8B21"; // test environment only - replace for production
 String keyIdentifier = "SpecV2TestMACKey"; // test environment only - replace for production
 String keyVersion = "20191122164326.594"; // test environment only - replace for production

 String providerIdentification = "Company A"; // test environment only - replace for production
 String applicationName = "POS Retail"; // test environment only - replace for production
 String softwareVersion = "01.00.00"; // test environment only - replace for production
 String certificationCode = "98cf9dfc-0db7-4a92-8b8cb66d4d2d7169"; // test environment only - replace for production

 */
