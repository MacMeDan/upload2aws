//
//  ChinderVC.swift
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

private let frameAnimationSpringBounciness: CGFloat = 9
private let frameAnimationSpringSpeed: CGFloat = 16
private let kolodaCountOfVisibleCards = 2
private let kolodaAlphaValueSemiTransparent: CGFloat = 0.1

class ChinderVC: UIViewController {
    
    @IBOutlet weak var kolodaView: CustomKolodaView!
    
    var photoKeys:          [String] = []
    var photoObjectList:    [PhotoObject] = []
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        syncPhotos()
        kolodaView.alphaValueSemiTransparent = kolodaAlphaValueSemiTransparent
        kolodaView.countOfVisibleCards = kolodaCountOfVisibleCards
        kolodaView.delegate = self
        kolodaView.dataSource = self
        kolodaView.animator = BackgroundKolodaAnimator(koloda: kolodaView)
        
        self.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        AWS.shared.createUserSubFolder()
        AWS.shared.createFolderWith(Name: printFolder)
        AWS.shared.createFolderWith(Name: excludeFolder)
    }
    
    //MARK: IBActions
    @IBAction func leftButtonTapped() {
        AWS.shared.upload(Object: photoObjectList[kolodaView.currentCardIndex], folder: excludeFolder)
        kolodaView?.swipe(.left)
    }
    
    @IBAction func rightButtonTapped() {
        AWS.shared.upload(Object: photoObjectList[kolodaView.currentCardIndex], folder: excludeFolder)
        kolodaView?.swipe(.right)
    }
    
    @IBAction func undoButtonTapped() {
        AWS.shared.deleteFile(Key: photoObjectList[kolodaView.currentCardIndex].id)
        kolodaView?.revertAction()
    }
    
    @IBAction func testAction(_ sender: UIButton) {
        self.navigationController?.present(ViewController(), animated: true, completion: nil)
        
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
    
    func addImgToArray(uploadImage:UIImage, id: String){
        let photoObject = PhotoObject(image: uploadImage, id: id)
        photoObjectList.append(photoObject)
        photoKeys.append(id)
    }

}

//MARK: KolodaViewDelegate
extension ChinderVC: KolodaViewDelegate {
    
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        kolodaView.resetCurrentCardIndex()
    }
    
    func koloda(_ koloda: KolodaView, didSwipeCardAt index: Int, in direction: SwipeResultDirection) {
        switch direction {
        case .left:
            AWS.shared.upload(Object: photoObjectList[kolodaView.currentCardIndex], folder: excludeFolder)
        case .right:
            AWS.shared.upload(Object: photoObjectList[kolodaView.currentCardIndex], folder: printFolder)
        default:
            assertionFailure("This direction is not supported :\(direction)")
            break
        }
        
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        //UIApplication.shared.openURL(URL(string: "https://yalantis.com/")!)
    }
    
    func kolodaShouldApplyAppearAnimation(_ koloda: KolodaView) -> Bool {
        return true
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
extension ChinderVC: KolodaViewDataSource {
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return photoObjectList.count
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        let imageView = UIImageView(image: photoObjectList[index].image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return ChinderOverlayView(frame: koloda.frame)
    }
}

