//
//  YPFiltersView.swift
//  photoTaking
//
//  Created by Sacha Durand Saint Omer on 21/10/16.
//  Copyright © 2016 octopepper. All rights reserved.
//

import Stevia

class YPFiltersView: UIView {
    
    let imageView = UIImageView()
    var filterCollectionView: UICollectionView!
    var filtersLoader: UIActivityIndicatorView!
    fileprivate let collectionViewContainer: UIView = UIView()
    
    private var footer = UIView()
    private var filterItem = YPMenuItem()
    private var editItem = YPMenuItem()
    private var isFilter: Bool = true {
        didSet {
            if isFilter {
                filterItem.select()
                editItem.deselect()
            }
            else {
                filterItem.deselect()
                editItem.select()
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        filterCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout())
        filtersLoader = UIActivityIndicatorView(style: .gray)
        filtersLoader.hidesWhenStopped = true
        filtersLoader.startAnimating()
        filtersLoader.color = YPConfig.colors.tintColor
        
        sv(
            imageView,
            collectionViewContainer.sv(
                filtersLoader,
                filterCollectionView
            ),
            footer.sv(
                filterItem,
                editItem
            )
        )
        
        |-0-imageView.top(0)-0-|
        |-0-collectionViewContainer-0-|
        |-0-footer-0-|
        footer.height(44)
        imageView.Bottom == collectionViewContainer.Top
        collectionViewContainer.Bottom == footer.Top
        |filterCollectionView.centerVertically().height(160)|
        filtersLoader.centerInContainer()
        footer.Bottom == safeAreaLayoutGuide.Bottom
        imageView.heightEqualsWidth()
        
        backgroundColor = .offWhiteOrBlack
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        filterCollectionView.backgroundColor = .clear
        filterCollectionView.showsHorizontalScrollIndicator = false
        
        |-0-filterItem.top(0)-0-editItem.top(0)-0-|
        equal(widths: filterItem, editItem)
        filterItem.bottom(0)
        editItem.bottom(0)
        filterItem.textLabel.text = YPConfig.wordings.filter
        filterItem.select()
        editItem.textLabel.text = YPConfig.wordings.edit
        editItem.deselect()
        
        filterItem.button.addTarget(self, action: #selector(onBtnFilter), for: .touchUpInside)
        editItem.button.addTarget(self, action: #selector(onBtnEdit), for: .touchUpInside)
    }
    
    func layout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        layout.itemSize = CGSize(width: 100, height: 120)
        return layout
    }
    
    @objc private func onBtnFilter() {
        guard !isFilter else {return}
        isFilter = true
        print("Click button filter")
    }
    
    @objc private func onBtnEdit() {
        guard isFilter else {return}
        isFilter = false
        print("Click button edit")
    }
    
}
