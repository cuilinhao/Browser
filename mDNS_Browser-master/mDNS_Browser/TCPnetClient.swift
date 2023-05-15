//
//  TCPnetClient.swift
//  mDNS_Browser
//
//  Created by Mark Robberts on 2021/08/05.
//

import Foundation
import Network
import UIKit
import Combine

/*
 客户端
 */
//@MainActor
class TCPnetClient: NSObject, ObservableObject {
    
    @Published var connectState: String = ""
    @Published var imgData: Data = Data()
    @Published var ipInfo: String = ""
    private var cancellables: AnyCancellable?
    
    private var netConnect: NWConnection?
    let monitor = NWPathMonitor()
    
    
    //MARK: - This is settimng up a new connection once the service is identified/selected
    ///Now we just have to receive incoming data
    func bonjourToTCP(called: String, serviceTCPName: String, serviceDomain: String) {
        guard !called.isEmpty else { return }
        
        self.netConnect = NWConnection(to: .service(name: called, type: serviceTCPName, domain: serviceDomain, interface: nil), using: .tcp)
        self.netConnect?.stateUpdateHandler = { (newState) in
            print("__>>>__bonjourToTCP: Connection details: \(String(describing: self.netConnect?.debugDescription))")
            switch (newState) {
            case .preparing:
                print("___>>>_正在准备建立连接___")
            case .cancelled:
                print("___>>>_被呼叫___")
            case .failed(let error):
                print("___>>>__链接失败_\(error)")
            case .setup:
                print("___>>>_setUp___")
            case .ready:
                self.connectState = "Connection state: Ready"
                print("____>>>>__bonjourToTCP: new TCP connection ready ")
                //self.requestData()
                self.getIpv4Adress { str in
                    DispatchQueue.main.async {
                        self.ipInfo = str
                    }
                    
                    //self.testPublisher(str)
                }
                //self.testPublisher(self.getIpv4Adress())
                if let innerEndpoint = self.netConnect?.currentPath?.remoteEndpoint,
                   case let .hostPort(host, port) = innerEndpoint {
                    //print(host, port)
                    print("___>>>_\(host)___\(port)")
                }
                
                switch self.netConnect!.endpoint {
                case .hostPort(host: let host, port: let port):
                    print("___>>>_\(host)___\(port)")
                case .service(name: let name, type: let type, domain: let domain, interface: let interface):
                    print("___>>>_\(name)___\(type)___\(domain)__\(interface)")
                case .unix(path: let path):
                    break
                case .url(let u):
                    print("___>>>_\(u)___")
                case .opaque(_):
                    break
                @unknown default:
                    break
                }
                
            default:
                break
            }
        }
        
        self.netConnect?.start(queue: .main)
        /*
         收消息 和发消息
         */
        //self.netConnect?.send(content: Data?, contentContext: <#T##NWConnection.ContentContext#>, isComplete: <#T##Bool#>, completion: <#T##NWConnection.SendCompletion#>)
        
        ///发送数据
        self.netConnect?.send(content: "abc".data(using: .utf8), completion: NWConnection.SendCompletion.contentProcessed({ error in
            print("___>>>_\(error)")
        }))
        
        ///接收数据
        self.netConnect?.receive(minimumIncompleteLength: 8, maximumLength: 8, completion: { content, contentContext, isComplete, error in
            // 接收到的data
            print("_接收数据__>>>_\(content)__\(contentContext)___\(isComplete)___\(error)")
        })
    }
    
    private func testPublisher(_ ipv4: String) {
        let session = URLSession(configuration: .default)
        //http://172.20.10.3:8080/Pictures/NIO/IMG_20230327_152316.jpg
        let str = "http://" + ipv4 + ":8080/Pictures/NIO/IMG_20230327_152316.jpg"
        let url = URL(string: str)!
        var urlRequest = URLRequest(url: url)
        //urlRequest.method = .post
        urlRequest.httpMethod = "GET"
        cancellables = session.dataTaskPublisher(for: urlRequest).receive(on: DispatchQueue.main).sink { error in
            print("___>>>_\(error)")
        } receiveValue: { data in
            self.imgData = data.data
        }
    }
    
    private func getIpv4Adress(_ completion: ((String) -> Void)?) {
        var ipv4 = String()
        monitor.pathUpdateHandler = { path in
           _ =  path.gateways.map { endpoint in
                print("___>>>__test__0_\(endpoint)")
                switch endpoint {
                case let .hostPort(host: host, port: port):
                    print("___>>>_test_1_\(host)___\(port)")
                    switch host {
                    case let .ipv4(ip4):
                        print("___>>>_test_2_\(ip4)")
                        //ipv4 =  ip4.debugDescription
                        //completion?(ipv4)
                        ipv4 = ipv4.appending("ipv4:\(ip4.debugDescription )")
                    case let .ipv6(ip6):
                        print("___>>>_test_3_\(ip6)")
                        ipv4 = ipv4.appending(" ipv6:\(ip6.debugDescription )")
                        ipv4 = ipv4.appending(" port:\(port.rawValue)")
                    default:
                        break
                    }
                default:
                    break
                }
            }
            
           if path.status == .satisfied {
               //连接
               completion?(ipv4)
              print("__>>>__test__connected_\(ipv4)")
           } else {
              print("__>>>__test__no connection")
           }
        }
        monitor.start(queue: DispatchQueue.global())
    }
    
    
//
//     func requestData() {
//        let session = URLSession(configuration: .default)
//        //let url = URL(string: "http://127.0.0.1:8080/api/test")!
//
//        let str = "http://172.20.10.3:8080/.photoShare/thumb/lcd/default-album-1/00e6fba788569c0d339837669eb8535c18cbb7825c61b60bfd5ccda42d36e463.jpg"
//        let localStr = "http://127.20.10.3:8080"
//        let url = URL(string: str)!
//        var urlRequest = URLRequest(url: url)
//        //urlRequest.method = .post
//        urlRequest.httpMethod = "GET"
//        print("___>>>_qqqqq")
//        let task = session.dataTask(with: urlRequest) { (data, response, error) in
//            print("___>>>_\(data)")
//            do {
//                self.imgData = data!// ?? UIImage(named: "aaa")?.pngData()!
//                let jsonData = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
//                if let dic = jsonData as? [String : Any] {
//                    print("___>>>_\(dic)")
//                }
//            } catch  {
//                //如果链接失败´
//                print("___>>>_链接失败__error:\(error)")
//            }
//        }
//        task.resume()
//    }
//
//
//
//    private func requestData22() {
//        let session = URLSession(configuration: .default)
//        let url = "http://172.20.10.4:8080"
//        let urlRequest = URLRequest(url: URL(string: url)!)
//        let task = session.dataTask(with: urlRequest) { (data, response, error) in
//            do {
//                //返回
//                let r =  try JSONSerialization.jsonObject(with: data!, options: [])
//                print("___>>>_\(r)")
//            } catch {
//                //如果链接失败
//                print("___>>>_链接服务器失败")
//            }
//        }
//        task.resume()
//    }
    
}


extension URLRequest {
    /// Returns the `httpMethod` as Alamofire's `HTTPMethod` type.
//    public var method: HTTPMethod? {
//        get { httpMethod.flatMap(HTTPMethod.init) }
//        set { httpMethod = newValue?.rawValue }
//    }

//    public func validate() throws {
//        if method == .get, let bodyData = httpBody {
//            throw AFError.urlRequestValidationFailed(reason: .bodyDataInGETRequest(bodyData))
//        }
//    }
}

