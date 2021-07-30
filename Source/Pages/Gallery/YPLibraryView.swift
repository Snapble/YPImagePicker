//
//  YPLibraryView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/14.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Stevia
import Photos

extension UIFont {
    class var semiTitle16Pt: UIFont {
        return UIFont.systemFont(ofSize: 16.0, weight: .semibold)
    }
}

extension UIButton {
    
    func setText(_ text: String?, font: UIFont?, color: UIColor? = nil, for state: UIButton.State = .normal) {
        if let font = font {
            self.titleLabel?.font = font
        }
        if let color = color {
            self.setTitleColor(color, for: state)
        }
        if let text = text {
            self.setTitle(text, for: state)
        }
    }
}

final class YPLibraryView: UIView {
    
    let assetZoomableViewMinimalVisibleHeight: CGFloat  = 50
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var assetZoomableView: YPAssetZoomableView!
    @IBOutlet weak var assetViewContainer: YPAssetViewContainer!
    @IBOutlet weak var assetViewContainerConstraintTop: NSLayoutConstraint!
    @IBOutlet weak var noPhotoViewContainer: UIView!
    @IBOutlet weak var noPhotoLabel: UILabel!
    @IBOutlet weak var makePhotoButton: UIButton!
    
    let maxNumberWarningView = UIView()
    let maxNumberWarningLabel = UILabel()
    let progressView = UIProgressView()
    let line = UIView()
    var shouldShowLoader = false
    
    var makePhotoAction: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sv(
            line
        )
        
        layout(
            assetViewContainer!,
            |line| ~ 1
        )
        
        line.backgroundColor = .ypSystemBackground
        noPhotoLabel.text = YPConfig.wordings.warningNoMedia
        makePhotoButton.setText(YPConfig.wordings.takePhoto, font: UIFont.semiTitle16Pt)
        
        setupMaxNumberOfItemsView()
        setupProgressBarView()
    }
    
    /// At the bottom there is a view that is visible when selected a limit of items with multiple selection
    func setupMaxNumberOfItemsView() {
        // View Hierarchy
        sv(
            maxNumberWarningView.sv(
                maxNumberWarningLabel
            )
        )
        
        // Layout
        |maxNumberWarningView|.bottom(0)
        if #available(iOS 11.0, *) {
            maxNumberWarningView.Top == safeAreaLayoutGuide.Bottom - 40
            maxNumberWarningLabel.centerHorizontally().top(11)
        } else {
            maxNumberWarningView.height(40)
            maxNumberWarningLabel.centerInContainer()
        }
        
        // Style
        maxNumberWarningView.backgroundColor = .ypSecondarySystemBackground
        maxNumberWarningLabel.font = YPConfig.fonts.libaryWarningFont
        maxNumberWarningView.isHidden = true
    }
    
    /// When video is processing this bar appears
    func setupProgressBarView() {
        sv(
            progressView
        )
        
        progressView.height(5)
        progressView.Top == line.Top
        progressView.Width == line.Width
        progressView.progressViewStyle = .bar
        progressView.trackTintColor = YPConfig.colors.progressBarTrackColor
        progressView.progressTintColor = YPConfig.colors.progressBarCompletedColor ?? YPConfig.colors.tintColor
        progressView.isHidden = true
        progressView.isUserInteractionEnabled = false
    }
    
    // Action
    @IBAction func onBtnMakePhoto(_ sender: Any) {
        makePhotoAction?()
    }
    
}

// MARK: - UI Helpers

extension YPLibraryView {
    
    class func xibView() -> YPLibraryView? {
        let bundle = Bundle(for: YPPickerVC.self)
        let nib = UINib(nibName: "YPLibraryView", bundle: bundle)
        let xibView = nib.instantiate(withOwner: self, options: nil)[0] as? YPLibraryView
        return xibView
    }
    
    // MARK: - Overlay view
    
    func hideOverlayView() {
        assetViewContainer.itemOverlay?.alpha = 0
    }
    
    // MARK: - Loader and progress
    
    func fadeInLoader() {
        shouldShowLoader = true
        // Only show loader if full res image takes more than 0.5s to load.
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                if self.shouldShowLoader == true {
                    UIView.animate(withDuration: 0.2) {
                        self.assetViewContainer.spinnerView.alpha = 1
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            UIView.animate(withDuration: 0.2) {
                self.assetViewContainer.spinnerView.alpha = 1
            }
        }
    }
    
    func hideLoader() {
        shouldShowLoader = false
        assetViewContainer.spinnerView.alpha = 0
    }
    
    func updateProgress(_ progress: Float) {
        progressView.isHidden = progress > 0.99 || progress == 0
        progressView.progress = progress
        UIView.animate(withDuration: 0.1, animations: progressView.layoutIfNeeded)
    }
    
    // MARK: - Crop Rect
    
    func currentCropRect() -> CGRect {
        guard let cropView = assetZoomableView else {
            return CGRect.zero
        }
        let normalizedX = min(1, cropView.contentOffset.x &/ cropView.contentSize.width)
        let normalizedY = min(1, cropView.contentOffset.y &/ cropView.contentSize.height)
        let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width)
        let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height)
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }
    
    // MARK: - Curtain
    
    func refreshImageCurtainAlpha() {
        let imageCurtainAlpha = abs(assetViewContainerConstraintTop.constant)
            / (assetViewContainer.frame.height - assetZoomableViewMinimalVisibleHeight)
        assetViewContainer.curtain.alpha = imageCurtainAlpha
    }
    
    func cellSize() -> CGSize {
        var screenWidth: CGFloat = UIScreen.main.bounds.width
        if UIDevice.current.userInterfaceIdiom == .pad && YPImagePickerConfiguration.widthOniPad > 0 {
            screenWidth =  YPImagePickerConfiguration.widthOniPad
        }
        let size = screenWidth / 4 * UIScreen.main.scale
        return CGSize(width: size, height: size)
    }
}
