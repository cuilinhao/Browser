//
//  TCPnetServer.swift
//  mDNS_Browser
//
//  Created by Mark Robberts on 2021/08/02.
//

import Foundation
import Network
import UIKit

/*
 服务端
 */
class TCPnetServer: NSObject, ObservableObject {
    
    @Published var listenerState: String = ""
    @Published var receiveData: String = ""
    
    private var listener: NWListener?
    
    let monitor = NWPathMonitor()
    
    
    func bonjourTCPListener(called: String, serviceTCPName: String, serviceDomain: String) {
        print("Bonjour TCP Listener: The Bonjour TCP function - \(called)")
        do {
            //编码后的数据 可能
            let record = NWTXTRecord()
            let random = Int8.random(in: 0...Int8.max)
            ///PS：创建TCP的Server，可以接收很多次消息，创建UDP的Server，一次链接只能接收一次消息
            ///可查看https://www.cnblogs.com/17years/p/15251559.html
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
                case .add(let endpoint)://case add(NWEndpoint)
                    switch endpoint {
                        //case service(name: String, type: String, domain: String, interface: NWInterface?)
                    case let .service(name, type, domain, interface):
                        //Service Name iPhone of type _nsdalbum._tcp having domain: local. and interface: nil
                        print("_____>>>>>_Service Name \(name) of type \(type) having domain: \(domain) and interface: \(String(describing: interface?.debugDescription))")
                    case let .hostPort(host: host, port: port):
                        print("___>>>___host&port__\(host)_____\(port)")
                        
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
            ///该方法没有调用
            self.listener?.newConnectionHandler = {(newConnection) in
                newConnection.stateUpdateHandler = {newState in
                    switch newState {
                    case .ready:
                        print("Bonjour TCP Listener: new  connection state - ready")
                        print("___>>>_newConnection.endpoint__\(newConnection.endpoint)")
                        
                        switch newConnection.endpoint {
                        case let .hostPort(host: host, port: port):
                            print("___>>>_host&port_\(host)_____\(port)")
                        case let .service(name: name, type: type, domain: domain, interface: nil):
                            print("___>>>_name&type&domain_\(name)___\(type)__\(domain)")
                        default:
                            break
                        }
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
        
        test()
    }
    
    private func test() {
        monitor.pathUpdateHandler = { path in
           _ =  path.gateways.map { endpoint in
                print("___>>>__test__0_\(endpoint)")
                switch endpoint {
                case let .hostPort(host: host, port: port):
                    print("___>>>_test_1_\(host)___\(port)")
                    switch host {
                    case let .ipv4(ip4):
                        print("___>>>_test_2_\(ip4)")
                    case let .ipv6(ip6):
                        print("___>>>_test_3_\(ip6)")
                    default:
                        break
                    }
                    
                default:
                    break
                }
            
            }
           if path.status == .satisfied {
               //连接
              print("__>>>__test__connected")
           } else {
              print("__>>>__test__no connection")
           }
        }
        monitor.start(queue: DispatchQueue.global())
    }
    
    //MARK: - So this is one receive option
    ///Note that here we use the talking NWConenction, but in otehr places we refer to the TCPconenction, which is a bit confusing
    //MARK: - 接收数据
    func receive(on connection: NWConnection, recursive: Bool) {
        print("TCP Receive: Is listening...")
        connection.receive(minimumIncompleteLength: Int.min, maximumLength: Int.max) { content, contentContext, isComplete, error in
            print("TCP Receive: Received something")
            print("TCP Receive: \(String(describing: content))")
            //connection.receiveMessage { (data, context, isComplete, error) in
            if let error = error {
                print(error)
                return
            }
            if let content = content, !content.isEmpty {
                DispatchQueue.main.async {
                    let backToString = String(decoding: content, as: UTF8.self)
                    print("__收到的信息__TCP Receive: received: \(backToString)")
                    //talkingPublisher.send(backToString + " TCP")
                    if backToString.contains("Hello") {
                        self.receiveData = self.receiveData.appending(backToString)
                    }
                }
            }
        }
        /*
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
        */
    }
    
    
}


class viewcontroller: UIViewController {
    let monitor = NWPathMonitor()
    override func viewDidLoad() {
       super.viewDidLoad()
       monitor.pathUpdateHandler = { path in
          if path.status == .satisfied {
             print("connected")
          } else {
             print("no connection")
          }
       }
       monitor.start(queue: DispatchQueue.global())
        
        
        monitor.pathUpdateHandler = { path in
            path.gateways.map { endpoint in
                print("___>>>_\(endpoint)")
            }
           if path.status == .satisfied {
               //连接
              print("connected")
           } else {
              print("no connection")
           }
        }
        
        
    }
}
/*
 ___>>>__test__0_172.20.10.1:0
 ___>>>_test_1_172.20.10.1___0
 ___>>>_test_2_172.20.10.1
 __>>>__test__connected
 _____>>>>>_Service Name iPhone of type _nsdalbum._tcp having domain: local. and interface: nil
 ____>>>>_result_debug_DistributedAlbum._nsdalbum._tcplocal.
 ____>>>>_result_debug_iPhone._nsdalbum._tcplocal.
 ____>>>>_result_debug_DistributedAlbum._nsdalbum._tcplocal.
 __rrrr_>>>_Optional("103")____Optional("_localNode.peerID")
 __>>>__bonjourToTCP: Connection details: Optional("[C1 DistributedAlbum._nsdalbum._tcp.local. tcp, attribution: developer, path satisfied (Path is satisfied), interface: en0, ipv4]")
 ___>>>_正在准备建立连接___
 __>>>__bonjourToTCP: Connection details: Optional("[C1 connected DistributedAlbum._nsdalbum._tcp.local. tcp, attribution: developer, path satisfied (Path is satisfied), viable, interface: en0, scoped, ipv4, dns]")
 ____>>>>__bonjourToTCP: new TCP connection ready
 ___>>>_qqqqq
 ___>>>_nil
 ___>>>_finished
 _接收数据__>>>_nil__Optional(Network.NWConnection.ContentContext)___true___nil

 */
