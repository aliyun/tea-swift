//
//  TeaClient.swift
//  Tea
//
//  Created by Axios on 2020/1/7.
//

import Foundation

public typealias doneCompletion = (Any?) -> Void
public typealias requestCompletion = (doneCompletion) -> Void

open class TeaClient {
    public static func async(request: @escaping requestCompletion, done: @escaping doneCompletion) {
        let requestQueue = DispatchQueue(label: "TeaClientRequest", attributes: .init(rawValue: 0))
        requestQueue.async {
            request(done)
        }
    }
}
