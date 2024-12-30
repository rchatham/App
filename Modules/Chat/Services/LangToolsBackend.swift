//
//  LangToolsBackend.swift
//  App
//
//  Created by Reid Chatham on 12/8/24.
//
import Foundation
import LangTools
import OpenAI
import Anthropic


public final class LangToolsBackend: LangTools {
    public typealias ErrorResponse = LangToolsBackendErrorResponse

    public static let url: URL = URL(string: "http://localhost:8080/v1/")!

    public var streamManager: StreamSessionManager<LangToolsBackend> = StreamSessionManager()
    public lazy var session: URLSession = {
       // URLProtocol.registerClass(HostInterceptorProtocol.self)
        let config = URLSessionConfiguration.ephemeral
       // config.protocolClasses = [HostInterceptorProtocol.self]
        return URLSession(configuration: config, delegate: streamManager, delegateQueue: nil)
    }()

    public func prepare(request: some LangToolsRequest) throws -> URLRequest {
        var urlRequest = URLRequest(url: Self.url.appending(path: request.path))
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
        do { urlRequest.httpBody = try JSONEncoder().encode(request) } catch { throw LangToolError<ErrorResponse>.invalidData }
        return urlRequest
    }

    public static func processStream(data: Data, completion: @escaping (Data) -> Void) {
        String(data: data, encoding: .utf8)?.split(separator: "\n").filter{ $0.hasPrefix("data:") && !$0.contains("[DONE]") }.forEach { completion(Data(String($0.dropFirst(5)).utf8)) }
    }

    public var requestTypes: [(any LangToolsRequest) -> Bool] {
        return [
            { ($0 as? OpenAI.ChatCompletionRequest) != nil },
            { ($0 as? OpenAI.AudioSpeechRequest) != nil },
            { ($0 as? Anthropic.MessageRequest) != nil }
        ]
    }
}


public struct LangToolsBackendErrorResponse: Error, Codable {
    public let type: String?
    public let error: APIError

    public struct APIError: Error, Codable {
        public let message: String
        public let type: String
        public let param: String?
        public let code: String?
    }
}


/// A custom URLProtocol subclass to intercept and modify HTTP requests
class HostInterceptorProtocol: URLProtocol {

    // Configuration for hostname replacement
    static var replacementHosts: [String: String] = [
        "api.openai.com"    : "localhost",
        "api.anthropic.com" : "localhost"
    ]

    /// Override to determine if the protocol can handle the given request
    override class func canInit(with request: URLRequest) -> Bool {
        // Only intercept HTTP and HTTPS requests
        guard let url = request.url,
              let scheme = url.scheme,
              (scheme == "http" || scheme == "https") else {
            return false
        }

        // Check if the host needs to be replaced
        return replacementHosts.keys.contains(url.host() ?? "")
    }

    /// Modify the request before sending
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        guard var url = request.url,
              let originalHost = url.host,
              let replacementHost = replacementHosts[originalHost] else {
            return request
        }

        // Create a new URL with the replacement host
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "http"
        components?.host = replacementHost

        if replacementHost == "localhost" {
            components?.port = 8080
        }

        guard let modifiedURL = components?.url else {
            return request
        }

        var mutableRequest = request
        mutableRequest.url = modifiedURL

        print("Intercepted request: \(originalHost) -> \(replacementHost)")

        return mutableRequest
    }

    /// Start loading the request
    override func startLoading() {

        // Create a session configuration to use this protocol
        let session = URLSession(configuration: .default)
        let request = Self.canonicalRequest(for: request)
        print("host: " + (request.url?.host() ?? "no host"))
        // Create a data task to perform the request
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self else { return }

            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }

            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
            }

            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }

            self.client?.urlProtocolDidFinishLoading(self)
        }

        task.resume()
    }

    /// Stop loading the request
    override func stopLoading() {
        // Any cleanup required when loading is stopped
    }
}
