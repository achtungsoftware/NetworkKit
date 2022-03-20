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
import SwiftPlus

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if os(iOS)
import UIKit
#endif

/// A class for handling http requests and json encoding
public class NKHttp {
    
    /// Creates an parameter string from a dictionary and applies url encoding to the value
    /// - Parameter parameters: The parameter dictionary
    /// - Returns: An encoded String for url paramater
    public static func buildParameterString(_ parameters: [String: String]?) -> String {
        var postData = ""
        if let parameters = parameters {
            for (key, value) in parameters {
                postData.append("\(key)=\(value.urlEncode())&")
            }
        }
        
        return String(postData.dropLast())
    }
}

// POST CALLBACK
extension NKHttp {
    
#if os(iOS)
    /// This function uploads mutiple media to the server (Audio, Video, Image)
    /// - Parameters:
    ///   - urlString: The Api url
    ///   - parameters: Post parameters
    ///   - videos: An Array of video asset urls
    ///   - images: An Array of images
    ///   - audios: An Array of audio asset urls
    ///   - thread: The ``CUThreadHelper`` async thread for processing
    ///   - callback: Callback with the result String and success Bool
    @available(iOS 7.0, *)
    public static func upload(_ urlString: String, parameters: [String: String]? = nil, videos: [String: URL]? = nil, images: [String: UIImage]? = nil, audios: [String: URL]? = nil, thread: SPThreadHelper.async = .background, callback: @escaping (String, Bool) -> ()) {
        thread.run {
            
            guard let url = URL(string: urlString) else {
                SPThreadHelper.async.main.run {
                    callback("", false)
                }
                return
            }
            
            let request = NSMutableURLRequest(url: url)
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
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
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
                
                // Check if Error took place
                if error != nil {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                // Read HTTP Response Status code
                guard let response = response as? HTTPURLResponse else {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                // Check if data is valid
                guard let data = data else {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                // Convert HTTP Response Data to a simple String
                guard let dataString = String(data: data, encoding: .utf8) else {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                // Check if HTTP-STATUS-CODE is OK (200)
                if response.statusCode != 200 {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                SPThreadHelper.async.main.run {
                    callback(dataString, true)
                }
            }
            
            task.resume()
        }
    }
    
#endif
    
    /// This function makes an http post request and trys to encode the result to an object
    /// - Parameters:
    ///   - urlString: The Api url
    ///   - parameters: Post parameters
    ///   - thread: The ``CUThreadHelper`` async thread for processing
    ///   - callback: Callback with the object, the result String and success Bool
    public static func postObject<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type, thread: SPThreadHelper.async = .utility, callback: @escaping (T?, String, Bool) -> ()){
        thread.run {
            
            guard let url = URL(string: urlString) else {
                SPThreadHelper.async.main.run {
                    callback(nil, "", false)
                }
                return
            }
            
            // Prepare URL Request Object
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Set HTTP Request Body
            request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
            
            // Perform HTTP Request
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                // Check if Error took place
                if error != nil {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                // Read HTTP Response Status code
                guard let response = response as? HTTPURLResponse else {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                // Check if data is valid
                guard let data = data else {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                // Convert HTTP Response Data to a simple String
                guard let dataString = String(data: data, encoding: .utf8) else {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                // Check if HTTP-STATUS-CODE is OK (200)
                if response.statusCode != 200 {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                if dataString.isEmpty {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                let jsonData = dataString.data(using: .utf8)
                
                if let jsonData = jsonData {
                    do {
                        let data: T = try JSONDecoder().decode(T.self, from: jsonData)
                        SPThreadHelper.async.main.run {
                            callback(data, dataString, true)
                        }
                        return
                    } catch {}
                }
                
                SPThreadHelper.async.main.run {
                    callback(nil, "", false)
                }
            }
            task.resume()
        }
    }
    
    /// This function makes an http post request and trys to encode the result to an object array
    /// - Parameters:
    ///   - urlString: The Api url
    ///   - parameters: Post parameters
    ///   - thread: The ``CUThreadHelper`` async thread for processing
    ///   - callback: Callback with the object array, the result String and success Bool
    public static func postObjectArray<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type, thread: SPThreadHelper.async = .utility, callback: @escaping ([T]?, String, Bool) -> ()){
        
        thread.run {
            guard let url = URL(string: urlString) else {
                SPThreadHelper.async.main.run {
                    callback(nil, "", false)
                }
                return
            }
            
            // Prepare URL Request Object
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Set HTTP Request Body
            request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
            
            // Perform HTTP Request
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                // Check if Error took place
                if error != nil {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                // Read HTTP Response Status code
                guard let response = response as? HTTPURLResponse else {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                // Check if data is valid
                guard let data = data else {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                // Convert HTTP Response Data to a simple String
                guard let dataString = String(data: data, encoding: .utf8) else {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                // Check if HTTP-STATUS-CODE is OK (200)
                if response.statusCode != 200 {
                    SPThreadHelper.async.main.run {
                        callback(nil, "", false)
                    }
                    return
                }
                
                let jsonData = dataString.data(using: .utf8)
                
                if let jsonData = jsonData {
                    do {
                        let data: [T] = try JSONDecoder().decode([T].self, from: jsonData)
                        SPThreadHelper.async.main.run {
                            callback(data, dataString, true)
                        }
                        return
                    } catch {}
                }
                
                SPThreadHelper.async.main.run {
                    callback(nil, "", false)
                }
            }
            task.resume()
        }
    }
    
    /// This function makes an http post request
    /// - Parameters:
    ///   - urlString: The Api url
    ///   - parameters: Post parameters
    ///   - thread: The ``CUThreadHelper`` async thread for processing
    ///   - callback: Callback with the result String and success Bool
    public static func post(_ urlString: String, parameters: [String: String]? = nil, thread: SPThreadHelper.async = .utility, callback: @escaping (String, Bool) -> ()){
        thread.run {
            
            guard let url = URL(string: urlString) else {
                SPThreadHelper.async.main.run {
                    callback("", false)
                }
                return
            }
            
            // Prepare URL Request Object
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Set HTTP Request Body
            request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
            
            // Perform HTTP Request
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                
                // Check if Error took place
                if error != nil {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                // Read HTTP Response Status code
                guard let response = response as? HTTPURLResponse else {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                // Check if data is valid
                guard let data = data else {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                // Convert HTTP Response Data to a simple String
                guard let dataString = String(data: data, encoding: .utf8) else {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                // Check if HTTP-STATUS-CODE is OK (200)
                if response.statusCode != 200 {
                    SPThreadHelper.async.main.run {
                        callback("", false)
                    }
                    return
                }
                
                SPThreadHelper.async.main.run {
                    callback(dataString, true)
                }
            }
            task.resume()
        }
    }
}

// POST ASYNC
extension NKHttp {
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func post(_ urlString: String, parameters: [String: String]? = nil) async -> (String, Bool) {
        
        guard let url = URL(string: urlString) else { return ("", false) }
        
        // Prepare URL Request Object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set HTTP Request Body
        request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let dataString = String(data: data, encoding: .utf8) else { return ("", false) }
            guard let response = response as? HTTPURLResponse else { return ("", false) }
            
            return (dataString, response.statusCode == 200)
        } catch {
            return ("", false)
        }
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func postObjectArray<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type) async -> ([T]?, String, Bool) {
        
        guard let url = URL(string: urlString) else { return (nil, "", false) }
        
        // Prepare URL Request Object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set HTTP Request Body
        request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let dataString = String(data: data, encoding: .utf8) else { return (nil, "", false) }
            guard let response = response as? HTTPURLResponse else { return (nil, "", false) }
            guard let jsonData = dataString.data(using: .utf8) else { return (nil, "", false) }
            
            do {
                let data: [T] = try JSONDecoder().decode([T].self, from: jsonData)
                
                return (data, dataString, response.statusCode == 200)
            } catch {
                return (nil, "", false)
            }
        } catch {
            return (nil, "", false)
        }
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func postObject<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type) async -> (T?, String, Bool) {
        
        guard let url = URL(string: urlString) else { return (nil, "", false) }
        
        // Prepare URL Request Object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set HTTP Request Body
        request.httpBody = buildParameterString(parameters).data(using: String.Encoding.utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let dataString = String(data: data, encoding: .utf8) else { return (nil, "", false) }
            guard let response = response as? HTTPURLResponse else { return (nil, "", false) }
            guard let jsonData = dataString.data(using: .utf8) else { return (nil, "", false) }
            
            do {
                let data: T = try JSONDecoder().decode(T.self, from: jsonData)
                
                return (data, dataString, response.statusCode == 200)
            } catch {
                return (nil, "", false)
            }
        } catch {
            return (nil, "", false)
        }
    }
}

/// GET ASYNC
extension NKHttp {
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func get(_ urlString: String, parameters: [String: String]? = nil) async -> (String, Bool) {
        
        let urlWithParameters = parameters == nil ? urlString : urlString + "?" + buildParameterString(parameters)
        guard let url = URL(string: urlWithParameters) else { return ("", false) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let dataString = String(data: data, encoding: .utf8) else { return ("", false) }
            guard let response = response as? HTTPURLResponse else { return ("", false) }
            
            return (dataString, response.statusCode == 200)
        } catch {
            return ("", false)
        }
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func getObject<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type) async -> T? {
        
        let urlWithParameters = parameters == nil ? urlString : urlString + "?" + buildParameterString(parameters)
        guard let url = URL(string: urlWithParameters) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let dataString = String(data: data, encoding: .utf8) else { return nil }
            guard let jsonData = dataString.data(using: .utf8) else { return nil }
            
            do {
                return try JSONDecoder().decode(T.self, from: jsonData)
            } catch {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public static func getObjectArray<T: Decodable>(_ urlString: String, parameters: [String: String]? = nil, type: T.Type) async -> [T]? {
        
        let urlWithParameters = parameters == nil ? urlString : urlString + "?" + buildParameterString(parameters)
        guard let url = URL(string: urlWithParameters) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let dataString = String(data: data, encoding: .utf8) else { return nil }
            guard let jsonData = dataString.data(using: .utf8) else { return nil }
            
            do {
                return try JSONDecoder().decode([T].self, from: jsonData)
            } catch {
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension NSMutableData {
    func appendString(string: String) {
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            append(data)
        }
    }
}
