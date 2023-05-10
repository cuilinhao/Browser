//
//  mCastBrowser.swift
//  mDNS_Browser
//
//  Created by Mark Robberts on 2021/07/22.
//

import UIKit
import Combine
import Network

/*
 * 可以是client 也可以是server 查看状态
 */
class mCastBrowser: NSObject, ObservableObject, Identifiable {
    //model 数据
    struct objectOf:Hashable {
        var id:UUID? = UUID()
        var device:String = ""
        var IsIndexed:Int = 0
        var userId: String = ""
    }
    @Published var devices: [objectOf] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    var browser: NWBrowser!
    /*
     
     1、他们有 http server
     
     2. 我拿他们相册数据，展示到app
     
     3.
     
     */
    //扫描所有设备
    func scan(typeOf: String, domain: String) {
        //let bonjourTCP = NWBrowser.Descriptor.bonjour(type: typeOf , domain: domain)
        let bonjourTCP = NWBrowser.Descriptor.bonjourWithTXTRecord(type: typeOf, domain: domain)
        let bonjourParms = NWParameters.init()
        bonjourParms.allowLocalEndpointReuse = true
        bonjourParms.acceptLocalOnly = true
        bonjourParms.allowFastOpen = true
        
        browser = NWBrowser(for: bonjourTCP, using: bonjourParms)
        browser.stateUpdateHandler = {newState in
            switch newState {
            case .failed(let error):
                print("NW Browser: now in Error state: \(error)")
                self.browser.cancel()
            case .ready:
                print("NW Browser: new bonjour discovery - ready")
            case .setup:
                print("NW Browser: ooh, apparently in SETUP state")
            default:
                break
            }
        }
        //搜索结果
        browser.browseResultsChangedHandler = { ( results, changes ) in
            print("NW Browser: Scan results found:")
            for result in results {
//                var userId  = ""
//                if case let .bonjour(record) = result.metadata {
//                    userId = record["userid"]!
//                    print("__rrrr_>>>_\(record["userid"])")
//                }
            //case .add(let endpoint)://case add(NWEndpoint)
                switch result.endpoint {
                    //case service(name: String, type: String, domain: String, interface: NWInterface?)
//                case let .service(name, type, domain, interface):
//                    //Service Name iPhone of type _nsdalbum._tcp having domain: local. and interface: nil
//                    print("_____>>>>>__result_Service Name \(name) of type \(type) having domain: \(domain) and interface: \(String(describing: interface?.debugDescription))")
                case let .hostPort(host: host, port: port):
                    print("___>>>_result__host&port__\(host)_____\(port)")
                    
                default:
                    break
                }
                
                
                print("____>>>>_result_debug_\(result.endpoint.debugDescription)")
            }
            for change in changes {
                
                if case .added(let added) = change {
                    
                    //endpoint 主机端口端点表示由主机和端口定义的端点。
                    //case service(name: String, type: String, domain: String, interface: NWInterface?)
                    //NWBrowser.Result
                    if case .hostPort(let is_host, let is_port) = added.endpoint {
                        print("__changes_>>>_\(is_host)____\(is_port)")
                    }
                    if case .service(let name, _, _, _) = added.endpoint {
                        var userId  = ""
                        if case let .bonjour(record) = added.metadata {
                            userId = record["userid"]!
                            print("__rrrr_>>>_\(record["userid"])____\(record["test"])")
                        }
                        let device = objectOf(device: name, IsIndexed: self.devices.count, userId: userId)
                        //let device = objectOf(device: name, IsIndexed: self.devices.count)
                        self.devices.append(device)
                    }
                    
                    if case .removed(let removed) = change {
                        print("NW Browser: Removed")
                        if case .service(let name, _, _, _) = removed.endpoint {
                            let index = self.devices.firstIndex(where:{$0.device == name })
                            self.devices.remove(at: index!)
                        }
                    }
                    
                    
                }
            }
        }
        self.browser.start(queue: DispatchQueue.main)
    }
}


