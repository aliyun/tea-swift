//
// Created by Axios on 2020/1/14.
//

import Foundation
import Tea

open class ListDriveResponse : TeaModel {
    @objc public var requestId:String = ""

    @objc public var items:[String:Any] = [String:NSObject]()

    @objc public var nextMarker:String = ""

    public override init() {
        super.init()
        self.__name["requestId"] = "requestId"
        self.__name["items"] = "items"
        self.__name["nextMarker"] = "next_marker"
    }
}


open class ListDriveRequestModel: TeaModel{
    @objc public var limit:Int = 0
    @objc public var marker:String = ""
    @objc public var owner:String = ""
    public override init() {
        super.init()
        self.__required["owner"] = true
    }
}