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

    fileprivate var testResults         = UILabel()
    fileprivate var amountUploaded      = UILabel()
    fileprivate var responseData        = NSMutableData()
    fileprivate var progressView        = UIProgressView()
    fileprivate let activeTasks         = NSMutableSet()
    fileprivate var firstTime           = true
    fileprivate var startTime           = Date()
    fileprivate var endTime             = Date()
    fileprivate var photosUploaded      = Int()
    fileprivate var photosToUpload      = Int()
    var thetotalBytesSent               = Int64()
    fileprivate var downloadedImages    = [UIImage]()
    fileprivate var photoObjectList:    [PhotoObject] = []
    fileprivate var allTasks            = [String: URLSessionUploadTask]()
    fileprivate var photoKeys:          [String] = []
    fileprivate let ext                 = ".jpg"
    fileprivate let bucket              = "upload2aws"
    fileprivate let contentType         = "image/jpeg"
    fileprivate let reuseIdentifier     = "PhotoCell"
    
    var collectionView:                 UICollectionView!
    let statsbutton = UIButton()
    
    
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
        //syncPhotos()
        onlySync100Photos()
    }
    
    
    fileprivate func syncPhotos() {
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
    
    fileprivate func prepareTestResults() {
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
    
    fileprivate func photoForIndexPath(_ indexPath: IndexPath) -> UIImage {
        return downloadedImages[indexPath.item]
    }
    
    fileprivate func evaluateTestResults() {
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
    
    
    fileprivate func getPresignedURL(key: String) -> AWSS3GetPreSignedURLRequest  {
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
    
    fileprivate func manageActiveTasks() {
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
    
    fileprivate func prepareUploadButton() {
        let button = UIButton()
        //Chatbooks Green
        button.backgroundColor = UIColor.RGB(168, greenValue: 217, blueValue: 210, alpha: 1)
        button.setTitle("Trigger upload", for: .normal)
        button.tintColor = UIColor.black
       //button.addTarget(self, action: #selector(uploadAction), for: .touchUpInside)
        button.addTarget(self, action: #selector(displayImagePickerButtonTapped), for: .touchUpInside)
        
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(100)
            make.width.equalTo(180)
            make.height.equalTo(40)
        }
    }
    
    fileprivate func prepareDownloadButton() {
        let button = UIButton()
        button.backgroundColor = UIColor.RGB(168, greenValue: 217, blueValue: 210, alpha: 1)
        button.setTitle("Download from S3", for: .normal)
        button.tintColor = UIColor.black
        button.addTarget(self, action: #selector(downloadAction), for: .touchUpInside)
        
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(100)
            make.width.equalTo(180)
            make.height.equalTo(40)
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
//                if let image = UIImage(contentsOfFile: uploadFilePath1) {
//                    self.downloadedImages.append(image)
//                    self.collectionView.reloadData()
//                }
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

extension ViewController: URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
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
            
            let object = String(task.taskIdentifier)
            activeTasks.remove(object)
            manageActiveTasks()
            photosUploaded = photosUploaded + 1
            // Update Progress Bar
            DispatchQueue.main.async (execute: {
                let uploadProgress: Float = Float(self.photosUploaded) / Float(self.photosToUpload)
                self.progressView.progress = uploadProgress
                let formated = String(format: "%.0f", uploadProgress * 100)
                self.amountUploaded.text = "\(formated)%"
            })
            
            let now = Date()
            let time = DateFormatter.localizedString(from: now, dateStyle: .none, timeStyle: .long)
            print("Task:\(task.taskIdentifier) completed at, Time:\(time)")
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return downloadedImages.count
    }
    func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCell
        cell.backgroundColor = UIColor.white
        let image = photoForIndexPath(indexPath)
        cell.imageView.image = image
        cell.imageView.contentMode = .scaleAspectFit
        return cell
    }
}
