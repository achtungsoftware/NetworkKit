import XCTest
@testable import NetworkKit

struct Httpbin {
    
    static let POST_URL = "https://httpbin.org/post"
    static let GET_URL = "https://httpbin.org/get"
    
    struct Post: Codable {
        let url: String
        let form: Form
        
        struct Form: Codable {
            let foo: String
        }
    }
    
    struct Get: Codable {
        let url: String
        let args: Args
        
        struct Args: Codable {
            let foo: String
        }
    }
}

struct FakeModel: Codable {
    let fakeProp: String
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
final class NetworkKitTests: XCTestCase {
    
    func test_post_object_callback() throws {
        let expectation = expectation(description: "Http.post.object.callback")
        NKHttp.postObject(Httpbin.POST_URL, parameters: ["foo": "bar"], type: Httpbin.Post.self) { object in
            XCTAssertEqual(object?.form.foo, "bar")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_get_object_callback() throws {
        let expectation = expectation(description: "Http.get.object.callback")
        NKHttp.getObject(Httpbin.GET_URL, parameters: ["foo": "bar"], type: Httpbin.Get.self) { object in
            XCTAssertEqual(object?.args.foo, "bar")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func test_post_object_async() async throws {
        let object = try await NKHttp.postObject(Httpbin.POST_URL, parameters: ["foo": "bar"], type: Httpbin.Post.self)
        XCTAssertEqual(object.form.foo, "bar")
    }
    
    func test_get_object_async() async throws {
        let object = try await NKHttp.getObject(Httpbin.GET_URL, parameters: ["foo": "bar"], type: Httpbin.Get.self)
        XCTAssertEqual(object.args.foo, "bar")
    }
    
    func test_post_decodingDataFailed_object_async() async throws {
        do {
            let _ = try await NKHttp.postObject(Httpbin.POST_URL, parameters: ["foo": "bar"], type: FakeModel.self)
        }
        catch {
            XCTAssertEqual(error as! NKHttpError, NKHttpError.decodingDataFailed)
        }
    }
    
    func test_get_decodingDataFailed_object_async() async throws {
        do {
            let _ = try await NKHttp.getObject(Httpbin.GET_URL, parameters: ["foo": "bar"], type: FakeModel.self)
        }
        catch {
            XCTAssertEqual(error as! NKHttpError, NKHttpError.decodingDataFailed)
        }
    }
    
    func test_post_async() async throws {
        let (result, success) = try await NKHttp.post(Httpbin.POST_URL, parameters: ["foo": "bar"])
        XCTAssertTrue(success)
        XCTAssertNotEqual(result, "")
    }
    
    func test_get_async() async throws {
        let (result, success) = try await NKHttp.get(Httpbin.GET_URL, parameters: ["foo": "bar"])
        XCTAssertTrue(success)
        XCTAssertNotEqual(result, "")
    }
}
