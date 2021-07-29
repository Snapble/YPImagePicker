//
//  VideoFiltersVC.swift
//  YPImagePicker
//
//  Created by Nik Kov || nik-kov.com on 18.04.2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Photos
import PryntTrimmerView
import MetalPetal
import MetalFilters
import VideoIO

public class YPVideoFiltersVC: UIViewController, IsMediaFilterVC {
    
    @IBOutlet weak var trimBottomItem: YPMenuItem!
    @IBOutlet weak var coverBottomItem: YPMenuItem!
    @IBOutlet weak var filterBottomItem: YPMenuItem!
    
    @IBOutlet weak var videoView: YPVideoView!
    @IBOutlet weak var trimmerView: TrimmerView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var coverThumbSelectorView: ThumbSelectorView!
    
    public var inputVideo: YPMediaVideo!
    public var inputAsset: AVAsset { return AVAsset(url: inputVideo.url) }
    
    private var playbackTimeCheckerTimer: Timer?
    private var imageGenerator: AVAssetImageGenerator?
    private var isFromSelectionVC = false
    
    var didSave: ((YPMediaItem) -> Void)?
    var didCancel: (() -> Void)?
    
    // For filter function
    fileprivate var allFilters: [MTFilter.Type] = MTFilterManager.shared.allFilters
    fileprivate var thumbnails: [String: UIImage] = [:]
    
    fileprivate var selectedFilter: MTFilter?
    fileprivate var currentlySelectedImageThumbnail: UIImage? // Used for comparing with original image when tapped
    
    private var videoComposition: VideoComposition<BlockBasedVideoCompositor>?
    
    /// Designated initializer
    public class func initWith(video: YPMediaVideo,
                               isFromSelectionVC: Bool) -> YPVideoFiltersVC {
        let vc = YPVideoFiltersVC(nibName: "YPVideoFiltersVC", bundle: Bundle(for: YPVideoFiltersVC.self))
        vc.inputVideo = video
        vc.isFromSelectionVC = isFromSelectionVC
        
        return vc
    }
    
    // MARK: - Live cycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        trimmerView.mainColor = YPConfig.colors.trimmerMainColor
        trimmerView.handleColor = YPConfig.colors.trimmerHandleColor
        trimmerView.positionBarColor = YPConfig.colors.positionLineColor
        trimmerView.maxDuration = YPConfig.video.trimmerMaxDuration
        trimmerView.minDuration = YPConfig.video.trimmerMinDuration
        
        coverThumbSelectorView.thumbBorderColor = YPConfig.colors.coverSelectorBorderColor
        
        trimBottomItem.textLabel.text = YPConfig.wordings.trim
        coverBottomItem.textLabel.text = YPConfig.wordings.cover
        filterBottomItem.textLabel.text = YPConfig.wordings.filter
        
        trimBottomItem.button.addTarget(self, action: #selector(selectTrim), for: .touchUpInside)
        coverBottomItem.button.addTarget(self, action: #selector(selectCover), for: .touchUpInside)
        filterBottomItem.button.addTarget(self, action: #selector(selectFilter), for: .touchUpInside)
        filterCollectionView.register(FilterPickerCell.self, forCellWithReuseIdentifier: NSStringFromClass(FilterPickerCell.self))
        filterCollectionView.collectionViewLayout = self.layout()
        filterCollectionView.delegate = self
        filterCollectionView.dataSource = self
        
        // Remove the default and add a notification to repeat playback from the start
        videoView.removeReachEndObserver()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(itemDidFinishPlaying(_:)),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: nil)
        
        // Set initial video cover
        imageGenerator = AVAssetImageGenerator(asset: self.inputAsset)
        imageGenerator?.appliesPreferredTrackTransform = true
        didChangeThumbPosition(CMTime(seconds: 1, preferredTimescale: 1))
        
        // Navigation bar setup
        title = YPConfig.wordings.trim
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: YPConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancel))
            navigationItem.leftBarButtonItem?.setFont(font: YPConfig.fonts.leftBarButtonFont, forState: .normal)
        }
        setupRightBarButtonItem()
        generateFilterThumbnails()
        
        selectFilter()
        videoView.loadVideo(inputVideo)
    }
    
    fileprivate func thumbFromImage(_ img: UIImage) -> CIImage {
        let k = img.size.width / img.size.height
        let scale = UIScreen.main.scale
        let thumbnailHeight: CGFloat = 300 * scale
        let thumbnailWidth = thumbnailHeight * k
        let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)
        UIGraphicsBeginImageContext(thumbnailSize)
        img.draw(in: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return smallImage!.toCIImage()!
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        trimmerView.asset = inputAsset
        trimmerView.delegate = self
        
        coverThumbSelectorView.asset = inputAsset
        coverThumbSelectorView.delegate = self
        
        //        selectFilter()
        //        videoView.loadVideo(inputVideo)
        
        super.viewDidAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaybackTimeChecker()
        videoView.stop()
    }
    
    func setupRightBarButtonItem() {
        let rightBarButtonTitle = isFromSelectionVC ? YPConfig.wordings.done : YPConfig.wordings.next
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
    }
    
    fileprivate func generateFilterThumbnails() {
        DispatchQueue.global().async {
            
            let size = CGSize(width: 200, height: 200)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            self.inputVideo.thumbnail.draw(in: CGRect(origin: .zero, size: size))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let image = scaledImage {
                for filter in self.allFilters {
                    let image = MTFilterManager.shared.generateThumbnailsForImage(image, with: filter)
                    self.thumbnails[filter.name] = image
                    DispatchQueue.main.async {
                        self.filterCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    // MARK: - Top buttons
    
    @objc public func save() {
        videoView.stopDisplayLink()
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        navigationItem.rightBarButtonItem = YPLoaders.defaultLoader
        let context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
        do {
            let asset = AVURLAsset(url: inputVideo.url)
            let trimmedAsset = try asset
                .assetByTrimming(startTime: trimmerView.startTime ?? CMTime.zero,
                                 endTime: trimmerView.endTime ?? inputAsset.duration)
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingUniquePathComponent(pathExtension: YPConfig.video.fileType.fileExtension)
            // MARK: - TOFIX
//            let outputURL = URL(fileURLWithPath: FileManager.default.documentDirectoryPath)
//            .appendingUniquePathComponent(pathExtension: YPConfig.video.fileType.fileExtension)
            let fileManager = FileManager()
            try? fileManager.removeItem(at: outputURL)
            
            if let filter = selectedFilter {
                let handler = MTIAsyncVideoCompositionRequestHandler(context: context, tracks: trimmedAsset.tracks(withMediaType: .video)) { [weak self] request in
                    guard self != nil else {
                        //TODO: resolve force unwrap
                        return request.anySourceImage!
                    }
                    return FilterGraph.makeImage { output in
                        //TODO: resolve force unwrap
                        request.anySourceImage! => filter => output
                        }!
                }
                let composition = VideoComposition(propertiesOf: asset, compositionRequestHandler: handler.handle(request:))
                self.videoComposition = composition
                var configuration = AssetExportSession.Configuration(fileType: AssetExportSession.fileType(for: outputURL)!, videoSettings: .h264(videoSize: videoComposition!.renderSize), audioSettings: .aac(channels: 2, sampleRate: 44100, bitRate: 128 * 1000))
                configuration.videoComposition = videoComposition!.makeAVVideoComposition()
                let exporter = try! AssetExportSession(asset: asset, outputURL: outputURL, configuration: configuration)
                exporter.export(progress: { p in },
                                completion: { [weak self] error in
                                    // Remove input file
                                    if let inputVideoUrl = self?.inputVideo.url {
                                        try? fileManager.removeItem(at: inputVideoUrl)
                                    }
                                    if error != nil {
                                        print("YPVideoFiltersVC -> Export video error \(error.debugDescription)")
                                    }
                                    else {
                                        DispatchQueue.main.async {
                                            if let coverImage = self?.coverImageView.image {
                                                let resultVideo = YPMediaVideo(thumbnail: coverImage,
                                                                               videoURL: outputURL,
                                                                               asset: self?.inputVideo.asset)
                                                didSave(YPMediaItem.video(v: resultVideo))
                                                self?.setupRightBarButtonItem()
                                            } else {
                                                print("YPVideoFiltersVC -> Don't have coverImage.")
                                            }
                                        }
                                    }
                                })
            }
            else {
                _ = trimmedAsset.export(to: outputURL) { [weak self] session in
                    switch session.status {
                    case .completed:
                        if let inputVideoUrl = self?.inputVideo.url {
                            try? fileManager.removeItem(at: inputVideoUrl)
                        }
                        DispatchQueue.main.async {
                            if let coverImage = self?.coverImageView.image {
                                let resultVideo = YPMediaVideo(thumbnail: coverImage,
                                                               videoURL: outputURL,
                                                               asset: self?.inputVideo.asset)
                                didSave(YPMediaItem.video(v: resultVideo))
                                self?.setupRightBarButtonItem()
                            } else {
                                print("YPVideoFiltersVC -> Don't have coverImage.")
                            }
                        }
                    case .failed:
                        print("YPVideoFiltersVC Export of the video failed. Reason: \(String(describing: session.error))")
                    default:
                        print("YPVideoFiltersVC Export session completed with \(session.status) status. Not handled")
                    }
                }
            }
        } catch let error {
            print("💩 \(error)")
        }
    }
    
    //    func update(asset: AVAsset){
    //        let handler = MTIAsyncVideoCompositionRequestHandler(context: context, tracks: asset.tracks(withMediaType: .video)) { [weak self] request in
    //            guard let `self` = self else {
    //                return request.anySourceImage
    //            }
    //            return FilterGraph.makeImage { output in
    //                request.anySourceImage => self.videoFilter => output
    //                }!
    //        }
    //        let composition = VideoComposition(propertiesOf: asset, compositionRequestHandler: handler.handle(request:))
    //
    //        let playerItem = AVPlayerItem(asset: asset)
    //        playerItem.videoComposition = composition.makeAVVideoComposition()
    //        self.player.replaceCurrentItem(with: playerItem)
    //        self.asset = asset
    //        self.videoComposition = composition
    //        exportVideo()
    //    }
    
    @objc func cancel() {
        didCancel?()
    }
    
    // MARK: - Bottom buttons
    
    @objc public func selectTrim() {
        title = YPConfig.wordings.trim
        
        filterBottomItem.deselect()
        trimBottomItem.select()
        coverBottomItem.deselect()
        
        trimmerView.isHidden = false
        videoView.isHidden = false
        coverImageView.isHidden = true
        coverThumbSelectorView.isHidden = true
        filterCollectionView.isHidden = true
    }
    
    @objc public func selectCover() {
        title = YPConfig.wordings.cover
        
        filterBottomItem.deselect()
        trimBottomItem.deselect()
        coverBottomItem.select()
        
        trimmerView.isHidden = true
        videoView.isHidden = true
        coverImageView.isHidden = false
        coverThumbSelectorView.isHidden = false
        filterCollectionView.isHidden = true
        
        stopPlaybackTimeChecker()
        videoView.stop()
    }
    
    @objc public func selectFilter() {
        title = YPConfig.wordings.filter
        
        filterBottomItem.select()
        trimBottomItem.deselect()
        coverBottomItem.deselect()
        
        trimmerView.isHidden = true
        videoView.isHidden = false
        coverImageView.isHidden = true
        coverThumbSelectorView.isHidden = true
        filterCollectionView.isHidden = false
        
        stopPlaybackTimeChecker()
        videoView.stop()
    }
    
    // MARK: - Various Methods
    
    // Updates the bounds of the cover picker if the video is trimmed
    // TODO: Now the trimmer framework doesn't support an easy way to do this.
    // Need to rethink a flow or search other ways.
    func updateCoverPickerBounds() {
        if let startTime = trimmerView.startTime,
            let endTime = trimmerView.endTime {
            if let selectedCoverTime = coverThumbSelectorView.selectedTime {
                let range = CMTimeRange(start: startTime, end: endTime)
                if !range.containsTime(selectedCoverTime) {
                    // If the selected before cover range is not in new trimeed range,
                    // than reset the cover to start time of the trimmed video
                }
            } else {
                // If none cover time selected yet, than set the cover to the start time of the trimmed video
            }
        }
    }
    
    // MARK: - Trimmer playback
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            videoView.player.seek(to: startTime)
        }
    }
    
    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer
            .scheduledTimer(timeInterval: 0.05, target: self,
                            selector: #selector(onPlaybackTimeChecker),
                            userInfo: nil,
                            repeats: true)
    }
    
    func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {
        guard let startTime = trimmerView.startTime,
            let endTime = trimmerView.endTime else {
                return
        }
        
        let playBackTime = videoView.player.currentTime()
        trimmerView.seek(to: playBackTime)
        
        if playBackTime >= endTime {
            videoView.player.seek(to: startTime,
                                  toleranceBefore: CMTime.zero,
                                  toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
}

// MARK: - TrimmerViewDelegate
extension YPVideoFiltersVC: TrimmerViewDelegate {
    public func positionBarStoppedMoving(_ playerTime: CMTime) {
        videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        videoView.play()
        startPlaybackTimeChecker()
        updateCoverPickerBounds()
    }
    
    public func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        videoView.pause()
        videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
}

// MARK: - ThumbSelectorViewDelegate
extension YPVideoFiltersVC: ThumbSelectorViewDelegate {
    public func didChangeThumbPosition(_ imageTime: CMTime) {
        if let imageGenerator = imageGenerator,
            let imageRef = try? imageGenerator.copyCGImage(at: imageTime, actualTime: nil) {
            coverImageView.image = UIImage(cgImage: imageRef)
        }
    }
}


extension YPVideoFiltersVC {
    func layout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        layout.itemSize = CGSize(width: 100, height: 120)
        return layout
    }
}

extension YPVideoFiltersVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //        return filteredThumbnailImagesArray.count
        return allFilters.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FilterPickerCell.self), for: indexPath) as! FilterPickerCell
        let filter = allFilters[indexPath.item]
        cell.update(filter)
        cell.thumbnailImageView.image = thumbnails[filter.name]
        return cell
    }
}

extension YPVideoFiltersVC: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filter = allFilters[indexPath.item].init()
        selectedFilter = filter
        videoView.filter = filter
        videoView.play()
        currentlySelectedImageThumbnail = thumbnails[allFilters[indexPath.item].name]
        self.coverImageView.image = currentlySelectedImageThumbnail
    }
}
