//
//  ViewController.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/20/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import UIKit
import AWSCore
import AWSS3
import Photos
import SnapKit

struct PhotoObject {
    let image: UIImage
    let id: String
}

class ViewController: UIViewController {

    var testResults         = UILabel()
    var amountUploaded      = UILabel()
    var responseData        = NSMutableData()
    var progressView        = UIProgressView()
    let activeTasks         = NSMutableSet()
    var firstTime           = true
    var startTime           = Date()
    var endTime             = Date()
    var photosUploaded      = Int()
    var photosToUpload      = Int()
    var thetotalBytesSent   = Int64()
    var downloadedImages    = [UIImage]()
    var photoObjectList:    [PhotoObject] = []
    var allTasks            = [String: URLSessionUploadTask]()
    var photoKeys:          [String] = []
    let ext                 = ".jpg"
    let bucket              = "upload2aws"
    let contentType         = "image/jpeg"
    let reuseIdentifier     = "PhotoCell"
    
    var collectionView:     UICollectionView!
    let statsbutton         = UIButton()
    
    
    // For testing only 100 photos
    let albumName = "GarffFam2016"
    
    lazy var uploadSession : URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "BackgroundThreadIdentifier")
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return urlSession
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BGAudio.shared.setupAudioSession()
        _ = self.uploadSession
        setUpView()
    }
    
    fileprivate func setUpView() {
        photosUploaded = 0
        photosToUpload = 0
        photoKeys = []
        prepareAmountUploaded()
        prepareTestResults()
        photoObjectList = [PhotoObject]()
        prepareProgressView()
        prepareCollectionView()
        prepareUploadButton()
        prepareDownloadButton()
        prepareStatsButton()
        prepareChinderButton()
        //syncPhotos()
        onlySync100Photos()
    }
    
    
    func syncPhotos() {
        // Gets all photos off of phone.
        let imgManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .exact
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        results.enumerateObjects({(object: AnyObject!, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if object is PHAsset{
                let asset = object as! PHAsset
                imgManager.requestImage(for: asset, targetSize: CGSize(width: 240, height: 240), contentMode: .aspectFit, options: requestOptions, resultHandler: { (image, info) in
                    let idString = asset.localIdentifier
                    let indexOfCharicter = idString.components(separatedBy: "/")
                    if let image = image, let id = indexOfCharicter.first {
                        self.addImgToArray(uploadImage: image, id: id)
                    }
                })
            }
        })
    }
    
    // #MARK: Prepare UI
    fileprivate func prepareAmountUploaded() {
        view.addSubview(amountUploaded)
        amountUploaded.text = "0/0"
        amountUploaded.font = UIFont.systemFont(ofSize: 14)
        amountUploaded.textAlignment = .center
        amountUploaded.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
            make.height.equalTo(40)
            make.width.equalToSuperview()
        }
    }
    
    func prepareTestResults() {
        view.addSubview(testResults)
        testResults.text = ""
        testResults.font = UIFont.systemFont(ofSize: 12)
        testResults.textAlignment = .center
        testResults.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(65)
            make.height.equalTo(40)
            make.width.equalToSuperview()
        }
    }
    
    fileprivate func prepareCollectionView() {
        // This Determins the size of each cell in the collection view
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        layout.itemSize = CGSize(width: view.bounds.width/3 - 8, height: view.bounds.width/3 - 8)
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 190, width: view.bounds.width, height: view.bounds.height - 190), collectionViewLayout: layout)
        
        view.addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.white
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    fileprivate func prepareProgressView() {
        view.addSubview(progressView)
        progressView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(70)
            make.centerX.equalToSuperview()
        }
    }
    
    func photoForIndexPath(_ indexPath: IndexPath) -> UIImage {
        return downloadedImages[indexPath.item]
    }
    
    func evaluateTestResults() {
        let start = Date()
        
        if firstTime {
            startTime = start
            endTime = start
            BGAudio.shared.playYesMeLord()
        }
        
        if allTasks.count <= 5 && activeTasks.count <= 5 {
            endTime = firstTime ? start : Date()
            let rawS = Calendar.current.dateComponents([.second], from: startTime, to: endTime).second ?? 0
            let seconds = rawS % 60
            let duration = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute ?? 0
            DispatchQueue.main.async (execute: {
                self.testResults.text = "Test took: \(duration)min and \(seconds)s"
            })
        }
        firstTime = false
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
    
    func displayImagePickerButtonTapped() {
        evaluateTestResults()
        if photoObjectList.first != nil {
            if let object = photoObjectList.first {
                photoObjectList.removeFirst()
                let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(object.id)
                let imageData = UIImageJPEGRepresentation(object.image, 1.0)
                
                if imageData == nil {
                    // This filters out any Assets that have 0 data for an Image saving us uploading empty files to S3
                    displayImagePickerButtonTapped()
                    photosToUpload = photosToUpload - 1
                    return
                }
                
                FileManager.default.createFile(atPath: path as String, contents: imageData, attributes: nil)
                let fileUrl = URL(fileURLWithPath: path)
                
                let preSignedRequest = getPresignedURL(key: object.id + ext)
                AWSS3PreSignedURLBuilder.default().getPreSignedURL(preSignedRequest).continue({ (task) -> Any? in
                    if task.error != nil {
                        print("* * * error: \(task.error?.localizedDescription)")
                    } else {
                        if let presignedURl = task.result as? URL {
                            let request = NSMutableURLRequest(url: presignedURl)
                            request.cachePolicy = .reloadIgnoringLocalCacheData
                            request.httpMethod = "PUT"
                            request.setValue(self.contentType, forHTTPHeaderField: "Content-Type")
                            
                            let uploadTask = self.uploadSession.uploadTask(with: request as URLRequest, fromFile: fileUrl)
                            let id = String(uploadTask.taskIdentifier)
                            uploadTask.resume()
//                            self.allTasks[id] = uploadTask
//                            self.manageActiveTasks()
                        }
                    }
                    return nil
                })
            }
        }
    }
    
    func manageActiveTasks() {
        if activeTasks.count < 50 {
            if allTasks.isEmpty != true {
            if let nextTask = self.allTasks.first {
                self.allTasks.removeValue(forKey: nextTask.key)
                self.activeTasks.add(nextTask.key)
                nextTask.value.resume()
                }
            }
        }
        displayImagePickerButtonTapped()
    }
    
    func getButton() -> UIButton {
        let button = UIButton()
        //Chatbooks Green
        button.backgroundColor = UIColor.RGB(168, greenValue: 217, blueValue: 210, alpha: 1)
        
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.width.equalTo(180)
            make.height.equalTo(40)
        }
        return button
    }
    
    func prepareUploadButton() {
        let button = getButton()
        button.setTitle("Trigger upload", for: .normal)
        button.addTarget(self, action: #selector(displayImagePickerButtonTapped), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(100)
        }
    }
    
    func prepareChinderButton() {
        let button = getButton()
        button.setTitle("Chinder", for: .normal)
        button.addTarget(self, action: #selector(chinderAction), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(200)
        }
    }
    
    func chinderAction() {
        present(chinderViewController(), animated: true, completion: nil)
    }
    
    func prepareDownloadButton() {
        let button = getButton()
        button.setTitle("Download from S3", for: .normal)
        button.addTarget(self, action: #selector(downloadAction), for: .touchUpInside)
        
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(100)
        }
    }
    
    func downloadAction() {
        for key in photoKeys {
            downloadImagefor(Key: key)
        }
    }
    
    func uploadAction() {
        for key in photoKeys {
            uploadImagefor(Key: key)
        }
    }
    
    func prepareStatsButton() {
        
        statsbutton.backgroundColor = UIColor.RGB(168, greenValue: 217, blueValue: 210, alpha: 1)
        statsbutton.addTarget(self, action: #selector(statsAction), for: .touchUpInside)
        
        self.view.addSubview(statsbutton)
        statsbutton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(160)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(40)
        }

    }
    
    func statsAction() {
        print(photoKeys.count, downloadedImages.count)
        statsbutton.setTitle("\(downloadedImages.count) photos", for: .normal)
        for key in photoKeys {
            deleteFile(Key: key)
        }
        
        self.downloadedImages = [UIImage]()
        self.collectionView.reloadData()
        setUpView()
    }
    
   fileprivate func onlySync100Photos() {
        // Gets 158 photos on Dan's Phone from his family pictures ablum.
        var assetCollection = PHAssetCollection()
        var albumFound = Bool()
        var photoAssets = PHFetchResult<AnyObject>()
    
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let first_Obj:AnyObject = collection.firstObject {
            //found the album
            assetCollection = first_Obj as! PHAssetCollection
            albumFound = true
        }
        else { albumFound = false }
    
        photoAssets = PHAsset.fetchAssets(in: assetCollection, options: nil) as! PHFetchResult<AnyObject>
        let imageManager = PHCachingImageManager()
        photoAssets.enumerateObjects({(object: AnyObject!, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            
            if object is PHAsset{
                let asset = object as! PHAsset
                let imageSize = CGSize(width: 244, height: 244)
            
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                requestOptions.isNetworkAccessAllowed = true
                requestOptions.deliveryMode = .opportunistic
                requestOptions.resizeMode = .exact
                imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: .aspectFit, options: requestOptions, resultHandler: {
                    (image, info) -> Void in
                    let idString = asset.localIdentifier
                    let indexOfCharicter = idString.components(separatedBy: "/")
                    if let image = image, let id = indexOfCharicter.first  {
                        /* The image is now available to us */
                        let photo = image
                        self.addImgToArray(uploadImage: photo, id: id)
                    }
                })
                
            }
        })
    }
    
    func addImgToArray(uploadImage:UIImage, id: String){
        let photoObject = PhotoObject(image: uploadImage, id: id)
        photoObjectList.append(photoObject)
        DispatchQueue.main.async (execute: {
            self.photosToUpload = self.photoObjectList.count
        })
        //Used for download
        photoKeys.append(id)
    }
    
    fileprivate func downloadImagefor(Key: String) {
        let downloadingFilePath1 = NSTemporaryDirectory().appending(Key + ext)
        let downloadingFileURL1 = URL(fileURLWithPath: downloadingFilePath1)
        let transferManager = AWSS3TransferManager.default()
        let readRequest1 : AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
        readRequest1.bucket = bucket
        readRequest1.key = Key + ext
        readRequest1.downloadingFileURL = downloadingFileURL1
        transferManager?.download(readRequest1).continue(with: AWSExecutor.mainThread(), withSuccessBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error?.localizedDescription ?? "Error")
            } else {
                if let image = UIImage(contentsOfFile: downloadingFilePath1) {
                    self.downloadedImages.append(image)
                    self.collectionView.reloadData()
                }
            }
            return nil
        })
    }
    
    fileprivate func uploadImagefor(Key: String) {
        let uploadFilePath1 = NSTemporaryDirectory().appending(Key + ext)
        let uploadingFileURL1 = URL(fileURLWithPath: uploadFilePath1)
        let transferManager = AWSS3TransferManager.default()
        let writeRequest1 : AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        writeRequest1.bucket = bucket
        writeRequest1.key = Key + ext
        writeRequest1.body = uploadingFileURL1
        transferManager?.upload(writeRequest1).continue(with: AWSExecutor.immediate(), withSuccessBlock: { (task: AWSTask) -> Any? in
            if task.error != nil {
                print(task.error?.localizedDescription ?? "Error")
            } else {
                print("Sucess uploading", task)
            }
            return nil
        })
    }
    
    func deleteFile(Key: String) {
        let s3 = AWSS3.default()
        let deleteObjectRequest: AWSS3DeleteObjectRequest = AWSS3DeleteObjectRequest()
        deleteObjectRequest.bucket = bucket
        deleteObjectRequest.key = Key + ext
        s3.deleteObject(deleteObjectRequest)
    }
}

