//
//  RestClient.swift
//  REST-Test
//
//  Created by Michael Main on 1/8/15.
//  Copyright (c) 2015 Michael Main. All rights reserved.
//

import Foundation

class NBRestResponse {
    var response : HTTPURLResponse?
    var statusCode : Int!
    var contentType : String!
    var headers : Dictionary<String, String>! = [:]
    var body : Data!
    var error : Error?
    
    init(error: Error?) {
        self.error = error
    }
    
    init(statusCode: Int, contentType: String, headers: Dictionary<String, String>, body: Data) {
        self.statusCode = statusCode
        self.contentType = contentType
        self.headers = headers
        self.body = body
    }
    
    init(response: HTTPURLResponse, data: Data?) {
        self.response = response
        self.statusCode = response.statusCode
        self.contentType = response.allHeaderFields["Content-Type"] as? String
        self.body = data
        
        for (key, value) in response.allHeaderFields {
            headers[key as! String] = value as? String
        }
    }
}

class NBRestRequest {
    var request : URLRequest!
    var response : NBRestResponse?
    var error : Error!
    
    var method : String
    var url : String
    var headers : Dictionary<String, String> = [:]
    var contentType: String?
    var acceptType: String?
    var body : String!
    
    var completed : Bool = false
    
    init(method: String, hostname : String, port : String, uri : String, headers : Dictionary<String, String>, body : String, ssl : Bool) {
        url = "http://"
        
        if (ssl) {
            url = "https://"
        }
        
        url += hostname
        
        if (!port.isEmpty) {
            url += ":\(port)"
        }
        
        url += uri
        
        self.body = body
        self.method = method
        
        for (key, value) in headers {
            addHeader(key: key, value: value)
        }
    }
    
    func addHeader(key : String, value : String) -> NBRestRequest {
        if (key == "Content-Type") {
            contentType = value
        } else if (key == "Accept") {
            acceptType = value
        }
        
        headers[key] = value
        return self
    }
    
    func setContentType(contentType: String) -> NBRestRequest {
        self.contentType = contentType
        return self
    }
    
    func setAcceptType(acceptType: String) -> NBRestRequest {
        self.acceptType = acceptType
        return self
    }
    
    private func setupHeaders() {
        if (contentType != nil) {
            request.addValue(contentType!, forHTTPHeaderField: "Content-Type")
        }
        
        if (acceptType == nil) {
            acceptType = "*/*"
        }
        
        request.addValue(acceptType!, forHTTPHeaderField: "Accept")
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
    }
    
    private func setupPayload() {
        request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        
        if (body != nil) {
            if (method != "GET" && method != "DELETE") {
                request.httpBody = body.data(using: String.Encoding.utf8, allowLossyConversion: true)
                addHeader(key: "Content-Length", value: "\(body.lengthOfBytes(using: String.Encoding.utf8))")
            } else {
                url += body.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
                request.url = URL(string: url)
            }
        }
        
        print("\(method) \(request.url)")
    }
    
    func sendSync() -> NBRestResponse! {
        self.response = nil
        self.completed = false
    
        // Send asynchronously, but wait for completion
        sendAsync()
        waitForCompletion()
        return self.response
    }
    
    func sendAsync() -> Void {
        sendAsync(completionHandler: {(response: NBRestResponse!) -> Void in
        })
    }
    
    func sendAsync(completionHandler: @escaping ((NBRestResponse!) -> Void)) -> Void {
        self.response = nil
        self.completed = false
        
        // Setup payload and headers
        setupPayload()
        setupHeaders()
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response:URLResponse?, error: Error?) -> Void in
            if (error != nil || data == nil) {
                self.response = NBRestResponse(error: error)
                self.completed = true
                self.error = error
                
                completionHandler(self.response)
                
                return
            }
            
            let httpResponse: HTTPURLResponse = response as! HTTPURLResponse
            
            self.response = NBRestResponse(response: httpResponse, data: data)
            completionHandler(self.response)
            self.completed = true
        })
        
        task.resume()
    }
    
    func isComplete() -> Bool {
        return completed
    }
    
    func waitForCompletion() {
        while !completed {}
    }
    
    func getResponse() -> Any? {
        return response
    }
}

class NBRestClient {
    class NBMediaType {
        static var APPLICATION_JSON = "application/json"
        static var APPLICATION_XML = "application/xml"
    }
    
    private class func createQueryString(pairs: Dictionary<String, AnyObject>) -> String {
        var query = ""
        var sep = "?"
        
        for (key, value) in pairs {
            query += "\(sep)\(key)=\(value)"
            sep = "&"
        }
        
        return query
    }
    
    class func get(hostname : String, port : String = "", uri : String, headers : Dictionary<String, String> = [:], query : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> NBRestRequest {
        let body = createQueryString(pairs: query)
        return NBRestRequest(method: "GET", hostname: hostname, port: port, uri: uri, headers: headers, body: body, ssl: ssl)
    }
    
    class func put(hostname : String, port : String = "", uri : String, headers : Dictionary<String, String> = [:], body : String = "", ssl : Bool = false) -> NBRestRequest {
        return NBRestRequest(method: "PUT", hostname: hostname, port: port, uri: uri, headers: headers, body: body, ssl: ssl)
    }
    
    class func post(hostname : String, port : String = "", uri : String, headers : Dictionary<String, String> = [:], body : String = "", ssl : Bool = false) -> NBRestRequest {
        return NBRestRequest(method: "POST", hostname: hostname, port: port, uri: uri, headers: headers, body: body, ssl: ssl)
    }
    
    class func delete(hostname : String, port : String = "", uri : String, headers : Dictionary<String, String> = [:], query : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> NBRestRequest {
        let body = createQueryString(pairs: query)
        return NBRestRequest(method: "DELETE", hostname: hostname, port: port, uri: uri, headers: headers, body: body, ssl: ssl)
    }
}
