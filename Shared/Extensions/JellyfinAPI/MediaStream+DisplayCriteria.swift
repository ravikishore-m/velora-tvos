//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(tvOS)
import AVKit
import CoreMedia
import JellyfinAPI

extension MediaStream {

    private enum DynamicRange {
        case sdr
        case hdr10
        case hlg
    }

    /// Players that render the HDR10 base layer request HDR10 for Dolby Vision
    private var displayDynamicRange: DynamicRange {
        switch videoRangeType {
        case .hdr10, .hdr10Plus, .dovi, .doviWithHDR10, .doviWithEL, .doviWithHDR10Plus, .doviWithELHDR10Plus:
            .hdr10
        case .hlg, .doviWithHLG:
            .hlg
        default:
            .sdr
        }
    }

    private var codecType: CMVideoCodecType {
        switch codec?.lowercased() {
        case "hevc", "h265": kCMVideoCodecType_HEVC
        case "av1": kCMVideoCodecType_AV1
        case "vp9": kCMVideoCodecType_VP9
        case "mpeg2video": kCMVideoCodecType_MPEG2Video
        default: kCMVideoCodecType_H264
        }
    }

    /// Display criteria for frame rate and dynamic range matching of players that
    /// do not provide a format description, built from the stream's metadata.
    var displayCriteria: AVDisplayCriteria? {
        guard type == .video,
              let frameRate = realFrameRate ?? averageFrameRate,
              frameRate > 0,
              let width, let height, width > 0, height > 0
        else { return nil }

        var extensions: [CFString: Any] = [:]

        switch displayDynamicRange {
        case .sdr:
            extensions[kCMFormatDescriptionExtension_ColorPrimaries] = kCMFormatDescriptionColorPrimaries_ITU_R_709_2
            extensions[kCMFormatDescriptionExtension_TransferFunction] = kCMFormatDescriptionTransferFunction_ITU_R_709_2
            extensions[kCMFormatDescriptionExtension_YCbCrMatrix] = kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2

        case .hdr10:
            extensions[kCMFormatDescriptionExtension_ColorPrimaries] = kCMFormatDescriptionColorPrimaries_ITU_R_2020
            extensions[kCMFormatDescriptionExtension_TransferFunction] = kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ
            extensions[kCMFormatDescriptionExtension_YCbCrMatrix] = kCMFormatDescriptionYCbCrMatrix_ITU_R_2020

        case .hlg:
            extensions[kCMFormatDescriptionExtension_ColorPrimaries] = kCMFormatDescriptionColorPrimaries_ITU_R_2020
            extensions[kCMFormatDescriptionExtension_TransferFunction] = kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG
            extensions[kCMFormatDescriptionExtension_YCbCrMatrix] = kCMFormatDescriptionYCbCrMatrix_ITU_R_2020
        }

        var formatDescription: CMVideoFormatDescription?
        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: codecType,
            width: Int32(width),
            height: Int32(height),
            extensions: extensions as CFDictionary,
            formatDescriptionOut: &formatDescription
        )

        guard status == noErr, let formatDescription else { return nil }

        return AVDisplayCriteria(refreshRate: frameRate, formatDescription: formatDescription)
    }
}
#endif
