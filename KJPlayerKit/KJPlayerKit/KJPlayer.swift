//
//  KJPlayer.swift
//  KJPlayerKit
//
//  Created by 黄克瑾 on 2020/7/5.
//  Copyright © 2020 黄克瑾. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit

enum KJPlayerStatus {
    case unknown        // 未知
    case buffer         // 缓冲
    case playing        // 播放
    case pause          // 暂停
    case failed         // 失败
    case complete       // 播放完成 - 全播放完毕
}

struct KJPlayerItemDuration {
    var totalDuration: Int = 0
    var currentDuration: Int = 0
    var defaultStatus: KJPlayerStatus = .unknown
    var userPlayStatus: KJPlayerStatus = .unknown
    
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

class KJPlayer: NSObject {
    
    /// contentView
    private(set) lazy var contentView: KJContentView = {
        let v = KJContentView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0)
        return v
    }()
    
    /// 播放前的预览图
    private(set) lazy var preview: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        return v
    }()
    
    /// 播放器
    dynamic private(set) lazy var avPlayer: AVPlayer = {
        return AVPlayer(playerItem: nil)
    }()
    
    /// 播放视图层
    private(set) lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer(player: avPlayer)
//        layer.backgroundColor = UIColor.black.cgColor
        return layer
    }()
    
    /// 进度条
    private(set) lazy var avProgress = KJProgressBar()
    
    /// 顶部导航
    private(set) lazy var topView = KJPlayerTopBar()
    
    /// 加载样式
    private(set) lazy var activityView: UIActivityIndicatorView = {
        var style: UIActivityIndicatorView.Style
        if #available(iOS 13.0, *) {
            style = .large
        } else {
            style = .whiteLarge
        }
        let v = UIActivityIndicatorView(style: style)
        v.color = .white
        v.hidesWhenStopped = true;
        v.stopAnimating()
        return v
    }()
    
    /// 播放对象的相关数据
    private var playerItemModel = KJPlayerItemDuration()
    
    /// 定时器 用于获取播放器各种状态
    private var timer: DispatchSourceTimer = {
        let gcdTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        gcdTimer.schedule(deadline: DispatchTime.now(),
                          repeating: DispatchTimeInterval.milliseconds(500),
                          leeway: DispatchTimeInterval.milliseconds(10))
        return gcdTimer
    }()
    
    override init() {
        super.init()
        contentView.layer.insertSublayer(playerLayer, at: 0)
        contentView.addSubview(avProgress)
        contentView.addSubview(topView)
        contentView.addSubview(activityView)
        avProgress.snp.makeConstraints {
            $0.bottom.leading.trailing.equalToSuperview()
            $0.height.equalTo(80.0)
        }
        topView.snp.makeConstraints {
            $0.leading.trailing.top.equalToSuperview()
            $0.height.equalTo(44.0)
        }
        activityView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        // 播放、暂停按钮点击处理
        avProgress.operationButtonAction = { [weak self] in
            guard let self = self  else { return }
            if self.playerItemModel.userPlayStatus == .playing {
                self.playerItemModel.userPlayStatus = .pause
                self.pause()
            } else {
                self.playerItemModel.userPlayStatus = .playing
                if self.playerItemModel.isPlayComplete {
                    self.playerItemModel.currentDuration = 0
                    self.avPlayer.seek(to: CMTime(seconds: 0, preferredTimescale: self.avPlayer.currentItem?.currentTime().timescale ?? 1))
                }
                self.play()
            }
        }
        // 手动调整播放进度
        avProgress.playProgressValueChanged = { [weak self] (value) in
            guard let self = self  else { return }
            if let playerItem = self.avPlayer.currentItem {
                self.avPlayer.seek(to: CMTime(seconds: Double(value), preferredTimescale: playerItem.currentTime().timescale))
            }
        }
        
        // 更新播放层的大小
        contentView.observerBoundsChaned = { [weak self] in
            guard let self = self  else { return }
            self.playerLayer.frame = CGRect(x: 0, y: 0, width: $0.size.width, height: $0.size.height)
        }
        // 处理定时器
        handleTimer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 播放
    /// - Parameter fileUrl: 播放的视频或语音文件路径
    func play(fileUrl: URL) {
        let item = AVPlayerItem(url: fileUrl)
        avPlayer.replaceCurrentItem(with: item)
        // 重置
        self.playerItemModel.totalDuration = 0
        self.playerItemModel.currentDuration = 0
        // 播放状态
        self.playerItemModel.userPlayStatus = .playing
        play()
    }
    
    /// 播放，不用切换播放源
    func play() {
        avPlayer.play()
        // 开启定时器
        timer.resume()
        self.avProgress.playingChanged(status: self.playerItemModel.userPlayStatus)
    }
    
    /// 暂停
    func pause() {
        avPlayer.pause()
        // 暂停定时器
        timer.suspend()
        self.avProgress.playingChanged(status: self.playerItemModel.userPlayStatus)
    }

    /// 处理定时器
    private func handleTimer() {
        // 定时器事件处理
        timer.setEventHandler {
            DispatchQueue.main.async { [weak self] in
                guard let self = self,
                    let playerItem = self.avPlayer.currentItem else {return}
                if playerItem.status == .readyToPlay {
                    // 准备播放 计算总时长
                    if self.playerItemModel.totalDuration <= 0 {
                        self.playerItemModel.totalDuration = Int(playerItem.duration.seconds);
                        // 设置播放进度的最大值为总时长
                        self.avProgress.playProgress.maximumValue = Float(self.playerItemModel.totalDuration);
                        self.avProgress.totalTimeLabel.text = self.playerItemModel.totalDurationText;
                    }
                    
                    // 当前已播放时长
                    self.playerItemModel.currentDuration = Int(playerItem.currentTime().seconds);
                    self.avProgress.playTimeLabel.text = self.playerItemModel.currentDurationText
                    self.avProgress.playProgress.value = Float(self.playerItemModel.currentDuration)
                    #if DEBUG
                    print("总时长：\(self.playerItemModel.totalDuration)")
                    print("已播放时长：\(self.playerItemModel.currentDuration)")
                    #endif
                }
                if playerItem.isPlaybackBufferEmpty {
                    if self.playerItemModel.defaultStatus != .buffer {
                        // 显示加载loading
                        self.activityView.startAnimating()
                        self.playerItemModel.defaultStatus = .buffer
                    }
                    #if DEBUG
                    print("缓冲不足，正在缓冲中...")
                    #endif
                }
                if playerItem.isPlaybackLikelyToKeepUp {
                    if self.playerItemModel.defaultStatus != .playing {
                        // 隐藏加载loading
                        self.activityView.stopAnimating()
                        self.playerItemModel.defaultStatus = .playing
                    }
                    #if DEBUG
                    print("缓冲足够了，可以开始播放了")
                    #endif
                }
                
                // 计算缓冲
                let loadedTimeRanges: [NSValue] = playerItem.loadedTimeRanges
                if let timeRange: CMTimeRange = loadedTimeRanges.first?.timeRangeValue {
                    let startSeconds = timeRange.start.seconds
                    let durationSeconds = timeRange.duration.seconds
                    let timeInterval = startSeconds + durationSeconds
                    let progress = timeInterval / Double(self.playerItemModel.totalDuration)
                    self.avProgress.cacheProgress.progress = Float(progress)
                    #if DEBUG
                    print("缓冲进度：\(progress)")
                    #endif
                    
                }
                
                if self.playerItemModel.isPlayComplete {
                    // 播放完成
                    self.playerItemModel.userPlayStatus = .complete
                    self.pause()
                }
            }
        }
    }
}
