//
//  SHA256.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//

import Foundation
import CNIOBoringSSL

func sha256(message: Data) -> Data {
    var output = Data(count: 32)
    CNIOBoringSSL_SHA256(pointer(message), message.count, pointer(&output))
    return output
}
