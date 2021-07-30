//
// Strings.swift
// YPImagePicker
//
// Created by Hai Nguyen on 7/30/21.
// Copyright (c) 2021 Yummypets. All rights reserved.
//
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
    /// Albums
    internal static let ypImagePickerAlbums = L10n.tr("YPImagePickerLocalizable", "YPImagePickerAlbums")
    /// Cancel
    internal static let ypImagePickerCancel = L10n.tr("YPImagePickerLocalizable", "YPImagePickerCancel")
    /// Cover
    internal static let ypImagePickerCover = L10n.tr("YPImagePickerLocalizable", "YPImagePickerCover")
    /// Crop
    internal static let ypImagePickerCrop = L10n.tr("YPImagePickerLocalizable", "YPImagePickerCrop")
    /// Done
    internal static let ypImagePickerDone = L10n.tr("YPImagePickerLocalizable", "YPImagePickerDone")
    /// Edit
    internal static let ypImagePickerEdit = L10n.tr("YPImagePickerLocalizable", "YPImagePickerEdit")
    /// Filter
    internal static let ypImagePickerFilter = L10n.tr("YPImagePickerLocalizable", "YPImagePickerFilter")
    /// Library
    internal static let ypImagePickerLibrary = L10n.tr("YPImagePickerLocalizable", "YPImagePickerLibrary")
    /// Next
    internal static let ypImagePickerNext = L10n.tr("YPImagePickerLocalizable", "YPImagePickerNext")
    /// Ok
    internal static let ypImagePickerOk = L10n.tr("YPImagePickerLocalizable", "YPImagePickerOk")
    /// Cancel
    internal static let ypImagePickerPermissionDeniedPopupCancel = L10n.tr("YPImagePickerLocalizable", "YPImagePickerPermissionDeniedPopupCancel")
    /// Grant Permission
    internal static let ypImagePickerPermissionDeniedPopupGrantPermission = L10n.tr("YPImagePickerLocalizable", "YPImagePickerPermissionDeniedPopupGrantPermission")
    /// Please allow access
    internal static let ypImagePickerPermissionDeniedPopupMessage = L10n.tr("YPImagePickerLocalizable", "YPImagePickerPermissionDeniedPopupMessage")
    /// Permission denied
    internal static let ypImagePickerPermissionDeniedPopupTitle = L10n.tr("YPImagePickerLocalizable", "YPImagePickerPermissionDeniedPopupTitle")
    /// Photo
    internal static let ypImagePickerPhoto = L10n.tr("YPImagePickerLocalizable", "YPImagePickerPhoto")
    /// Processing..
    internal static let ypImagePickerProcessing = L10n.tr("YPImagePickerLocalizable", "YPImagePickerProcessing")
    /// Save
    internal static let ypImagePickerSave = L10n.tr("YPImagePickerLocalizable", "YPImagePickerSave")
    /// Take a photo
    internal static let ypImagePickerTakePhoto = L10n.tr("YPImagePickerLocalizable", "YPImagePickerTakePhoto")
    /// Trim
    internal static let ypImagePickerTrim = L10n.tr("YPImagePickerLocalizable", "YPImagePickerTrim")
    /// Video
    internal static let ypImagePickerVideo = L10n.tr("YPImagePickerLocalizable", "YPImagePickerVideo")
    /// Video duration
    internal static let ypImagePickerVideoDurationTitle = L10n.tr("YPImagePickerLocalizable", "YPImagePickerVideoDurationTitle")
    /// Pick a video less than %@ seconds long
    internal static func ypImagePickerVideoTooLong(_ p1: Any) -> String {
        return L10n.tr("YPImagePickerLocalizable", "YPImagePickerVideoTooLong", String(describing: p1))
    }
    /// The video must be at least %@ seconds
    internal static func ypImagePickerVideoTooShort(_ p1: Any) -> String {
        return L10n.tr("YPImagePickerLocalizable", "YPImagePickerVideoTooShort", String(describing: p1))
    }
    /// The limit is %d photos or videos
    internal static func ypImagePickerWarningItemsLimit(_ p1: Int) -> String {
        return L10n.tr("YPImagePickerLocalizable", "YPImagePickerWarningItemsLimit", p1)
    }
    /// No Media. Please take photos and videos using the camera
    internal static let ypImagePickerWarningNoMedia = L10n.tr("YPImagePickerLocalizable", "YPImagePickerWarningNoMedia")
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
    private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
        return String(format: format, locale: Locale.current, arguments: args)
    }
}

// swiftlint:disable convenience_type
private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}
// swiftlint:enable convenience_type
