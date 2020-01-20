//
// Created by Axios on 2020/1/14.
//

import Foundation
import Alamofire
import PromiseKit

extension Alamofire.DataRequest {
    public func response(queue: DispatchQueue? = nil) -> Promise<DefaultDataResponse> {
        let TeaQueue: DispatchQueue = DispatchQueue(label: "TeaQueue.Alamofire.DataRequest.response", attributes: .init(rawValue: 0))
        return Promise { seal in
            response(queue: TeaQueue) { response in
                seal.fulfill(response)
            }
        }
    }

    public func responseString() -> Promise<DataResponse<String>> {
        let TeaQueue: DispatchQueue = DispatchQueue(label: "TeaQueue.Alamofire.DataRequest.responseString", attributes: .init(rawValue: 0))
        return Promise { seal in
            responseString(queue: TeaQueue) { response in
                seal.fulfill(response)
            }
        }
    }

    public func responseData() -> Promise<DataResponse<Data>> {
        let TeaQueue: DispatchQueue = DispatchQueue(label: "TeaQueue.Alamofire.DataRequest.responseData", attributes: .init(rawValue: 0))
        return Promise { seal in
            responseData(queue: TeaQueue) { response in
                seal.fulfill(response)
            }
        }
    }

    public func responseJSON(options: JSONSerialization.ReadingOptions = .allowFragments) -> Promise<DataResponse<Any>> {
        let TeaQueue: DispatchQueue = DispatchQueue(label: "TeaQueue.Alamofire.DataRequest.responseJSON", attributes: .init(rawValue: 0))
        return Promise { seal in
            responseJSON(queue: TeaQueue, options: options) { response in
                seal.fulfill(response)
            }
        }
    }

    public func responsePropertyList(
            queue: DispatchQueue? = nil,
            options: PropertyListSerialization.ReadOptions = PropertyListSerialization.ReadOptions()
    ) -> Promise<DataResponse<Any>> {
        let TeaQueue: DispatchQueue = DispatchQueue(label: "TeaQueue.Alamofire.DataRequest.responsePropertyList", attributes: .init(rawValue: 0))
        return Promise { seal in
            responsePropertyList(queue: TeaQueue, options: options) { response in
                seal.fulfill(response)
            }
        }
    }
}

extension Alamofire.DownloadRequest {
    public func response(_: PMKNamespacer, queue: DispatchQueue? = nil) -> Promise<DefaultDownloadResponse> {
        let TeaQueue: DispatchQueue = DispatchQueue(label: "TeaQueue.Alamofire.DownloadRequest.response", attributes: .init(rawValue: 0))
        return Promise { seal in
            response(queue: TeaQueue) { response in
                seal.fulfill(response)
            }
        }
    }

    public func responseData(queue: DispatchQueue? = nil) -> Promise<DownloadResponse<Data>> {
        let TeaQueue: DispatchQueue = DispatchQueue(label: "TeaQueue.Alamofire.DownloadRequest.responseData", attributes: .init(rawValue: 0))
        return Promise { seal in
            responseData(queue: TeaQueue) { response in
                seal.fulfill(response)
            }
        }
    }
}