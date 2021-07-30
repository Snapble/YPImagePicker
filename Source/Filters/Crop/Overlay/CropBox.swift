//
//  CropBox.swift
//
//  Created by Chen Qizhi on 2019/10/15.
//

import UIKit

// extension Overlay {
open class CropBox: UIView {

    var gridLinesAlpha: CGFloat = 1 {
        didSet {
            gridLinesView.alpha = gridLinesAlpha
        }
    }

//    var borderWidth: CGFloat = 1 {
//        didSet {
//            layer.borderWidth = borderWidth
//        }
//    }

    lazy var gridLinesView: Grid = {
        let view = Grid(frame: bounds)
        view.backgroundColor = UIColor.clear
        view.alpha = 1.0
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleBottomMargin, .flexibleBottomMargin, .flexibleRightMargin]
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        clipsToBounds = false
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
        autoresizingMask = UIView.AutoresizingMask(rawValue: 0)
        addSubview(gridLinesView)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        gridLinesView.frame = bounds
        gridLinesView.setNeedsDisplay()
    }
}

// MARK: CornerType

extension CropBox {
    enum CornerType {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}
