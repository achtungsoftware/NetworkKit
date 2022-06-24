//  Copyright © 2021 - present Julian Gerhards
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  GitHub https://github.com/knoggl/NetworkKit
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
