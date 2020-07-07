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
    
    /// 播放状态 - 用于改变播放按钮展示状态
    open var playState: KJPlayerStatus = .unknown {
        didSet {
            btmView.playingChanged(status: playState)
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
    /// 定时器，用于自动显示和隐藏 默认当显示时5s后自动隐藏
    private var timer: DispatchSourceTimer = {
        let gcdTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        gcdTimer.schedule(deadline: DispatchTime.now(),
                          repeating: DispatchTimeInterval.seconds(1),
                          leeway: DispatchTimeInterval.milliseconds(10))
        return gcdTimer
    }()
    /// 计时
    private var countdown: Int = 5

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(topView)
        addSubview(btmView)
        
        topView.snp.makeConstraints({
            $0.height.equalTo(44.0)
            $0.leading.trailing.top.equalToSuperview()
        })
        
        btmView.snp.makeConstraints({
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(80.0)
        })
        // 添加手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundAction(tap:)))
        addGestureRecognizer(tap)
        
        timer.setEventHandler {
            DispatchQueue.main.async {  [weak self] in
                if self?.countdown == 0 {
                    self?.btmView.isHidden = true
                    self?.topView.isHidden = true
                    self?.timer.suspend()
                }
                self?.countdown -= 1
            }
        }
        // 开启定时器
        timer.resume()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 点击手势的处理
    @objc private func tapBackgroundAction(tap: UITapGestureRecognizer) {
        countdown = 5
        btmView.isHidden = false
        topView.isHidden = false
        // 开启定时器
        timer.resume()
    }
}
