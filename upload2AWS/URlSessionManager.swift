//
//  URlSessionManager.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/30/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import Foundation
import UIKit

class URlSessionManager: NSObject {
    
    static var shared = URlSessionManager()
    lazy var backgroundUploadSession : URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "BackgroundThreadIdentifier")
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return urlSession
    }()
    
    var responseData        = NSMutableData()
    var thetotalBytesSent   = Int64()
}

extension URlSessionManager: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("session \(session), received response \(response)")
        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        thetotalBytesSent = thetotalBytesSent + totalBytesExpectedToSend
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData.append(data)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                DispatchQueue.main.async (execute: {
                    completionHandler()
                })
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            print("\n ERROR: session: \(session),for task: \(task), \n\n Error Description: \(error?.localizedDescription)")
        } else {
            print("Completed task:\(task.taskIdentifier)")
        }
    }
}
