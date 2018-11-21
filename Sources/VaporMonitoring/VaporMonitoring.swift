//
//  VaporMonitoring.swift
//  VaporMonitoring
//
//  Created by Jari Koopman on 29/05/2018.
//

import Foundation
import SwiftMetrics
import Vapor
import Leaf

/// Provides configuration for VaporMonitoring
public struct MonitoringConfig {
    /// Wether or not to create the VaporMetricsDashboard
    var dashboard: Bool
    /// Wether or not to serve Prometheus data
    var prometheus: Bool
    /// At what route to host the dashboard
    var dashboardRoute: String
    /// At what route to host the Prometheus data
    var prometheusRoute: String
    
    /// A function that can process `RequestData` before it is logged
    public var processRequestData: ((Request, inout RequestData) -> ())?
    
    public init(dashboard: Bool, prometheus: Bool, dashboardRoute: String, prometheusRoute: String) {
        self.dashboard = dashboard
        self.prometheus = prometheus
        self.dashboardRoute = dashboardRoute
        self.prometheusRoute = prometheusRoute
    }
    
    public static func `default`() -> MonitoringConfig {
        return .init(dashboard: true, prometheus: true, dashboardRoute: "", prometheusRoute: "")
    }
}

/// Vapor Monitoring class
/// Used to set up monitoring/metrics on your Vapor app
public final class VaporMonitoring {    
    /// Sets up config & services to monitor your Vapor app
    public static func setupMonitoring(_ config: inout Config, _ services: inout Services, _ middlewareConfig: inout MiddlewareConfig, _ monitorConfig: MonitoringConfig = .default()) throws -> MonitoredRouter {
        
        services.register { (container) -> (MonitoredResponder) in
            let responder = try MonitoredResponder.makeService(for: container)
            responder.processRequestData = monitorConfig.processRequestData
            return responder
        }
        
        config.prefer(MonitoredResponder.self, for: Responder.self)
        
        let metrics = try SwiftMetrics()
        services.register(metrics)
        
        let router = try MonitoredRouter()
        config.prefer(MonitoredRouter.self, for: Router.self)
        
        if monitorConfig.dashboard && publicDir != "" {
            let publicDir = getPublicDir()
            let fileMiddelware = FileMiddleware(publicDirectory: publicDir)
            
            middlewareConfig.use(fileMiddelware)
            
            let dashboard = try VaporMetricsDash(metrics: metrics, router: router, route: monitorConfig.dashboardRoute)
            services.register(dashboard)
            let metricsServer = MetricsWebSocketServer()
            metricsServer.get(dashboard.route, use: dashboard.socketHandler)
            services.register(metricsServer, as: WebSocketServer.self)
        }
        
        if monitorConfig.prometheus {
            let prometheus = try VaporMetricsPrometheus(metrics: metrics, router: router, route: monitorConfig.prometheusRoute)
            services.register(prometheus)
        }
        
        return router
    }
    
    /// Sets up config & services to monitor your Vapor app
    public static func setupMonitoring(_ config: inout Config, _ services: inout Services, _ monitorConfig: MonitoringConfig = .default()) throws -> MonitoredRouter {
        var middlewareConfig = MiddlewareConfig()
        let router = try self.setupMonitoring(&config, &services, &middlewareConfig, monitorConfig)
        services.register(middlewareConfig)
        return router
    }
    
    static public var publicDir: String {
        return getPublicDir()
    }
    
    static func getPublicDir() -> String {
        return DirectoryConfig.detect().workDir.appending("Public/metrics")
    }
}

/// Data collected from each request
public struct RequestData: SMData {
    public var timestamp: Int
    public var url: String
    public var requestDuration: Double
    public var statusCode: UInt
    public var method: HTTPMethod
}

/// Log of request
internal struct RequestLog {
    var request: Request
    var timestamp: Double
}

/// Log of requests
internal var requestsLog = [RequestLog]()

/// Timestamp for refference
internal var timeIntervalSince1970MilliSeconds: Double {
    var time = timeval()
    if gettimeofday(&time, nil) == -1 {
        preconditionFailure("Could not get time of day.")
    }
    return Double(time.tv_sec) * 1_000.0 + Double(time.tv_usec) / 1_000.0
}

internal var requestLogQueue = DispatchQueue(label: "requestLogQueue")
