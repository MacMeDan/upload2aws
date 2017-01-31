//
//  chinderViewController.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/31/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import UIKit
import Koloda
import Photos

class chinderViewController: UIViewController {
    @IBOutlet weak var kolodaView: KolodaView!
    var photoKeys:          [String] = []
    var photoObjectList:    [PhotoObject] = []
    
    var dataSource: [UIImage] = {
        var array: [UIImage] = []
        return array
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        syncPhotos()
        kolodaView.delegate = self
        kolodaView.dataSource = self
        self.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        kolodaView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        //Used for download
        photoKeys.append(id)
    }
    
    @IBAction func leftButtonTapped() {
        kolodaView?.swipe(.left)
    }
    
    @IBAction func rightButtonTapped() {
        kolodaView?.swipe(.right)
    }
    
    @IBAction func undoButtonTapped() {
        kolodaView?.revertAction()
    }

    
    
}


extension chinderViewController: KolodaViewDelegate {
    func kolodaDidRunOutOfCards(koloda: KolodaView) {
        print("Out of cards")
    }
    
    func koloda(koloda: KolodaView, didSelectCardAt index: Int) {
    }
}

extension chinderViewController: KolodaViewDataSource {
    
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return photoObjectList.count
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        return UIImageView(image: photoObjectList[index].image)
    }
    
    
    func koloda(koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return nil
    }
}
