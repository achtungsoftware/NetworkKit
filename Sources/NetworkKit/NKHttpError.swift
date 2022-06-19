//
//  File.swift
//  
//
//  Created by Julian Gerhards on 20.06.22.
//

import Foundation

public enum NKHttpError: Error {
    case invalidUrl, responseFailed, decodingDataFailed, encodingDataFailed
}

extension NKHttpError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidUrl:
            return "NKHttp: URL object could not be created from given url string"
        case .responseFailed:
            return "NKHttp: Making HTTPURLResponse failed"
        case .decodingDataFailed:
            return "NKHttp: Failed decoding result string"
        case .encodingDataFailed:
            return "NKHttp: Failed encoding result string"
        }
    }
}
