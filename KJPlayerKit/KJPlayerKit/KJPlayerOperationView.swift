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
    open var tapFullScreenAction: (() -> Void)?
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
    
    
    
    /// 进度条
    private(set) lazy var btmView = KJPlayerBtmBar()
    
    /// 顶部导航
    private(set) lazy var topView = KJPlayerTopBar()

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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
