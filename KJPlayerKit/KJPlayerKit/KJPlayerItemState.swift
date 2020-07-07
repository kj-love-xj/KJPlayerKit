//
//  KJPlayerItemState.swift
//  KJPlayerKit
//
//  Created by 黄克瑾 on 2020/7/6.
//  Copyright © 2020 黄克瑾. All rights reserved.
//

import Foundation

struct KJPlayerItemState {
    /// 总时长
    var totalDuration: Int = 0
    /// 已播放时长
    var currentDuration: Int = 0
    /// 已缓存时长
    var cacheDuration: Int = 0
    /// 网络加载状态
    var defaultStatus: KJPlayerStatus = .unknown
    /// 用户操作状态
    var userPlayStatus: KJPlayerStatus = .unknown
    
    /// 总时长格式化文本
    var totalDurationText: String {
        
        let minutes = totalDuration % 3600 / 60
        let seconds = totalDuration % 3600 % 60
        
        if totalDuration >= 3600 {
            let hours = totalDuration / 3600
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 已播放时长的格式化文本
    var currentDurationText: String {
        
        let minutes = currentDuration % 3600 / 60
        let seconds = currentDuration % 3600 % 60

        if totalDuration >= 3600 {
            let hours = currentDuration / 3600
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 是否播放完成
    var isPlayComplete: Bool {
        return totalDuration == currentDuration && totalDuration > 0
    }
}
