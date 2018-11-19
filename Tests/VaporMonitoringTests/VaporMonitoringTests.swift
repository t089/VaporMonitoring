import XCTest
@testable import VaporMonitoring
import SwiftMetrics
@testable import Vapor

typealias Configure = (inout Config, inout Environment, inout Services) throws -> ()

extension Application {
    static func testable(configure: Configure, boot: (Application) throws -> ()) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        try configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        try boot(app)
        return app
    }
    
    func sendRequest<Body>(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: Body?, isLoggedInRequest: Bool = false) throws -> Response where Body: Content {
        let httpRequest = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: httpRequest, using: self)
        if let body = body {
            try wrappedRequest.content.encode(body)
        }
        let responder = try make(Responder.self)
        return try responder.respond(to: wrappedRequest).wait()
    }
}

class VaporMonitoringTests: XCTestCase {
    
    var app: Application!
    
    override func setUp() {
        super.setUp()
        
        
        
    }

	func testCounterFull() throws {
        app = try! Application.testable(configure: { (config, env, services) in
            var middlewareConfig = MiddlewareConfig()
            let router = try VaporMonitoring.setupMonitoring(&config, &services, &middlewareConfig)
            
            // Add your own middleware here
            services.register(middlewareConfig)
            
            router.get("test", use: { _ in return HTTPStatus.ok })
            services.register(router, as: Router.self)
        }, boot: { app in })
        
        let key = "test 200 GET"
        
        XCTAssertNil(httpCounter.handlers[key])
        try _ = app.sendRequest(to: "test", method: .GET, body: nil as String?)
        let handler = httpCounter.handlers[key]!
        XCTAssertEqual(handler.count, 1)
	}
    
    func testCounterSimple() throws {
        let counter = HTTPCounter()
        
        let key = "test 200 GET"
        XCTAssertNil(counter.handlers[key])
        
        counter.addRequest(url: "test", statusCode: 200, requestMethod: "GET")
        
        let handler = counter.handlers[key]!
        XCTAssertEqual(handler.count, 1)
    }
    
    func testCounterSimpleSecondRequest() throws {
        let counter = HTTPCounter()
        
        let key = "test 200 GET"
        XCTAssertNil(counter.handlers[key])
        
        counter.addRequest(url: "test", statusCode: 200, requestMethod: "GET")
        
        let handler = counter.handlers[key]!
        XCTAssertEqual(handler.count, 1)
        
        counter.addRequest(url: "test", statusCode: 200, requestMethod: "GET")
        
        XCTAssertEqual(handler.count, 2)
    }

	static let allTests = [
         ("testCounterFull", testCounterFull),
         ("testCounterSimple", testCounterSimple),
         ("testCounterSimpleSecondRequest", testCounterSimpleSecondRequest)
    ]
}
