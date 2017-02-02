//
//  ChindrVC.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/31/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import UIKit

import UIKit
import Koloda
import pop
import Photos
import SnapKit

private let frameAnimationSpringBounciness: CGFloat = 9
private let frameAnimationSpringSpeed: CGFloat = 16
private let kolodaCountOfVisibleCards = 2
private let kolodaAlphaValueSemiTransparent: CGFloat = 0.1

class ChindrVC: UIViewController {
    
    @IBOutlet weak var kolodaView: CustomKolodaView!
    var photoKeys:          [String] = []
    var photoObjectList:    [PhotoObject] = []
    var analyticsLabel = UILabel()
   
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        AWS.shared.printCount = 0
        AWS.shared.excludeCount = 0
        setupNavigationController()
        syncPhotos()
        kolodaView.alphaValueSemiTransparent = kolodaAlphaValueSemiTransparent
        kolodaView.countOfVisibleCards = kolodaCountOfVisibleCards
        kolodaView.delegate = self
        kolodaView.dataSource = self
        kolodaView.animator = BackgroundKolodaAnimator(koloda: kolodaView)
        prepareAnalytics()
        self.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        AWS.shared.createUserSubFolder()
        AWS.shared.createFolderWith(folder: .print)
        AWS.shared.createFolderWith(folder: .exclude)
        
    }
    
    func setupNavigationController() {
        navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func checkAutorization() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .restricted:
            syncPhotos()
        case .notDetermined, .denied:
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if (newStatus == PHAuthorizationStatus.authorized) {
                    self.syncPhotos()
                }
            })
        }
    }
    
    func prepareAnalytics() {
        view.addSubview(analyticsLabel)
        analyticsLabel.textColor = UIColor.white
        analyticsLabel.textAlignment = .center
        analyticsLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-60)
            make.width.equalToSuperview()
            make.height.equalTo(40)
        }
        
    }
    
    func updateCounts() {
        guard let printCount = AWS.shared.printCount, let excludedCount = AWS.shared.excludeCount else {
            return
        }
       self.analyticsLabel.text = "Print: \(printCount) Exclude:\(excludedCount)"
    }
    
    //MARK: IBActions
    @IBAction func leftButtonTapped() {
        uploadZiffImageFrom(id: photoObjectList[kolodaView.currentCardIndex].id, folder: .exclude)
        updateCounts()
        kolodaView?.swipe(.left)
    }
    
    @IBAction func rightButtonTapped() {
        uploadZiffImageFrom(id: photoObjectList[kolodaView.currentCardIndex].id, folder: .print)
        updateCounts()
        kolodaView?.swipe(.right)
    }
    
    @IBAction func undoButtonTapped(_ sender: UIBarButtonItem) {
        AWS.shared.deleteFile(Key: photoObjectList[kolodaView.currentCardIndex].id)
        kolodaView?.revertAction()
    }
    
    @IBAction func testAction(_ sender: Any) {
     self.navigationController?.pushViewController(ViewController(), animated: true)
    }
    
    func syncPhotos() {
        // Gets all photos off of phone.
        let imgManager = PHImageManager.default()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .none

        let fetchOptions = PHFetchOptions()
        
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        results.enumerateObjects({(object: AnyObject!, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if object is PHAsset{
                let asset = object as! PHAsset
                let date = asset.creationDate! as Date
                let year = Calendar.current.component(.year, from: date)
                //if year == 2016 {
                
                imgManager.requestImage(for: asset, targetSize: CGSize(width: 244, height: 244), contentMode: .aspectFit, options: requestOptions, resultHandler: { (image, info) in
                    let idString = asset.localIdentifier
                    let indexOfCharicter = idString.components(separatedBy: "/")
                    if let image = image, let id = indexOfCharicter.first {
                        self.addImgToArray(uploadImage: image, id: id)
                    }
                })
            }
        })
    }
    
    func uploadZiffImageFrom(id: String, folder: Folder) {
        let imgManager = PHImageManager.default()
        let ziffRequestOptions = PHImageRequestOptions()
        ziffRequestOptions.isSynchronous = true
        ziffRequestOptions.isNetworkAccessAllowed = true
        ziffRequestOptions.deliveryMode = .opportunistic
        ziffRequestOptions.resizeMode = .exact
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]

        let results = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: fetchOptions)
        
        results.enumerateObjects({(object: AnyObject!, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            if object is PHAsset{
                let asset = object as! PHAsset
                
                imgManager.requestImage(for: asset, targetSize: CGSize(width: 244, height: 244), contentMode: .aspectFit, options: ziffRequestOptions, resultHandler: { (image, info) in
                    let idString = asset.localIdentifier
                    let indexOfCharicter = idString.components(separatedBy: "/")
                    if let image = image, let id = indexOfCharicter.first {
                        let ziffPhotoObject = PhotoObject(image: image, id: id)
                        AWS.shared.upload(Object: ziffPhotoObject, folder: folder)
                    }
                })
            }
        })
    }
    
    func addImgToArray(uploadImage: UIImage, id: String){
        let photoObject = PhotoObject(image: uploadImage, id: id)
        photoObjectList.append(photoObject)
        photoKeys.append(id)
    }
}

//MARK: KolodaViewDelegate
extension ChindrVC: KolodaViewDelegate {
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        kolodaView.resetCurrentCardIndex()
    }
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        switch direction {
        case .left:
            uploadZiffImageFrom(id: photoObjectList[kolodaView.currentCardIndex - 1].id, folder: .exclude)
        case .right:
            uploadZiffImageFrom(id: photoObjectList[kolodaView.currentCardIndex - 1].id, folder: .print)
        default:
            assertionFailure("This direction is not supported :\(direction)")
            break
        }
        updateCounts()
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaSwipeThresholdRatioMargin(_ koloda: KolodaView) -> CGFloat? {
        return 0.4
    }
    
    func kolodaShouldMoveBackgroundCard(_ koloda: KolodaView) -> Bool {
        return false
    }
    
    func kolodaShouldTransparentizeNextCard(_ koloda: KolodaView) -> Bool {
        return true
    }
    
    func koloda(kolodaBackgroundCardAnimation koloda: KolodaView) -> POPPropertyAnimation? {
        let animation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        animation?.springBounciness = frameAnimationSpringBounciness
        animation?.springSpeed = frameAnimationSpringSpeed
        return animation
    }
}

// MARK: KolodaViewDataSource
extension ChindrVC: KolodaViewDataSource {
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return photoObjectList.count
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        let imageView = UIImageView(image: photoObjectList[index].image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return ChindrOverlayView(frame: koloda.frame)
    }
}


