//
//  YPWordings.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 12/03/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import Foundation

public struct YPWordings {
    
    public var permissionPopup = PermissionPopup()
    public var videoDurationPopup = VideoDurationPopup()

    public struct PermissionPopup {
        public var title = ypLocalized("YPImagePickerPermissionDeniedPopupTitle")
        public var message = ypLocalized("YPImagePickerPermissionDeniedPopupMessage")
        public var cancel = ypLocalized("YPImagePickerPermissionDeniedPopupCancel")
        public var grantPermission = ypLocalized("YPImagePickerPermissionDeniedPopupGrantPermission")
    }
    
    public struct VideoDurationPopup {
        public var title = L10n.ypImagePickerVideoDurationTitle
        public var tooShortMessage = L10n.ypImagePickerVideoTooShort(5)
        public var tooLongMessage = L10n.ypImagePickerVideoTooLong(300)
    }
    
    public var ok =  L10n.ypImagePickerOk
    public var done =  L10n.ypImagePickerDone
    public var cancel = L10n.ypImagePickerCancel
    public var save = L10n.ypImagePickerSave
    public var processing = L10n.ypImagePickerProcessing
    public var trim = L10n.ypImagePickerTrim
    public var cover = L10n.ypImagePickerCover
    public var albumsTitle = L10n.ypImagePickerAlbums
    public var libraryTitle = L10n.ypImagePickerLibrary
    public var cameraTitle = L10n.ypImagePickerPhoto
    public var videoTitle = L10n.ypImagePickerVideo
    public var next = L10n.ypImagePickerNext
    public var filter = L10n.ypImagePickerFilter
    public var crop = L10n.ypImagePickerCrop
    public var warningMaxItemsLimit = L10n.ypImagePickerWarningItemsLimit(10)
    public var warningNoMedia = L10n.ypImagePickerWarningNoMedia
    public var takePhoto = L10n.ypImagePickerTakePhoto
    public var edit = L10n.ypImagePickerEdit
}
