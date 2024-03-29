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

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if os(iOS)
import UIKit
#endif

/// A class for handling http requests and json encoding
public class NKHttp {
    
    private static let jsonDecoder: JSONDecoder = JSONDecoder()
    
    /// Creates an parameter string from a dictionary and applies url encoding to the value
    /// - Parameter parameters: The parameter dictionary
    /// - Returns: An encoded String for url paramater
    public static func buildParameterString(_ parameters: [String: String]?) -> String {
        var postData = ""
        if let parameters = parameters {
            for (key, value) in parameters {
                postData.append("\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")&")
            }
        }
        
        return String(postData.dropLast())
    }
}

/// POST callback methods
extension NKHttp {
    
#if os(iOS)
    
    @available(iOS 7.0, *)
    /// iOS specific method for uploading videos, images and/or audio files to the server
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Post url parameters, default is `nil`
    ///   - videos: Optional `Array` of video `Url`'s for upload
    ///   - images: Optional `Array` of image `UIImage`'s for upload
    ///   - audios: Optional `Array` of audio `Url`'s for upload
    ///   - imageCompressionQuality: The compression quality for images
    ///   - callback: The callback with the result body and success `Bool`
    public static func upload(_ urlString: String, 
        parameters: [String: String]? = nil, 
        videos: [String: URL]? = nil, 
        images: [String: UIImage]? = nil, 
        audios: [String: URL]? = nil, 
        imageCompressionQuality: Double = 0.95,
        timeoutInterval: TimeInterval = 60.0,
        callback: @escaping (String, Bool) -> ()) {
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                callback("", false)
            }
            return
        }
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeoutInterval
        
        
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        let body = NSMutableData()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
        
        if let images = images {
            for (name, image) in images {
                if let imageData = image.jpegData(compressionQuality: imageCompressionQuality) {
                    body.appendString(string: "--\(boundary)\r\n")
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"image.jpg\"\r\n")
                    body.appendString(string: "Content-Type: image/jpg\r\n\r\n")
                    body.append(imageData as Data)
                    body.appendString(string: "\r\n")
                }
            }
        }
        
        if let videos = videos {
            for (name, video) in videos {
                var videoData: Data?
                do {
                    videoData = try Data(contentsOf: video, options: Data.ReadingOptions.alwaysMapped)
                } catch _ {
                    videoData = nil
                }
                
                if let videoData = videoData {
                    body.appendString(string: "--\(boundary)\r\n")
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"video.mp4\"\r\n")
                    body.appendString(string: "Content-Type: video/mp4\r\n\r\n")
                    body.append(videoData as Data)
                    body.appendString(string: "\r\n")
                }
            }
        }
        
        
        if let audios = audios {
            for (name, audio) in audios {
                var audioData: Data?
                do {
                    audioData = try Data(contentsOf: audio, options: Data.ReadingOptions.alwaysMapped)
                } catch _ {
                    audioData = nil
                }
                
                if let audioData = audioData {
                    body.appendString(string: "--\(boundary)\r\n")
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"audio.m4a\"\r\n")
                    body.appendString(string: "Content-Type: audio/m4a\r\n\r\n")
                    body.append(audioData as Data)
                    body.appendString(string: "\r\n")
                }
            }
        }
        
        body.appendString(string: "--\(boundary)--\r\n")
        
        
        request.httpBody = body as Data
        
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            if response.statusCode != 200 {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            DispatchQueue.main.async {
                callback(dataString, true)
            }
        }
        task.resume()
    }
    
#endif
    
    /// Post a json object with callback http get
    ///
    /// Example:
    ///
    ///     NKHttp.postObject("YOUR_URL", parameters: ["foo": "bar"], type: Model.self) { obj in
    ///         if let obj = obj {
    ///             // Do something with your object
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Post url parameters, default is `nil`
    ///   - type: The model type, needs to conform to `Decodable`
    ///   - callback: The callback with `Optional` object
    public static func postObject<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type, callback: @escaping (T?) -> ()) {
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                callback(nil)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            if response.statusCode != 200 {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            if dataString.isEmpty {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            let jsonData = dataString.data(using: .utf8)
            
            if let jsonData = jsonData {
                do {
                    let data: T = try jsonDecoder.decode(T.self, from: jsonData)
                    DispatchQueue.main.async {
                        callback(data)
                    }
                    return
                } catch {}
            }
            
            DispatchQueue.main.async {
                callback(nil)
            }
        }
        task.resume()
    }
    
    /// Post a json object array with callback http get
    ///
    /// Example:
    ///
    ///     NKHttp.postObjectArray("YOUR_URL", parameters: ["foo": "bar"], type: Model.self) { array in
    ///         if let array = array {
    ///             // Do something with your array
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Post url parameters, default is `nil`
    ///   - type: The model type, needs to conform to `Decodable`
    ///   - callback: The callback with `Optional` object array
    public static func postObjectArray<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type, callback: @escaping ([T]?) -> ()) {
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                callback(nil)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            if response.statusCode != 200 {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            let jsonData = dataString.data(using: .utf8)
            
            if let jsonData = jsonData {
                do {
                    let data: [T] = try jsonDecoder.decode([T].self, from: jsonData)
                    DispatchQueue.main.async {
                        callback(data)
                    }
                    return
                } catch {}
            }
            
            DispatchQueue.main.async {
                callback(nil)
            }
        }
        task.resume()
    }
    
    /// Http post with callback function
    ///
    /// Example:
    ///
    ///     NKHttp.post("YOUR_URL", parameters: ["foo": "bar"]) { result, success in
    ///         if success {
    ///             print(result)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Post url parameters, default is `nil`
    ///   - callback: The callback with result body and success `Bool`
    public static func post(_ urlString: String, parameters: [String: String]? = nil, callback: @escaping (String, Bool) -> ()) {
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                callback("", false)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            if response.statusCode != 200 {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            DispatchQueue.main.async {
                callback(dataString, true)
            }
        }
        task.resume()
    }
}

/// GET callback methods
extension NKHttp {
    
    /// Get a json object with callback http get
    ///
    /// Example:
    ///
    ///     NKHttp.getObject("YOUR_URL", parameters: ["foo": "bar"], type: Model.self) { obj in
    ///         if let obj = obj {
    ///             // Do something with your object
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Get url parameters, default is `nil`
    ///   - type: The model type, needs to conform to `Decodable`
    ///   - callback: The callback with `Optional` object
    public static func getObject<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type, callback: @escaping (T?) -> ()) {
        
        let urlWithParameters = parameters == nil ? urlString : urlString + "?" + buildParameterString(parameters)
        guard let url = URL(string: urlWithParameters) else {
            DispatchQueue.main.async {
                callback(nil)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            if response.statusCode != 200 {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            if dataString.isEmpty {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            let jsonData = dataString.data(using: .utf8)
            
            if let jsonData = jsonData {
                do {
                    let data: T = try jsonDecoder.decode(T.self, from: jsonData)
                    DispatchQueue.main.async {
                        callback(data)
                    }
                    return
                } catch {}
            }
            
            DispatchQueue.main.async {
                callback(nil)
            }
        }
        task.resume()
    }
    
    
    /// Get a json object array with callback http get
    ///
    /// Example:
    ///
    ///     NKHttp.getObjectArray("YOUR_URL", parameters: ["foo": "bar"], type: Model.self) { array in
    ///         if let array = array {
    ///             // Do something with your array
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Get url parameters, default is `nil`
    ///   - type: The model type, needs to conform to `Decodable`
    ///   - callback: The callback with `Optional` object array
    public static func getObjectArray<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type, callback: @escaping ([T]?) -> ()) {
        
        
        let urlWithParameters = parameters == nil ? urlString : urlString + "?" + buildParameterString(parameters)
        guard let url = URL(string: urlWithParameters) else {
            DispatchQueue.main.async {
                callback(nil)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            if response.statusCode != 200 {
                DispatchQueue.main.async {
                    callback(nil)
                }
                return
            }
            
            let jsonData = dataString.data(using: .utf8)
            
            if let jsonData = jsonData {
                do {
                    let data: [T] = try jsonDecoder.decode([T].self, from: jsonData)
                    DispatchQueue.main.async {
                        callback(data)
                    }
                    return
                } catch {}
            }
            
            DispatchQueue.main.async {
                callback(nil)
            }
        }
        task.resume()
    }
    
    
    /// Http get with callback function
    ///
    /// Example:
    ///
    ///     NKHttp.get("YOUR_URL", parameters: ["foo": "bar"]) { result, success in
    ///         if success {
    ///             print(result)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Get url parameters, default is `nil`
    ///   - callback: The callback with result body and success `Bool`
    public static func get(_ urlString: String, parameters: [String: String]? = nil, callback: @escaping (String, Bool) -> ()) {
        
        let urlWithParameters = parameters == nil ? urlString : urlString + "?" + buildParameterString(parameters)
        guard let url = URL(string: urlWithParameters) else {
            DispatchQueue.main.async {
                callback("", false)
            }
            return
        }
        
        // Prepare URL Request Object
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            if response.statusCode != 200 {
                DispatchQueue.main.async {
                    callback("", false)
                }
                return
            }
            
            DispatchQueue.main.async {
                callback(dataString, true)
            }
        }
        task.resume()
    }
}

#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
/// POST async methods
extension NKHttp {
    
#if os(iOS)
    
    @available(iOS 15.0, *)
    /// iOS specific method for uploading videos, images and/or audio files to the server
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Post url parameters, default is `nil`
    ///   - videos: Optional `Array` of video `Url`'s for upload
    ///   - images: Optional `Array` of image `UIImage`'s for upload
    ///   - audios: Optional `Array` of audio `Url`'s for upload
    ///   - imageCompressionQuality: The compression quality for images
    /// - Returns: The result body and success `Bool`
    public static func upload(_ urlString: String, 
        parameters: [String: String]? = nil, 
        videos: [String: URL]? = nil, 
        images: [String: UIImage]? = nil, 
        audios: [String: URL]? = nil, 
        imageCompressionQuality: Double = 0.95,
        timeoutInterval: TimeInterval = 60.0) async throws -> (String, Bool) {
        
        guard let url = URL(string: urlString) else {
            throw NKHttpError.invalidUrl
        }
        
        // Prepare URL Request Object
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        
        
        let boundary = "Boundary-\(NSUUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        let body = NSMutableData()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
        
        if let images = images {
            for (name, image) in images {
                if let imageData = image.jpegData(compressionQuality: imageCompressionQuality) {
                    body.appendString(string: "--\(boundary)\r\n")
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"image.jpg\"\r\n")
                    body.appendString(string: "Content-Type: image/jpg\r\n\r\n")
                    body.append(imageData as Data)
                    body.appendString(string: "\r\n")
                }
            }
        }
        
        if let videos = videos {
            for (name, video) in videos {
                var videoData: Data?
                do {
                    videoData = try Data(contentsOf: video, options: Data.ReadingOptions.alwaysMapped)
                } catch _ {
                    videoData = nil
                }
                
                if let videoData = videoData {
                    body.appendString(string: "--\(boundary)\r\n")
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"video.mp4\"\r\n")
                    body.appendString(string: "Content-Type: video/mp4\r\n\r\n")
                    body.append(videoData as Data)
                    body.appendString(string: "\r\n")
                }
            }
        }
        
        
        if let audios = audios {
            for (name, audio) in audios {
                var audioData: Data?
                do {
                    audioData = try Data(contentsOf: audio, options: Data.ReadingOptions.alwaysMapped)
                } catch _ {
                    audioData = nil
                }
                
                if let audioData = audioData {
                    body.appendString(string: "--\(boundary)\r\n")
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(name)\"; filename=\"audio.m4a\"\r\n")
                    body.appendString(string: "Content-Type: audio/m4a\r\n\r\n")
                    body.append(audioData as Data)
                    body.appendString(string: "\r\n")
                }
            }
        }
        
        body.appendString(string: "--\(boundary)--\r\n")
        
        request.httpBody = body as Data
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let dataString = String(data: data, encoding: .utf8) else {
            throw NKHttpError.decodingDataFailed
        }
        
        guard let response = response as? HTTPURLResponse else {
            throw NKHttpError.responseFailed
        }
        
        return (dataString, response.statusCode == 200)
    }
    
#endif
    
    /// Asynchronous http post
    ///
    /// Example:
    ///
    ///     let (result, success) = NKHttp.await post("YOUR_URL", parameters: ["foo": "bar"])
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Post url parameters, default is `nil`
    /// - Returns: The result body and success `Bool`
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func post(_ urlString: String, parameters: [String: String]? = nil) async throws -> (String, Bool) {
        
        guard let url = URL(string: urlString) else {
            throw NKHttpError.invalidUrl
        }
        
        // Prepare URL Request Object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set HTTP Request Body
        request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let dataString = String(data: data, encoding: .utf8) else {
            throw NKHttpError.decodingDataFailed
        }
        
        guard let response = response as? HTTPURLResponse else {
            throw NKHttpError.responseFailed
        }
        
        return (dataString, response.statusCode == 200)
    }
    
    /// Post a json object with asynchronous http get
    ///
    /// Example:
    ///
    ///     let obj: Model = await NKHttp.postObject("YOUR_URL", parameters: ["foo": "bar"], type: Model.self)
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Post url parameters, default is `nil`
    ///   - type: The model type, needs to conform to `Decodable`
    /// - Returns: Object with the given type
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func postObject<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type) async throws -> T {
        guard let jsonData = try await post(urlString, parameters: parameters).0.data(using: .utf8) else {
            throw NKHttpError.encodingDataFailed
        }
        
        do {
            return try jsonDecoder.decode(T.self, from: jsonData)
        } catch is DecodingError {
            throw NKHttpError.decodingDataFailed
        }
    }
    
    /// Post a json object array with asynchronous http get
    ///
    /// Example:
    ///
    ///     let array: Array<Model> = await NKHttp.postObjectArray("YOUR_URL", parameters: ["foo": "bar"], type: Model.self)
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Post url parameters, default is `nil`
    ///   - type: The model type, needs to conform to `Decodable`
    /// - Returns: Object array with the given type
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func postObjectArray<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type) async throws -> [T] {
        guard let jsonData = try await post(urlString, parameters: parameters).0.data(using: .utf8) else {
            throw NKHttpError.encodingDataFailed
        }
        
        do {
            return try jsonDecoder.decode([T].self, from: jsonData)
        } catch is DecodingError {
            throw NKHttpError.decodingDataFailed
        }
    }
}

/// GET async methods
extension NKHttp {
    
    /// Asynchronous http get
    ///
    /// Example:
    ///
    ///     let (result, success) = await NKHttp.get("YOUR_URL", parameters: ["foo": "bar"])
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Get url parameters, default is `nil`
    /// - Returns: The result body and success `Bool`
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func get(_ urlString: String, parameters: [String: String]? = nil) async throws -> (String, Bool) {
        
        let urlWithParameters = parameters == nil ? urlString : urlString + "?" + buildParameterString(parameters)
        
        guard let url = URL(string: urlWithParameters) else {
            throw NKHttpError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let dataString = String(data: data, encoding: .utf8) else {
            throw NKHttpError.decodingDataFailed
        }
        
        guard let response = response as? HTTPURLResponse else {
            throw NKHttpError.responseFailed
        }
        
        return (dataString, response.statusCode == 200)
    }
    
    /// Get a json object with asynchronous http get
    ///
    /// Example:
    ///
    ///     let obj: Model = await NKHttp.getObject("YOUR_URL", parameters: ["foo": "bar"], type: Model.self)
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Get url parameters, default is `nil`
    ///   - type: The model type, needs to conform to `Decodable`
    /// - Returns: Object with the given type
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func getObject<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type) async throws -> T {
        guard let jsonData = try await get(urlString, parameters: parameters).0.data(using: .utf8) else {
            throw NKHttpError.encodingDataFailed
        }
        
        do {
            return try jsonDecoder.decode(T.self, from: jsonData)
        } catch is DecodingError {
            throw NKHttpError.decodingDataFailed
        }
    }
    
    /// Get a json object array with asynchronous http get
    ///
    /// Example:
    ///
    ///     let array: Array<Model> = await NKHttp.getObjectArray("YOUR_URL", parameters: ["foo": "bar"], type: Model.self)
    ///
    /// - Parameters:
    ///   - urlString: The url as `String`
    ///   - parameters: Get url parameters, default is `nil`
    ///   - type: The model type, needs to conform to `Decodable`
    /// - Returns: Object array with the given type
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func getObjectArray<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type) async throws -> [T] {
        guard let jsonData = try await get(urlString, parameters: parameters).0.data(using: .utf8) else {
            throw NKHttpError.encodingDataFailed
        }
        
        do {
            return try jsonDecoder.decode([T].self, from: jsonData)
        } catch is DecodingError {
            throw NKHttpError.decodingDataFailed
        }
    }
}
#endif

extension NSMutableData {
    func appendString(string: String) {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            append(data)
        }
    }
}
