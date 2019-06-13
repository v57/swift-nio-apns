//
//  DataSigner.swift
//  NIOAPNS
//
//  Created by Kyle Browning on 2/21/19.
//
import Foundation
import CNIOBoringSSL

public class DataSigner: APNSSigner {
    private let opaqueKey: OpaquePointer

    public init(data: Data) throws {
        let bio = CNIOBoringSSL_BIO_new(CNIOBoringSSL_BIO_s_mem())
        defer { CNIOBoringSSL_BIO_free(bio) }

        let nullTerminatedData = data + Data([0])
        let res = CNIOBoringSSL_BIO_puts(bio, raw(nullTerminatedData).convert())
        assert(res >= 0, "BIO_puts failed")

        if let pointer  = CNIOBoringSSL_PEM_read_bio_ECPrivateKey(bio!, nil, nil, nil) {
            self.opaqueKey = pointer
        } else {
            throw APNSSignatureError.invalidAuthKey
        }
    }

    deinit {
        CNIOBoringSSL_EC_KEY_free(opaqueKey)
    }

    public func sign(digest: Data) throws -> Data  {
        let sig = CNIOBoringSSL_ECDSA_do_sign(pointer(digest), digest.count, opaqueKey)
        defer { CNIOBoringSSL_ECDSA_SIG_free(sig) }

        var derEncodedSignature: UnsafeMutablePointer<UInt8>? = nil
        let derLength = CNIOBoringSSL_i2d_ECDSA_SIG(sig, &derEncodedSignature)
        
        guard let derCopy = derEncodedSignature, derLength > 0 else {
            throw APNSSignatureError.invalidASN1
        }

        var derBytes = [UInt8](repeating: 0, count: Int(derLength))

        for b in 0..<Int(derLength) {
            derBytes[b] = derCopy[b]
        }

        return Data(derBytes)

    }
}
