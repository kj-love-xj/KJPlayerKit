//
//  KJPlayerOperationView.swift
//  KJPlayerKit
//
//  Created by 黄克瑾 on 2020/7/6.
//  Copyright © 2020 黄克瑾. All rights reserved.
//

import UIKit

class KJPlayerOperationView: UIView {
    
   /// 播放/暂停按钮点击事件
    open var playButtonAction: (() -> Void)? {
        didSet {
            btmView.operationButtonAction = playButtonAction
        }
    }
    /// 手动改变了播放进度的回调
    open var playProgressValueChanged: ((_ value: Float) -> Void)? {
        didSet {
            btmView.playProgressValueChanged = playProgressValueChanged
        }
    }
    /// 全屏按钮点击回调
    open var tapFullScreenAction: (() -> Void)? {
        didSet {
            btmView.tapFullScreenAction = tapFullScreenAction
        }
    }
    /// 返回按钮点击回调
    open var backButtonAction: (() -> Void)? {
        didSet {
            topView.backButtonAction = backButtonAction
        }
    }
    /// 双击事件
    open var doubleTapAction: (() -> Void)?
    
    /// 播放状态 - 用于改变播放按钮展示状态
    open var playState: KJPlayerStatus = .unknown {
        didSet {
            btmView.playingChanged(status: playState)
            playButton.isHidden = playState == .playing
            if playState == .playing {
                countdown = 5
                if timer?.isPaused == true { // 开启定时器
                    timer?.isPaused = false
                }
            } else {
                if timer?.isPaused == false {
                    timer?.isPaused = true
                }
                self.topView.isHidden = false
                self.btmView.isHidden = false
            }
        }
    }
    /// 设置进度条最大数值
    open var totalDuration: Float = 1.0 {
        didSet {
            btmView.playProgress.maximumValue = totalDuration
        }
    }
    /// 显示总时长
    open var totalDurationText: String = "00:00" {
        didSet {
            btmView.totalTimeLabel.text = totalDurationText
        }
    }
    /// 展示进度
    open func showProgress(item: KJPlayerItemState) {
        btmView.playTimeLabel.text = item.currentDurationText
        btmView.playProgress.value = Float(item.currentDuration)
        if item.cacheDuration > 0 {
            btmView.cacheProgress.progress = Float(item.cacheDuration) / Float(item.totalDuration);
            print("进度：\(btmView.cacheProgress.progress)")
        }
    }
    /// 设置标题
    open var title: String = "" {
        didSet {
            self.topView.titleLabel.text = title
        }
    }
    var isFullScreen: Bool = false {
        didSet {
            btmView.isFullScreen = isFullScreen
            topView.isFullScreen = isFullScreen
        }
    }
    
    /// 进度条
    private(set) lazy var btmView = KJPlayerBtmBar()
    /// 顶部导航
    private(set) lazy var topView = KJPlayerTopBar()
    private(set) lazy var playButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "kj_player_play_big_icon"), for: .normal)
        btn.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        btn.addTarget(self, action: #selector(playButtonHandle), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()
    /// 定时器，用于自动显示和隐藏 默认当显示时5s后自动隐藏
    private lazy var timer: CADisplayLink? = {
        let timer = CADisplayLink(target: self, selector: #selector(handleOperationTimer))
        timer.add(to: RunLoop.current, forMode: RunLoop.Mode.default)
        if #available(iOS 10.0, *) {
            timer.preferredFramesPerSecond = 1
        } else {
            timer.frameInterval = 1
        }
        return timer
    }()
    /// 计时
    private var countdown: Int = 5
    
    deinit {
        timer?.invalidate()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(topView)
        addSubview(btmView)
        addSubview(playButton)
        
        topView.snp.makeConstraints({
            $0.height.equalTo(44.0)
            $0.leading.trailing.top.equalToSuperview()
        })
        
        btmView.snp.makeConstraints({
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(80.0)
        })
        
        playButton.snp.makeConstraints({
            $0.center.equalToSuperview()
        })
        
        // 添加手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundAction))
        tap.delegate = self
        addGestureRecognizer(tap)
        // 添加双击
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapBackgroundAction))
        doubleTap.delegate = self
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        // 当双击失败时，才触发单击
        tap.require(toFail: doubleTap)
        // 开启定时器
        timer?.isPaused = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 处理定时器
    @objc private func handleOperationTimer() {
        if countdown == 0 {
            btmView.isHidden = true
            topView.isHidden = true
        }
        if countdown <= 0 {
            if timer?.isPaused == false {
                timer?.isPaused = true
            }
        }
        countdown -= 1
    }
    
    /// 点击手势的处理
    @objc private func tapBackgroundAction() {
        countdown = 5
        btmView.isHidden = false
        topView.isHidden = false
        if playState == .playing {
            // 开启定时器
            if timer?.isPaused == true {
                timer?.isPaused = false
            }
        }
        #if DEBUG
        print("触发了单击事件")
        #endif
    }
    
    /// 双击手势的处理
    @objc private func doubleTapBackgroundAction() {
        if timer?.isPaused == false {
            timer?.isPaused = true
        }
        doubleTapAction?()
        #if DEBUG
        print("触发了双击事件")
        #endif
    }
    
    /// 播放按钮点击的处理
    @objc private func playButtonHandle() {
        playButtonAction?()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension KJPlayerOperationView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == topView || touch.view == btmView {
            return false
        }
        return true
    }
}
