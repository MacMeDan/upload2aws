////
////  TaskManager.swift
////  upload2AWS
////
////  Created by P D Leonard on 1/30/17.
////  Copyright © 2017 MacMeDan. All rights reserved.
////
//
//import Foundation
//
//class TaskManager: NSObject {
//    static var shared = TaskManager()
//    lazy var uploadSession : URLSession = {
//        let configuration = URLSessionConfiguration.background(withIdentifier: "BackgroundThreadIdentifier")
//        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//        return urlSession
//    }()
//    
//    var allTasks = [String: URLSessionUploadTask]()
//    var responseData        = NSMutableData()
//    var thetotalBytesSent               = Int64()
//    var activeTasks         = NSMutableSet()
//    
//    func manageActiveTasks() {
//        if allTasks.isEmpty != true {
//            if let nextTask = self.allTasks.first {
//                self.allTasks.removeValue(forKey: nextTask.key)
//                self.activeTasks.add(nextTask.key)
//                nextTask.value.resume()
//            }
//        }
//        //displayImagePickerButtonTapped()
//    }
//    
//}
//
//extension TaskManager: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
//    
//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//        print("session \(session), received response \(response)")
//        completionHandler(Foundation.URLSession.ResponseDisposition.allow)
//    }
//    
//    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
//        thetotalBytesSent = thetotalBytesSent + totalBytesExpectedToSend
//        print(thetotalBytesSent)
//    }
//    
//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//        responseData.append(data)
//    }
//    
//    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
//            if let completionHandler = appDelegate.backgroundSessionCompletionHandler {
//                appDelegate.backgroundSessionCompletionHandler = nil
//                DispatchQueue.main.async (execute: {
//                    completionHandler()
//                })
//            }
//        }
//    }
//    
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        if error != nil {
//            print("\n ERROR: session: \(session),for task: \(task), \n\n Error Description: \(error?.localizedDescription)")
//        } else {
//            
//            let object = String(task.taskIdentifier)
//            activeTasks.remove(object)
//            manageActiveTasks()
//            //photosUploaded = photosUploaded + 1
//            // Update Progress Bar
////            DispatchQueue.main.async (execute: {
////                //let uploadProgress: Float = Float(self.photosUploaded) / Float(self.photosToUpload)
////                //self.progressView.progress = uploadProgress
////                let formated = String(format: "%.0f", uploadProgress * 100)
////                //self.amountUploaded.text = "\(formated)%"
////            })
//            
//            let now = Date()
//            let time = DateFormatter.localizedString(from: now, dateStyle: .none, timeStyle: .long)
//            print("Task:\(task.taskIdentifier) completed at, Time:\(time)")
//        }
//    }
//}
