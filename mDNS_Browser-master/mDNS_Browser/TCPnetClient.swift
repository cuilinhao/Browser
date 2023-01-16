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
    
    private var cancellables: AnyCancellable?
    
    private var netConnect: NWConnection?
    
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
                self.testPublisher()
            default:
                break
            }
        }
        
        self.netConnect?.start(queue: .main)
        /*
         收消息 和发消息
         */
        //self.netConnect?.send(content: Data?, contentContext: <#T##NWConnection.ContentContext#>, isComplete: <#T##Bool#>, completion: <#T##NWConnection.SendCompletion#>)
//        self.netConnect?.receive(minimumIncompleteLength: <#T##Int#>, maximumLength: <#T##Int#>, completion: { content, contentContext, isComplete, error in
//            <#code#>
//        })
    }
    
     func requestData() {
        let session = URLSession(configuration: .default)
        //let url = URL(string: "http://127.0.0.1:8080/api/test")!
         
        let str = "http://172.20.10.3:8080/.photoShare/thumb/lcd/default-album-1/00e6fba788569c0d339837669eb8535c18cbb7825c61b60bfd5ccda42d36e463.jpg"
        let localStr = "http://127.20.10.3:8080"
        let url = URL(string: str)!
        var urlRequest = URLRequest(url: url)
        //urlRequest.method = .post
        urlRequest.httpMethod = "GET"
        print("___>>>_qqqqq")
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            print("___>>>_\(data)")
            do {
                self.imgData = data!// ?? UIImage(named: "aaa")?.pngData()!
                let jsonData = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers)
                if let dic = jsonData as? [String : Any] {
                    print("___>>>_\(dic)")
                }
            } catch  {
                //如果链接失败´
                print("___>>>_链接失败__error:\(error)")
            }
        }
        task.resume()
    }
    
    private func testPublisher() {
        let session = URLSession(configuration: .default)
        let str = "http://172.20.10.3:8080/.photoShare/thumb/lcd/default-album-1/00e6fba788569c0d339837669eb8535c18cbb7825c61b60bfd5ccda42d36e463.jpg"
        let localStr = "http://127.20.10.3:8080"
        let url = URL(string: str)!
        var urlRequest = URLRequest(url: url)
        //urlRequest.method = .post
        urlRequest.httpMethod = "GET"
        print("___>>>_qqqqq")
        
        cancellables = session.dataTaskPublisher(for: urlRequest).receive(on: DispatchQueue.main).sink { error in
            print("___>>>_\(error)")
        } receiveValue: { data in
            self.imgData = data.data
        }
    }
    
    private func requestData22() {
        let session = URLSession(configuration: .default)
        let url = "http://172.20.10.4:8080"
        let urlRequest = URLRequest(url: URL(string: url)!)
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            do {
                //返回
                let r =  try JSONSerialization.jsonObject(with: data!, options: [])
                print("___>>>_\(r)")
            } catch {
                //如果链接失败
                print("___>>>_链接服务器失败")
            }
        }
        task.resume()
    }
    
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

