//
//  Toolbar.swift
//
//  Created by Chen Qizhi on 2019/10/15.
//

import UIKit

class Toolbar: UIView {
    let textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .system)
        cancelButton.tintColor = .clear
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.setTitleColor(textColor, for: .normal)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.frame = CGRect(x: 0, y: 0, width: frame.width/2, height: frame.height)
        cancelButton.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
        return cancelButton
    }()

    lazy var doneButton: UIButton = {
        let doneButton = UIButton(type: .system)
        doneButton.tintColor = .clear
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        doneButton.setTitleColor(textColor, for: .normal)
        doneButton.setTitle(YPConfig.wordings.done, for: .normal)
        doneButton.frame = CGRect(x: frame.width/2, y: 0, width: frame.width/2, height: frame.height)
        doneButton.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
        return doneButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(cancelButton)
        addSubview(doneButton)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
