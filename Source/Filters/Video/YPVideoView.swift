//
//  YPVideoView.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Stevia
import AVFoundation
import GLKit
import Photos
import MetalPetal

public class YPVideoView: UIView {
    lazy var playerItemVideoOutput: AVPlayerItemVideoOutput = {
        let attributes = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        return AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
    }()
    
    lazy var displayLink: CADisplayLink = {
        let dl = CADisplayLink(target: self, selector: #selector(readBuffer(_:)))
        dl.add(to: .current, forMode: RunLoop.Mode.common)
        dl.isPaused = true
        return dl
    }()
    
    var filter: MTFilter?
    
    fileprivate var videoPreviewView: MTIImageView?
    
    public let playImageView = UIImageView(image: nil)
    
    internal let playerView = UIView()
    internal let playerLayer = AVPlayerLayer()
    internal var previewImageView = UIImageView()
    
    private var asset: AVAsset?
    private var videoComposition: VideoComposition<BlockBasedVideoCompositor>?
    private let context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    private let videoFilter = MT1977Filter()
    
    public var player: AVPlayer {
        guard playerLayer.player != nil else {
            return AVPlayer()
        }
        return playerLayer.player!
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    internal func setup() {
        let singleTapGR = UITapGestureRecognizer(target: self,
                                                 action: #selector(singleTap))
        singleTapGR.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGR)
        
        // Loop playback
        addReachEndObserver()
    
        playerView.alpha = 0
        playImageView.alpha = 0.8
        playerLayer.videoGravity = .resizeAspect
        previewImageView.backgroundColor = .clear

        sv(
            previewImageView,
            playerView,
            playImageView
        )
        
        previewImageView.fillContainer()
        playerView.fillContainer()
        playImageView.centerInContainer()
        playerView.layer.addSublayer(playerLayer)
        playImageView.image = YPConfig.icons.playImage
        
        self.showPlayImage(show: true)
        
        DispatchQueue.main.async {
            self.setupVideoPreviewView()
        }
        
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = playerView.bounds
    }
    
    @objc internal func singleTap() {
        pauseUnpause()
    }
    
    @objc public func playerItemDidReachEnd(_ note: Notification) {
        player.actionAtItemEnd = .none
        player.seek(to: CMTime.zero)
        player.play()
    }
    
    @objc private func readBuffer(_ sender: CADisplayLink) {
        var currentTime = CMTime.invalid
        let nextVSync = sender.timestamp + sender.duration
        currentTime = self.playerItemVideoOutput.itemTime(forHostTime: nextVSync)
        
        if self.playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime), let pixelBuffer = self.playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
            self.videoFilterPlay(cvImageBuffer: pixelBuffer)
        }
    }
    
    func stopDisplayLink() {
        displayLink.invalidate()
    }
    
    func setupVideoPreviewView() {
        videoPreviewView = MTIImageView(frame: self.playerView.frame)
        if let videoPreviewView = videoPreviewView {
            videoPreviewView.frame = self.playerView.bounds
            videoPreviewView.isUserInteractionEnabled = false
            self.insertSubview(videoPreviewView, belowSubview: playImageView)
        }
    }
     
}

// MARK: - Video handling
extension YPVideoView {
    /// The main load video method
    public func loadVideo<T>(_ item: T) {
        var player: AVPlayer
        var playerItem: AVPlayerItem!
        switch item.self {
        case let video as YPMediaVideo:
            player = AVPlayer(url: video.url)
            let asset = AVURLAsset(url: video.url)
            playerItem = AVPlayerItem(asset: asset)
        case let url as URL:
            player = AVPlayer(url: url)
            let asset = AVURLAsset(url: url)
            playerItem = AVPlayerItem(asset: asset)
        case let aPlayerItem as AVPlayerItem:
            player = AVPlayer(playerItem: playerItem)
            playerItem = aPlayerItem
        default:
            return
        }
    
        playerLayer.player = player
        
        // Add the player item video output to the player item.
        playerItem.add(playerItemVideoOutput)
         
        // Add the player item to the player.
        playerLayer.player?.replaceCurrentItem(with: playerItem)
        
        playerView.alpha = 1
        setNeedsLayout()

        pauseUnpause()
    }
    
    /// Convenience func to pause or unpause video dependely of state
    public func pauseUnpause() {
        (player.rate == 0.0) ? play() : pause()
    }

    /// Mute or unmute the video
    public func muteUnmute() {
        player.isMuted = !player.isMuted
    }
    
    public func play() {
        player.play()
        displayLink.isPaused = false
        showPlayImage(show: false)
        addReachEndObserver()
    }
    
    public func pause() {
        player.pause()
        showPlayImage(show: true)
    }
    
    public func stop() {
        player.pause()
        player.seek(to: CMTime.zero)
        showPlayImage(show: true)
        removeReachEndObserver()
    }
    
    public func deallocate() {
        playerLayer.player = nil
        playImageView.image = nil
    }
    
    func videoFilterPlay(cvImageBuffer: CVImageBuffer) {
        let sourceImage = CIImage(cvImageBuffer: cvImageBuffer)
        let inputImage = MTIImage(ciImage: sourceImage, isOpaque: true)
        filter?.inputImage = inputImage
        
        guard let outputImage = filter?.outputImage else{
            videoPreviewView?.image = inputImage
            return
        }
        videoPreviewView?.image = outputImage
    }
}

// MARK: - Other API
extension YPVideoView {
    public func setPreviewImage(_ image: UIImage) {
        previewImageView.image = image
    }
    
    /// Shows or hide the play image over the view.
    public func showPlayImage(show: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.playImageView.alpha = show ? 0.8 : 0
        }
    }
    
    public func addReachEndObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    /// Removes the observer for AVPlayerItemDidPlayToEndTime. Could be needed to implement own observer
    public func removeReachEndObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
    }
}
