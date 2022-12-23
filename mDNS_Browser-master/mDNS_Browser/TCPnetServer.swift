//
//  TCPnetServer.swift
//  mDNS_Browser
//
//  Created by Mark Robberts on 2021/08/02.
//

import Foundation
import Network

/*
 服务端
 */
class TCPnetServer: NSObject, ObservableObject {
    
    @Published var listenerState: String = ""
    
    private var listener: NWListener?
    
    func bonjourTCPListener(called: String, serviceTCPName: String, serviceDomain: String) {
        print("Bonjour TCP Listener: The Bonjour TCP function - \(called)")
        do {
            //编码后的数据 可能
            let record = NWTXTRecord()
            let random = Int8.random(in: 0...Int8.max)
            self.listener = try NWListener(using: .tcp)
            
            let txtDict = ["test": "_localNode.peerID",
                           "userid": random.description]
            //record.setEntry(NWTXTRecord.Entry.string(random.description), for: "userid")
            
            //var service = NWListener.Service(name:called, type: serviceTCPName, domain: serviceDomain, txtRecord: record)
            
            //这个不行因为data不对，data要特定的格式
            //let dd = "_localNode.peerID".data(using: String.Encoding.utf8)
            //var service1 = NWListener.Service(name:called, type: serviceTCPName, domain: serviceDomain, txtRecord: dd)
            
            let service2 = NWListener.Service(name:called, type: serviceTCPName, domain: serviceDomain, txtRecord: record)
            
            let service3 = NWListener.Service(name: called, type: serviceTCPName, domain: serviceDomain, txtRecord: NWTXTRecord.init(txtDict))
            
            //self.listener?.service = NWListener.Service(name:called, type: serviceTCPName, domain: serviceDomain, txtRecord: nil)
            self.listener?.service = service3
            
            self.listener?.serviceRegistrationUpdateHandler = { (serviceChange) in
                switch(serviceChange) {
                case .add(let endpoint):
                    switch endpoint {
                        //case service(name: String, type: String, domain: String, interface: NWInterface?)
                    case let .service(name, type, domain, interface):
                        print("Service Name \(name) of type \(type) having domain: \(domain) and interface: \(String(describing: interface?.debugDescription))")
                    default:
                        break
                    }
                default:
                    break
                }
            }
            self.listener?.stateUpdateHandler = {(newState) in
                switch newState {
                case .ready:
                    self.listenerState = "Listener state: Ready"
                    print("Bonjour TCP Listener: Bonjour listener state changed - ready")
                default:
                    break
                }
            }
            self.listener?.newConnectionHandler = {(newConnection) in
                newConnection.stateUpdateHandler = {newState in
                    switch newState {
                    case .ready:
                        print("Bonjour TCP Listener: new  connection state - ready")
                        self.receive(on: newConnection, recursive: true)
                        //self.receive(recursive: true)
                    default:
                        break
                    }
                }
                newConnection.start(queue: DispatchQueue(label: "Bonjour TCP Listener: New Connection"))
            }
        } catch {
            print("Bonjour TCP Listener: Unable to create listener")
        }
        self.listener?.start(queue: .main)
    }
    
    //MARK: - So this is one receive option
    ///Note that here we use the talking NWConenction, but in otehr places we refer to the TCPconenction, which is a bit confusing
    
    func receive(on connection: NWConnection, recursive: Bool) {
        print("TCP Receive: Is listening...")
        connection.receiveMessage { (data, context, isComplete, error) in
            print("TCP Receive: Received something")
            print("TCP Receive: \(String(describing: data))")
            //connection.receiveMessage { (data, context, isComplete, error) in
            if let error = error {
                print(error)
                return
            }
            if let content = data, !content.isEmpty {
                DispatchQueue.main.async {
                    let backToString = String(decoding: content, as: UTF8.self)
                    print("__收到的信息__TCP Receive: received: \(backToString)")
                    //talkingPublisher.send(backToString + " TCP")
                }
            }
            
        }
    }
    
    
}
