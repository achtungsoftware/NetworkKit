[![Swift](https://img.shields.io/badge/Swift-5.5-brightgreen.svg?colorA=orange&colorB=4F4F4F)](https://swift.org)
[![Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-brightgreen.svg?colorA=orange&colorB=4F4F4F)](https://www.apache.org/licenses/LICENSE-2.0)
[![](https://img.shields.io/badge/Platform-Linux%20|%20MacOS%20|%20Windows%20|%20iOS-brightgreen.svg?colorA=orange&colorB=4F4F4F)]()

# NetworkKit

NetworkKit is a very high level api for http network requests and is used by Knoggl.

NetworkKit also handles json decoding for you.

# Examples

## Import

```swift
import NetworkKit
```

## Async await

Replace ``post`` with ``get`` to make get requests instead.

```swift
// Post request
let (result, success) = try await NKHttp.post("YOUR_URL_STRING", parameters: ["foo": "bar"])

// Post request (json object model)
let obj: Model = try await NKHttp.postObject("YOUR_URL_STRING", parameters: ["foo": "bar"], type: Model.self)

// Post request (json object model array)
let array: Array<Model> = try await NKHttp.postObjectArray("YOUR_URL_STRING", parameters: ["foo": "bar"], type: Model.self)
```

## With callback / completition

Replace ``post`` with ``get`` to make get requests instead.

```swift
// Post request
NKHttp.post("YOUR_URL_STRING", parameters: ["foo": "bar"]) { result, success in
    if success {
        print(result)
    }
}

// Post request (json object model)
NKHttp.postObject("YOUR_URL_STRING", parameters: ["foo": "bar"], type: Model.self) { object in
    if let object = object {
        // Do something with your object
    }
}

// Post request (json object model array)
NKHttp.postObjectArray("YOUR_URL_STRING", parameters: ["foo": "bar"], type: Model.self) { array in
    if let array = array {
        // Do something with your array
    }
}
```

## Upload
The upload method allows you to upload multiple `UIImages`, video `URLs` and audio `URLs`.
```swift
// Callback
NKHttp.upload("YOUR_URL_STRING", parameters: ["foo": "bar"],
videos: [String: URL], 
images: [String: UIImage], 
audios: [String: URL]) { result, success in
    if success {
        print(result)
    }
}

// Async await
let (result, success) = await NKHttp.upload("YOUR_URL_STRING", parameters: ["foo": "bar"],
videos: [String: URL], 
images: [String: UIImage], 
audios: [String: URL])

if success {
    print(result)
}
```
