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
    /// 当在小屏播放时，点击返回按钮的回调，由外部控制是退出控制器  还是有其它操作，全屏播放时，这里不会回调
    open var tapBackButtonAction: (()->Void)?
    /// 是否在播放
    open var isPlaying: Bool {
        return KJPlayerItemState.sharedInstance.userPlayStatus == .playing
    }
    
    /// 播放器
    private(set) var avPlayer = AVPlayer(playerItem: nil)
    
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
    
    /// 定时器 用于获取播放器各种状态
    private lazy var playerTimer: CADisplayLink = {
        let timer = CADisplayLink(target: self, selector: #selector(playerHandleTimer))
        timer.add(to: RunLoop.current, forMode: RunLoop.Mode.default)
        if #available(iOS 10.0, *) {
            timer.preferredFramesPerSecond = 2
        } else {
            timer.frameInterval = 2
        }
        return timer
    }()
    
    /// 记录屏幕方向
    private var lastDeviceOrientatio: UIDeviceOrientation = .unknown
    /// 是否进入全屏
    private var isFullScreen: Bool = false {
        didSet {
            operationView.isFullScreen = isFullScreen
        }
    }
    /// 获取Window
    private lazy var mainWindow: UIWindow? = {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }()
    
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self)
        pause()
        playerTimer.invalidate()
        
    }
    
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
            if KJPlayerItemState.sharedInstance.userPlayStatus == .playing {
                self.pause()
            } else {
                if KJPlayerItemState.sharedInstance.isPlayComplete {
                    KJPlayerItemState.sharedInstance.currentDuration = 0
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
        // 全屏切换
        operationView.tapFullScreenAction = { [weak self] in
            if self?.isFullScreen == true {
                self?.exitFullScreen()
            } else {
                self?.enterFullScreen()
            }
        }
        // 返回按钮
        operationView.backButtonAction = { [weak self] in
            if self?.isFullScreen == true {
                self?.exitFullScreen()
            } else {
                // 交给外部处理
                self?.tapBackButtonAction?()
            }
        }
        // 添加通知
        addNotifi()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 播放
    /// - Parameter fileUrl: 播放的视频或语音文件路径
    func play(fileUrl: URL) {
        // 准备播放的视频
        let item = AVPlayerItem(url: fileUrl)
        avPlayer.replaceCurrentItem(with: item)
        // 重置
        KJPlayerItemState.sharedInstance.reset()
        // 自动播放
        play()
    }
    
    /// 播放，不用切换播放源
    func play() {
        // 激活播放权限
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        try? AVAudioSession.sharedInstance().setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        // 开始播放
        avPlayer.play()
        // 播放状态
        KJPlayerItemState.sharedInstance.userPlayStatus = .playing
        // 开启定时器
        playerTimer.isPaused = false
        // 改变播放按钮样式
        operationView.playState = .playing;
    }
    
    /// 暂停
    func pause() {
        KJPlayerItemState.sharedInstance.userPlayStatus = .pause
        avPlayer.pause()
        // 暂停定时器
        playerTimer.isPaused = true
        // 改变播放按钮样式
        operationView.playState = .pause;
    }
    
    private lazy var KJPLAYER_SCREEN_SIZE = UIScreen.main.bounds.size
    /// 进入全屏
    func enterFullScreen() {
        if isFullScreen { return }
        isFullScreen = true
        lastDeviceOrientatio = UIDevice.current.orientation
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else {return}
            self.playerView.removeFromSuperview()
            self.mainWindow?.addSubview(self.playerView)
            self.playerView.snp.makeConstraints({
                $0.center.equalToSuperview()
                $0.size.equalTo(CGSize(width: self.KJPLAYER_SCREEN_SIZE.height, height: self.KJPLAYER_SCREEN_SIZE.width))
            })
            self.playerView.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2.0 * (self.lastDeviceOrientatio == .landscapeLeft ? 1.0 : -1.0))
        }
    }
    
    /// 退出全屏
    func exitFullScreen() {
        guard isFullScreen else { return }
        isFullScreen = false
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else {return}
            self.playerView.removeFromSuperview()
            self.contentView.addSubview(self.playerView)
            self.playerView.snp.makeConstraints({
                $0.edges.equalToSuperview()
            })
            self.playerView.transform = CGAffineTransform.identity
        }
    }
    
    /// 处理定时器
    @objc private func playerHandleTimer() {
        if let playerItem = avPlayer.currentItem {
            if playerItem.status == .readyToPlay {
                // 准备播放 计算总时长
                if KJPlayerItemState.sharedInstance.totalDuration <= 0 {
                    KJPlayerItemState.sharedInstance.totalDuration = Int(playerItem.duration.seconds);
                    // 设置播放进度的最大值为总时长
                    self.operationView.totalDuration = Float(KJPlayerItemState.sharedInstance.totalDuration);
                    self.operationView.totalDurationText = KJPlayerItemState.sharedInstance.totalDurationText;
                }
                
                // 当前已播放时长
                KJPlayerItemState.sharedInstance.currentDuration = Int(playerItem.currentTime().seconds);
                #if DEBUG
                print("总时长：\(KJPlayerItemState.sharedInstance.totalDuration)")
                print("已播放时长：\(KJPlayerItemState.sharedInstance.currentDuration)")
                #endif
            }
            if playerItem.isPlaybackBufferEmpty {
                if KJPlayerItemState.sharedInstance.defaultStatus != .buffer {
                    // 显示加载loading
                    self.playerView.showLoadingAnimating()
                    KJPlayerItemState.sharedInstance.defaultStatus = .buffer
                }
                #if DEBUG
                print("缓冲不足，正在缓冲中...")
                #endif
            }
            if playerItem.isPlaybackLikelyToKeepUp {
                if KJPlayerItemState.sharedInstance.defaultStatus != .playing {
                    // 隐藏加载loading
                    self.playerView.hideLoadingAnimating()
                    KJPlayerItemState.sharedInstance.defaultStatus = .playing
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
                KJPlayerItemState.sharedInstance.cacheDuration = Int(startSeconds + durationSeconds)
                #if DEBUG
                print("已缓冲：\(KJPlayerItemState.sharedInstance.cacheDuration)")
                #endif
            }
            self.operationView.showProgress(item: KJPlayerItemState.sharedInstance)
            if KJPlayerItemState.sharedInstance.isPlayComplete {
                // 播放完成
                KJPlayerItemState.sharedInstance.userPlayStatus = .complete
                self.pause()
            }
        }
    }
    
    /// 添加通知
    private func addNotifi() {
        NotificationCenter.default.removeObserver(self)
        // 开启检测设备旋转的通知
        if UIDevice.current.isGeneratingDeviceOrientationNotifications  {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceOrientationChange(ntf:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        // 被打断的通知
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(ntf:)), name: AVAudioSession.interruptionNotification, object: nil)
        // 进入后台的通知
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(ntf:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    /// 处理屏幕方向改变
    @objc func handleDeviceOrientationChange(ntf: Notification) -> Void {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .faceDown:
            // 屏幕朝下平躺
            break
        case .faceUp:
            // 屏幕朝上平躺
            break
        case .landscapeLeft:
            //屏幕向左横置
            if isFullScreen && lastDeviceOrientatio != deviceOrientation {
                // 需要改变方向
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.playerView.transform = CGAffineTransform.identity
                    self?.playerView.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2.0)
                }
                
            }
            break
        case .landscapeRight:
            // 屏幕向右横置
            if isFullScreen && lastDeviceOrientatio != deviceOrientation {
                // 需要改变方向
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.playerView.transform = CGAffineTransform.identity
                    self?.playerView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2.0)
                }
            }
            break
        case .portrait:
            // 屏幕直立
            break
        case .portraitUpsideDown:
            // 屏幕直立，上下颠倒
            break
        default:
            // 无法识别
            break
        }
        lastDeviceOrientatio = deviceOrientation
    }
    
    /// 被打断的通知
    @objc func handleInterruption(ntf: Notification) {
        // 暂停处理
        pause()
    }
    
}
