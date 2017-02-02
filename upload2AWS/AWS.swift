//
//  AWS.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/31/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import AWSCore
import AWSS3

class AWS: NSObject {
    var printCount: Int! = Int()
    var excludeCount: Int! = Int()
    lazy var user: String = {
        return UIDevice.current.identifierForVendor!.uuidString + "/"
    }()
    
    
    static var shared = AWS()
    
    func upload(Object: PhotoObject, folder: Folder) {
        if folder == .print {
            deleteFileFrom(folder: .exclude, Key: Object.id)
            printCount = printCount + 1
        } else {
            deleteFileFrom(folder: .print, Key: Object.id)
            excludeCount = excludeCount + 1
        }
        
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(Object.id)
        
        if let imageData = UIImageJPEGRepresentation(Object.image, 1.0) {
            FileManager.default.createFile(atPath: path as String, contents: imageData, attributes: nil)
            let fileUrl = URL(fileURLWithPath: path)
            buildPresigedURl(Object: Object, fileUrl: fileUrl, folder: folder)
        }
    }

    func getPresignedURL(key: String) -> AWSS3GetPreSignedURLRequest  {
        let preSignedRequest = AWSS3GetPreSignedURLRequest()
        preSignedRequest.contentType = contentType
        preSignedRequest.httpMethod = AWSHTTPMethod.PUT
        preSignedRequest.bucket = bucket
        preSignedRequest.key = key
        preSignedRequest.expires = Date(timeIntervalSinceNow: 3600)
        return preSignedRequest
    }
    
    func buildPresigedURl(Object: PhotoObject, fileUrl: URL, folder: Folder?) {
        var folderRoute: String
        if let folder = folder {
            folderRoute = user + folder.rawValue
        } else {
            folderRoute = user
        }
        
        let preSignedRequest = getPresignedURL(key: folderRoute + Object.id + ext)
        AWSS3PreSignedURLBuilder.default().getPreSignedURL(preSignedRequest).continue({ (task) -> Any? in
            if task.error != nil {
                print("* * * error: \(task.error?.localizedDescription)")
            } else {
                if let presignedURl = task.result as? URL {
                    var request: URLRequest = URLRequest(url: presignedURl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TimeInterval(3600))
                    request.httpMethod = "PUT"
                    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                    
                    let uploadTask = URlSessionManager.shared.backgroundUploadSession.uploadTask(with: request, fromFile: fileUrl)
                    uploadTask.resume()
                }
            }
            return nil
        })
    }
    
    func createFolderWith(folder: Folder) {
        let folderRequest: AWSS3PutObjectRequest = AWSS3PutObjectRequest()
        folderRequest.key = user + folder.rawValue
        folderRequest.bucket = bucket
        AWSS3.default().putObject(folderRequest).continue({ (task) -> Any? in
            task.error != nil ? print("Error:\(task.error?.localizedDescription)") : print(self.user, folder)
            return nil
        })
    }
    
    func createUserSubFolder() {
        let folderRequest: AWSS3PutObjectRequest = AWSS3PutObjectRequest()
        folderRequest.key = user
        folderRequest.bucket = bucket
        AWSS3.default().putObject(folderRequest).continue({ (task) -> Any? in
            task.error != nil ? print("Error:\(task.error?.localizedDescription)") : (print("User:\(self.user)"))
            return nil
        })
    }
    
    func deleteFileFrom(folder: Folder, Key: String) {
        let s3 = AWSS3.default()
        let deleteObjectRequest: AWSS3DeleteObjectRequest = AWSS3DeleteObjectRequest()
        deleteObjectRequest.bucket = bucket
        deleteObjectRequest.key = user + folder.rawValue + Key + ext
        s3.deleteObject(deleteObjectRequest)
    }
    
    func deleteFile(Key: String) {
        deleteFileFrom(folder: .print, Key: Key)
        deleteFileFrom(folder: .exclude, Key: Key)
    }
}
