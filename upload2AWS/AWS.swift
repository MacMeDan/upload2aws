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
    let contentType   = "image/jpeg"
    let ext           = ".jpg"
    let bucket        = "upload2aws"
    
    lazy var user: String = {
        return UIDevice.current.identifierForVendor!.uuidString + "/"
    }()
    
    
    static var shared = AWS()
    
    func upload(Object: PhotoObject, folder: String?) {
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
    
    func buildPresigedURl(Object: PhotoObject, fileUrl: URL, folder: String?) {
        var folderRoute: String
        if let folder = folder {
            folderRoute = user + folder
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
                    request.setValue(self.contentType, forHTTPHeaderField: "Content-Type")
                    
                    let uploadTask = URlSessionManager.shared.backgroundUploadSession.uploadTask(with: request, fromFile: fileUrl)
                    uploadTask.resume()
                }
            }
            return nil
        })
    }
    
    func createFolderWith(Name: String!) {
        let folderRequest: AWSS3PutObjectRequest = AWSS3PutObjectRequest()
        folderRequest.key = user + Name
        folderRequest.bucket = bucket
        AWSS3.default().putObject(folderRequest).continue({ (task) -> Any? in
            task.error != nil ? print("Error:\(task.error?.localizedDescription)") : print(self.user, Name)
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
    
    func deleteFile(Key: String) {
        let s3 = AWSS3.default()
        let deleteObjectRequest: AWSS3DeleteObjectRequest = AWSS3DeleteObjectRequest()
        deleteObjectRequest.bucket = bucket
        //deleteObjectRequest.key = user + Key + ext
        //s3.deleteObject(deleteObjectRequest)
        deleteObjectRequest.key = user + printFolder + Key + ext
        s3.deleteObject(deleteObjectRequest)
        deleteObjectRequest.key = user + excludeFolder + Key + ext
        s3.deleteObject(deleteObjectRequest)
    }
}
