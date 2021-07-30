//
//  PhotoEditorViewController.swift
//  InstagramPicker
//
//  Created by MMI0002 on 8/30/20.
//  Copyright © 2020 Tuan. All rights reserved.
//

import UIKit
import Photos
import MetalPetal

class PhotoEditorViewController: UIViewController, IsMediaFilterVC {
    
    // Outlet
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var filtersView: UIView!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    fileprivate var filterCollectionView: UICollectionView!
    fileprivate var toolCollectionView: UICollectionView!
    fileprivate var filterControlView: FilterControlView?
    
    fileprivate var imageView = MTIImageView() // For image filter view
    @IBOutlet weak var cropperView: UIView! // For crop image view
    private var cropperViewController: CropperViewController?
    
    // Data
    public var originImage: UIImage! // The origin Image (input)
    
    fileprivate var originInputImage: MTIImage?
    fileprivate var croppedImage: UIImage?
    
    fileprivate var currentAdjustStrengthFilter: MTFilter?  // Use for filter
    fileprivate var adjustFilter = MTBasicAdjustFilter()    // Use for edit
    fileprivate var allFilters: [MTFilter.Type] = []
    fileprivate var allTools: [FilterToolItem] = []
    
    fileprivate var thumbnails: [String: UIImage] = [:]
    fileprivate var cachedFilters: [Int: MTFilter] = [:]
    fileprivate var currentSelectFilterIndex: Int = 0
    fileprivate var adjustFilterClone = MTBasicAdjustFilter() // Use to clone adjustFilter
    
    fileprivate var appliedBorder = false
    fileprivate var tempAppliedBorder = false

    
    // Callback
    var didSave: ((YPMediaItem) -> Void)?
    var didCancel: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        allFilters = MTFilterManager.shared.allFilters
        
        setupFilterCollectionView()
        setupToolDataSource()
        setupToolCollectionView()
        
        let ciImage = CIImage(cgImage: originImage.cgImage!)
        let originImage = MTIImage(ciImage: ciImage, isOpaque: true)
        
        imageView.resizingMode = .aspectFill
        imageView.backgroundColor = .clear
        previewView.addSubview(imageView)
        originInputImage = originImage
        imageView.image = originImage
        
        let ratio = originImage.size.width / originImage.size.height
        DispatchQueue.main.async {
            var frame = self.previewView.bounds
            if ratio > 1 {
                let height = frame.width / ratio
                frame = CGRect(x: 0, y: (frame.height - height) / 2, width: frame.width, height: height)
            }
            else {
                let width = frame.height * ratio
                frame = CGRect(x: (frame.width - width) / 2 , y: 0, width: width, height: frame.height)
            }
            self.imageView.frame = frame
            self.imageView.isHidden = false
            
            self.addCropImageView()
        }
        
        generateFilterThumbnails()
        setupNavigationButton()
        
        
    }
    
    private func addCropImageView() {
        let cropperViewController = CropperViewController(originalImage: self.originImage)

        //add as a childviewcontroller
        addChild(cropperViewController)

         // Add the child's View as a subview
         self.cropperView.addSubview(cropperViewController.view)
         cropperViewController.view.frame = cropperView.bounds
         cropperViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

         // tell the childviewcontroller it's contained in it's parent
        cropperViewController.didMove(toParent: self)
        
        cropperViewController.delegate = self
        self.cropperViewController = cropperViewController
        
        cropperView.isHidden = true
        
    }
    
    private func setupNavigationBar() {
        let luxImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        luxImageView.image = UIImage(named: "edit-luxtool")
        navigationItem.titleView = luxImageView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupNavigationButton() {
        let leftBarButton = UIBarButtonItem(title: YPConfig.wordings.cancel, style: .plain, target: self, action: #selector(cancelBarButtonTapped(_:)))
        let rightBarButton = UIBarButtonItem(title: YPConfig.wordings.next, style: .done, target: self, action: #selector(saveBarButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = leftBarButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.navigationItem.rightBarButtonItem?.tintColor = YPConfig.colors.tintColor
        self.navigationItem.rightBarButtonItem?.setFont(font: YPConfig.fonts.rightBarButtonFont, forState: .normal)
    }
    
    private func clearNavigationButton() {
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.titleView = nil
    }
    
    private func setupAdjustNavigation() {
        let leftBarButton = UIBarButtonItem(image: UIImage(named: "icon-grid"), style: .plain, target: self, action: #selector(gridBarButtonTapped(_:)))
        let rightBarButton = UIBarButtonItem(image: UIImage(named: "icon-rotate"), style: .plain, target: self, action: #selector(rotateBarButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = leftBarButton
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        filterCollectionView.frame.size = filtersView.bounds.size
        toolCollectionView.frame.size = filtersView.bounds.size
    }
    
    override var prefersStatusBarHidden: Bool { return YPConfig.hidesStatusBar }
    
    fileprivate func getFilterAtIndex(_ index: Int) -> MTFilter {
        if let filter = cachedFilters[index] {
            return filter
        }
        let filter = allFilters[index].init()
        cachedFilters[index] = filter
        return filter
    }
    
    @objc func gridBarButtonTapped(_ sender: Any) {
        cropperViewController?.displayGridNextLevel()
    }
    
    @objc func rotateBarButtonTapped(_ sender: Any) {
        cropperViewController?.rotateButtonPressed()
    }
    
    @objc func cancelBarButtonTapped(_ sender: Any) {
        guard let didCancel = didCancel else {
            navigationController?.popViewController(animated: false)
            return
        }
        didCancel()
    }
    
    @objc func saveBarButtonTapped(_ sender: Any) {
        guard let image = self.imageView.image,
            let uiImage = MTFilterManager.shared.generate(image: image) else {
                return
        }
        let fileManager = FileManager()
        let fileName = "\(String.ramdomFileName()).jpg"
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        // MARK - TOFIX
//        let outputURL = URL(fileURLWithPath: FileManager.default.documentDirectoryPath).appendingPathComponent(fileName)
        try? fileManager.removeItem(at: outputURL)

        guard let imageData = uiImage.jpegData(compressionQuality: 1) else {return}
        do {
            // writes the image data to disk
            try imageData.write(to: outputURL)
            let mediaPhoto = YPMediaItem.photo(p: YPMediaPhoto(image: uiImage, url: outputURL))
            didSave?(mediaPhoto)
            navigationController?.popViewController(animated: false)
            print("file saved")
        } catch {
            print("error saving file:", error)
        }
    }
    
    fileprivate func setupFilterCollectionView() {
        
        let frame = CGRect(x: 0, y: 0, width: filtersView.bounds.width, height: filtersView.bounds.height - 44)
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        layout.itemSize = CGSize(width: 104, height: filtersView.bounds.height - 44)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        filterCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        filterCollectionView.backgroundColor = .clear
        filterCollectionView.showsHorizontalScrollIndicator = false
        filterCollectionView.showsVerticalScrollIndicator = false
        filtersView.addSubview(filterCollectionView)
        filterCollectionView.dataSource = self
        filterCollectionView.delegate = self
        filterCollectionView.register(FilterPickerCell.self, forCellWithReuseIdentifier: NSStringFromClass(FilterPickerCell.self))
        filterCollectionView.reloadData()
        
        filterButton.setTitle(YPConfig.wordings.filter, for: .normal)
        editButton.setTitle(YPConfig.wordings.edit, for: .normal)
    }
    
    fileprivate func setupToolCollectionView() {
        let frame = CGRect(x: 0, y: 0, width: filtersView.bounds.width, height: filtersView.bounds.height - 44)
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        layout.itemSize = CGSize(width: 100, height: 130)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        toolCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
        toolCollectionView.backgroundColor = .clear
        toolCollectionView.showsHorizontalScrollIndicator = false
        toolCollectionView.showsVerticalScrollIndicator = false
        toolCollectionView.dataSource = self
        toolCollectionView.delegate = self
        toolCollectionView.register(ToolPickerCell.self, forCellWithReuseIdentifier: NSStringFromClass(ToolPickerCell.self))
        toolCollectionView.reloadData()
    }
    
    fileprivate func setupToolDataSource() {
        allTools.removeAll()
        allTools.append(FilterToolItem(type: .adjust, slider: .adjustStraighten))
        allTools.append(FilterToolItem(type: .brightness, slider: .negHundredToHundred))
        allTools.append(FilterToolItem(type: .contrast, slider: .negHundredToHundred))
        allTools.append(FilterToolItem(type: .structure, slider: .zeroToHundred))
        allTools.append(FilterToolItem(type: .warmth, slider: .negHundredToHundred))
        allTools.append(FilterToolItem(type: .saturation, slider: .negHundredToHundred))
        allTools.append(FilterToolItem(type: .color, slider: .negHundredToHundred))
        allTools.append(FilterToolItem(type: .fade, slider: .zeroToHundred))
        allTools.append(FilterToolItem(type: .highlights, slider: .negHundredToHundred))
        allTools.append(FilterToolItem(type: .shadows, slider: .negHundredToHundred))
        allTools.append(FilterToolItem(type: .vignette, slider: .zeroToHundred))
        allTools.append(FilterToolItem(type: .tiltShift, slider: .tiltShift))
        allTools.append(FilterToolItem(type: .sharpen, slider: .zeroToHundred))
    }
    
    fileprivate func generateFilterThumbnails() {
        DispatchQueue.global().async {
            
            let size = CGSize(width: 200, height: 200)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            self.originImage.draw(in: CGRect(origin: .zero, size: size))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let image = scaledImage {
                for filter in self.allFilters {
                    let image1 = MTFilterManager.shared.generateThumbnailsForImage(image, with: filter)
                    self.thumbnails[filter.name] = image1
                    DispatchQueue.main.async {
                        self.filterCollectionView.reloadData()
                    }
                }
            }
        }
    }
    
    @IBAction func filterButtonTapped(_ sender: Any) {
        addCollectionView(at: 0)
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        adjustFilter.inputImage = imageView.image
        addCollectionView(at: 1)
    }
    
    fileprivate func addCollectionView(at index: Int) {
        let isFilterTabSelected = index == 0
        if isFilterTabSelected && filterButton.isSelected {
            return
        }
        if !isFilterTabSelected && editButton.isSelected {
            return
        }
        UIView.animate(withDuration: 0.5, animations: {
            if isFilterTabSelected {
                self.toolCollectionView.removeFromSuperview()
                self.filtersView.addSubview(self.filterCollectionView)
            } else {
                self.filterCollectionView.removeFromSuperview()
                self.filtersView.addSubview(self.toolCollectionView)
            }
        }) { (finish) in
            self.filterButton.isSelected = isFilterTabSelected
            self.editButton.isSelected = !isFilterTabSelected
        }
        
    }
    
    fileprivate func presentFilterControlView(for tool: FilterToolItem) {
        let width = self.filtersView.bounds.width
        let height = self.filtersView.bounds.height + 44 + view.safeAreaInsets.bottom
        let frame = CGRect(x: 0, y: view.bounds.height - height + 44, width: width, height: height)
        let value = valueForFilterControlView(with: tool)
        let controlView = FilterControlView(frame: frame, filterTool: tool, value: value, borderSeleted: appliedBorder)
        controlView.delegate = self
        filterControlView = controlView
        
        // Crop
        if tool.type == .adjust {
            imageView.isHidden = true
            cropperView.isHidden = false
            filterControlView?.isHidden = true
            UIView.animate(withDuration: 0.2, animations: {
                self.view.addSubview(controlView)
                controlView.setPosition(offScreen: false)
            }) { finish in
                self.title = tool.title
                self.clearNavigationButton()
                self.setupAdjustNavigation()
            }
        }
        else {
            imageView.isHidden = false
            cropperView.isHidden = true
            if adjustFilter.inputImage == nil{
                adjustFilter.inputImage = imageView.image
            }
            
            // Clone adjust filter
            adjustFilterClone = adjustFilter.copy()
            
            UIView.animate(withDuration: 0.2, animations: {
                self.view.addSubview(controlView)
                controlView.setPosition(offScreen: false)
            }) { finish in
                self.clearNavigationButton()
                self.navigationItem.title = tool.title
            }
        }
        
    }
    
    fileprivate func dismissFilterControlView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.filterControlView?.setPosition(offScreen: true)
        }) { finish in
            self.filterControlView?.removeFromSuperview()
            self.title = "Editor"
            self.setupNavigationButton()
            self.setupNavigationBar()
        }
    }
    
    fileprivate func valueForFilterControlView(with tool: FilterToolItem) -> Float {
        switch tool.type {
        case .adjustStrength:
            return 1.0
        case .adjust:
            return 0
        case .brightness:
            return adjustFilter.brightness
        case .contrast:
            return adjustFilter.contrast
        case .structure:
            return 0
        case .warmth:
            return adjustFilter.temperature
        case .saturation:
            return adjustFilter.saturation
        case .color:
            return 0
        case .fade:
            return adjustFilter.fade
        case .highlights:
            return adjustFilter.highlights
        case .shadows:
            return adjustFilter.shadows
        case .vignette:
            return adjustFilter.vignette
        case .tiltShift:
            return adjustFilter.tintShadowsIntensity
        case .sharpen:
            return adjustFilter.sharpen
        }
    }
}

extension PhotoEditorViewController: FilterControlViewDelegate {
    
    func filterControlViewDidPressCancel(filterTool: FilterToolItem) {
        // Filter
        if filterTool.type == .adjustStrength {
            tempAppliedBorder = appliedBorder
        }
        // Crop
        else if filterTool.type == .adjust {
            imageView.isHidden = false
            cropperView.isHidden = true
        }
        // Other Edit
        else {
            adjustFilter = adjustFilterClone.copy()
            imageView.image = adjustFilter.outputImage
        }
        dismissFilterControlView()
    }
    
    func filterControlViewDidPressDone(filterTool: FilterToolItem) {
        if filterTool.type == .adjustStrength {
            appliedBorder = tempAppliedBorder
        }
        dismissFilterControlView()
        if let index = allTools.firstIndex(of: filterTool) {
            toolCollectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    func filterControlViewDidStartDragging() {
        
    }
    
    func filterControlView(_ controlView: FilterControlView, didChangeValue value: Float, filterTool: FilterToolItem) {
        // Filter
        if filterTool.type == .adjustStrength {
            currentAdjustStrengthFilter?.strength = value
            imageView.image = currentAdjustStrengthFilter?.outputImage
            return
        }
        
        // Edit
        switch filterTool.type {
        case .adjust:
            break
        case .brightness:
            adjustFilter.brightness = value
            break
        case .contrast:
            adjustFilter.contrast = value
            break
        case .structure:
            break
        case .warmth:
            adjustFilter.temperature = value
            break
        case .saturation:
            adjustFilter.saturation = value
            break
        case .color:
            adjustFilter.tintShadowsColor = .green
            adjustFilter.tintShadowsIntensity = 1
            break
        case .fade:
            adjustFilter.fade = value
            break
        case .highlights:
            adjustFilter.highlights = value
            break
        case .shadows:
            adjustFilter.shadows = value
            break
        case .vignette:
            adjustFilter.vignette = value
            break
        case .tiltShift:
            adjustFilter.tintShadowsIntensity = value
        case .sharpen:
            adjustFilter.sharpen = value
        default:
            break
        }
        imageView.image = adjustFilter.outputImage
    }
    
    func filterControlViewDidEndDragging() {
        
    }
    
    
    // For border
    func filterControlView(_ controlView: FilterControlView, borderSelectionChangeTo isSelected: Bool) {
        tempAppliedBorder = isSelected
        let filter = getFilterAtIndex(currentSelectFilterIndex)
        if isSelected {
            let blendFilter = MTIBlendFilter(blendMode: .overlay)
            blendFilter.inputBackgroundImage = filter.borderImage
            blendFilter.inputImage = imageView.image
            imageView.image = blendFilter.outputImage
        } else {
            filter.inputImage = originInputImage
            imageView.image = filter.outputImage
        }
    }
}

extension PhotoEditorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == filterCollectionView {
            return allFilters.count
        }
        return allTools.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == filterCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(FilterPickerCell.self), for: indexPath) as! FilterPickerCell
            let filter = allFilters[indexPath.item]
            cell.update(filter)
            cell.thumbnailImageView.image = thumbnails[filter.name]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ToolPickerCell.self), for: indexPath) as! ToolPickerCell
            let tool = allTools[indexPath.item]
            let value = valueForFilterControlView(with: tool)
            cell.update(tool, applied: Int(value * 100) != 0)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Filter
        if collectionView == filterCollectionView {
            if currentSelectFilterIndex == indexPath.item {
                if indexPath.item != 0 {
                    var item = FilterToolItem(type: .adjustStrength, slider: .zeroToHundred)
                    item.customTitle = allFilters[indexPath.item].name
                    presentFilterControlView(for: item)
                }
            }
            else {
                let filter = getFilterAtIndex(indexPath.item)
                if let croppedImage = croppedImage {
                    let ciImage = CIImage(cgImage: croppedImage.cgImage!)
                    filter.inputImage = MTIImage(ciImage: ciImage, isOpaque: true)
                }
                else {
                    filter.inputImage = originInputImage
                }

                if appliedBorder {
                    let blendFilter = MTIBlendFilter(blendMode: .overlay)
                    blendFilter.inputBackgroundImage = filter.borderImage
                    blendFilter.inputImage = filter.outputImage
                    imageView.image = blendFilter.outputImage
                } else {
                    imageView.image = filter.outputImage
                }
                currentSelectFilterIndex = indexPath.item
                currentAdjustStrengthFilter = filter
            }
        }
        // Edit
        else {
            let tool = allTools[indexPath.item]
            presentFilterControlView(for: tool)
        }
    }
    
}

extension PhotoEditorViewController: CropperViewControllerDelegate {
    func cropperDidConfirm(_ cropper: CropperViewController, state: CropperState?) {
        print("Cropper did confirm")
        cropperView.isHidden = true
        imageView.isHidden = false
        if let state = state, let croppedImage = cropper.originalImage.cropped(withCropperState: state) {
            let ciImage = CIImage(cgImage: croppedImage.cgImage!)
            self.croppedImage = croppedImage
            var workingImage = MTIImage(ciImage: ciImage, isOpaque: true)
            if let filter = currentAdjustStrengthFilter {
                filter.inputImage = workingImage
                if appliedBorder {
                    let blendFilter = MTIBlendFilter(blendMode: .overlay)
                    blendFilter.inputBackgroundImage = filter.borderImage
                    blendFilter.inputImage = filter.outputImage
                    workingImage = blendFilter.outputImage ?? workingImage
                } else {
                    workingImage = filter.outputImage ?? workingImage
                }
            }
            adjustFilter.inputImage = workingImage
            imageView.image = adjustFilter.outputImage
        }
        dismissFilterControlView()
    }
    
    func cropperDidCancel(_ cropper: CropperViewController) {
        print("Cropper did cancel")
        cropperView.isHidden = true
        imageView.isHidden = false
        dismissFilterControlView()
    }
    
}
