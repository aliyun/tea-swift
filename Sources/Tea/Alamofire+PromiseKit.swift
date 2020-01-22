//
// Created by Axios on 2020/1/14.
//

import Foundation
import Alamofire
import PromiseKit

let defaultQueue = DispatchQueue(label: "AlamofirePromiseKit.queue")

public extension Alamofire.DataRequest {
    func response(queue: DispatchQueue? = nil) -> Promise<DefaultDataResponse> {
        Promise { seal in
            response(queue: queue ?? defaultQueue) { response in
                seal.fulfill(response)
            }
        }
    }

    func responseString(queue: DispatchQueue? = nil) -> Promise<DataResponse<String>> {
        Promise { seal in
            responseString(queue: queue ?? defaultQueue) { response in
                seal.fulfill(response)
            }
        }
    }

    func responseData(queue: DispatchQueue? = nil) -> Promise<DataResponse<Data>> {
        Promise { seal in
            responseData(queue: queue ?? defaultQueue) { response in
                seal.fulfill(response)
            }
        }
    }

    func responseJSON(
            queue: DispatchQueue? = nil,
            options: JSONSerialization.ReadingOptions = .allowFragments
    ) -> Promise<DataResponse<Any>> {
        Promise { seal in
            responseJSON(queue: queue ?? defaultQueue, options: options) { response in
                seal.fulfill(response)
            }
        }
    }

    func responsePropertyList(
            queue: DispatchQueue? = nil,
            options: PropertyListSerialization.ReadOptions = PropertyListSerialization.ReadOptions()
    ) -> Promise<DataResponse<Any>> {
        Promise { seal in
            responsePropertyList(queue: queue ?? defaultQueue, options: options) { response in
                seal.fulfill(response)
            }
        }
    }
}

public extension Alamofire.DownloadRequest {
    func response(queue: DispatchQueue? = nil) -> Promise<DefaultDownloadResponse> {
        Promise { seal in
            response(queue: queue ?? defaultQueue) { response in
                seal.fulfill(response)
            }
        }
    }

    func responseData(queue: DispatchQueue? = nil) -> Promise<DownloadResponse<Data>> {
        Promise { seal in
            responseData(queue: queue ?? defaultQueue) { response in
                seal.fulfill(response)
            }
        }
    }
}
