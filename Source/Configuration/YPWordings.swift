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
        public var title = "text_video_duration_title"
        public var tooShortMessage = "text_video_too_short"
        public var tooLongMessage = "text_video_too_long"
    }
    
    public var ok =  "text_button_ok"
    public var done =  "text_done"
    public var cancel = "text_button_cancel"
    public var save = "text_button_save"
    public var processing = "text_processing"
    public var trim = "text_video_trim"
    public var cover = "text_video_cover_image"
    public var albumsTitle = "text_photo_library"
    public var libraryTitle = "text_photo_library"
    public var cameraTitle = "text_photo"
    public var videoTitle = "text_video"
    public var next = "text_button_next"
    public var filter = "text_button_filters"
    public var crop = "text_button_crop"
    public var warningMaxItemsLimit = ypLocalized("YPImagePickerWarningItemsLimit")
    public var warningNoMedia = "text_warning_no_media"
    public var takePhoto = "text_button_take_photo"
    public var edit = "text_action_edit"
}
