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


class KJPlayer: NSObject {
    /// 提供外部展示
    lazy var contentView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0)
        return v
    }()
    
    /// 设置播放标题
    open var title: String = "" {
        didSet {
            self.operationView.title = title
        }
    }
    
    /// 播放器
    private(set) lazy var avPlayer: AVPlayer = {
        return AVPlayer(playerItem: nil)
    }()
    
    /// 视频展示
    private lazy var playerView: KJPlayerContentView = {
        let v = KJPlayerContentView(player: avPlayer)
        v.backgroundColor = UIColor.white.withAlphaComponent(0)
        return v
    }()
    
    /// 用户手动操作层
    private lazy var operationView: KJPlayerOperationView = {
        let v = KJPlayerOperationView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0)
        return v
    }()
    
    
    
    /// 播放对象的相关数据
    private var playerItemModel = KJPlayerItemState()
    
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
        
        contentView.addSubview(playerView)
        playerView.addSubview(operationView)
        
        playerView.snp.makeConstraints({
            $0.edges.equalToSuperview()
        })
        operationView.snp.makeConstraints({
            $0.edges.equalToSuperview()
        })

        // 播放、暂停按钮点击处理
        operationView.playButtonAction = { [weak self] in
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
        operationView.playProgressValueChanged = { [weak self] (value) in
            guard let self = self  else { return }
            if let playerItem = self.avPlayer.currentItem {
                self.avPlayer.seek(to: CMTime(seconds: Double(value), preferredTimescale: playerItem.currentTime().timescale))
            }
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
        self.playerItemModel.cacheDuration = 0
        // 播放状态
        self.playerItemModel.userPlayStatus = .playing
        play()
    }
    
    /// 播放，不用切换播放源
    func play() {
        avPlayer.play()
        // 开启定时器
        timer.resume()
        // 改变播放按钮样式
        operationView.playState = self.playerItemModel.userPlayStatus;
    }
    
    /// 暂停
    func pause() {
        avPlayer.pause()
        // 暂停定时器
        timer.suspend()
        // 改变播放按钮样式
        operationView.playState = self.playerItemModel.userPlayStatus;
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
                        self.operationView.totalDuration = Float(self.playerItemModel.totalDuration);
                        self.operationView.totalDurationText = self.playerItemModel.totalDurationText;
                    }
                    
                    // 当前已播放时长
                    self.playerItemModel.currentDuration = Int(playerItem.currentTime().seconds);
                    #if DEBUG
                    print("总时长：\(self.playerItemModel.totalDuration)")
                    print("已播放时长：\(self.playerItemModel.currentDuration)")
                    #endif
                }
                if playerItem.isPlaybackBufferEmpty {
                    if self.playerItemModel.defaultStatus != .buffer {
                        // 显示加载loading
                        self.playerView.showLoadingAnimating()
                        self.playerItemModel.defaultStatus = .buffer
                    }
                    #if DEBUG
                    print("缓冲不足，正在缓冲中...")
                    #endif
                }
                if playerItem.isPlaybackLikelyToKeepUp {
                    if self.playerItemModel.defaultStatus != .playing {
                        // 隐藏加载loading
                        self.playerView.hideLoadingAnimating()
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
                    self.playerItemModel.cacheDuration = Int(startSeconds + durationSeconds)
                    #if DEBUG
                    print("已缓冲：\(self.playerItemModel.cacheDuration)")
                    #endif
                }
                self.operationView.showProgress(item: self.playerItemModel)
                if self.playerItemModel.isPlayComplete {
                    // 播放完成
                    self.playerItemModel.userPlayStatus = .complete
                    self.pause()
                }
            }
        }
    }
}
