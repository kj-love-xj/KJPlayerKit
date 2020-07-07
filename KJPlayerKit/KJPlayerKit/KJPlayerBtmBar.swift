//
//  KJProgressBar.swift
//  KJPlayerKit
//
//  Created by 黄克瑾 on 2020/7/5.
//  Copyright © 2020 黄克瑾. All rights reserved.
//

import UIKit
import SnapKit

class KJPlayerBtmBar: UIView {
    
    /// 播放进度手动被改变外部的监听
    var playProgressValueChanged: ((_ value: Float) -> Void)?
    /// 播放/暂停按钮点击事件
    var operationButtonAction: (() -> Void)?
    
    /// 缓存进度
    private(set) lazy var cacheProgress: UIProgressView = {
        let v = UIProgressView(progressViewStyle: .default)
        v.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        v.progressTintColor = UIColor.white.withAlphaComponent(0.5)
        return v
    }()
    
    /// 播放进度
    private(set) lazy var playProgress: UISlider = {
        let slider = UISlider()
        slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0)
        slider.minimumTrackTintColor = UIColor.blue.withAlphaComponent(0.8)
        slider.setThumbImage(UIImage(named: "kj_player_slider_icon"), for: .normal)
        slider.addTarget(self, action: #selector(playProgressChang(slider:)), for: .valueChanged)
        return slider
    }()
    
    /// 播放 暂定按钮
    private(set) lazy var operationButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(stopIcon, for: .normal)
        return btn
    }()
    /// 播放图标
    private let playIcon = UIImage(named: "kj_player_play_icon")
    /// 暂停图标
    private let stopIcon = UIImage(named: "kj_player_stop_icon")
    
    /// 已播放时间
    private(set) lazy var playTimeLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = UIColor.white
        lb.font = UIFont.systemFont(ofSize: 12.0)
        lb.text = "00:00"
        lb.textAlignment = .center
        return lb
    }()
    
    /// 最大时间
    private(set) lazy var totalTimeLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = UIColor.white
        lb.font = UIFont.systemFont(ofSize: 12.0)
        lb.text = "00:00"
        lb.textAlignment = .center
        return lb
    }()
    
    /// 全屏缩小切换按钮
    private(set) lazy var screenSwitchButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(fullIcon, for: .normal)
        return btn
    }()
    /// 全屏图标
    private let fullIcon = UIImage(named: "kj_player_full_icon")
    /// 缩小图标
    private let smallIcon = UIImage(named: "kj_player_small_icon")
    
    /// 渐变层
    private(set) lazy var gl: CAGradientLayer = {
        let gl = CAGradientLayer()
        gl.startPoint = CGPoint(x: 0.5, y: 0)
        gl.endPoint = CGPoint(x: 0.5, y: 1.0)
        gl.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.1).cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor
        ]
        gl.locations = [0, 0.5, 0.9]
        return gl
    }()
    
    
    /// 播放进度手动滑动时的进度变化
    /// - Parameter slider: 播放进度条
    /// - Returns: Void
    @objc func playProgressChang(slider: UISlider) -> Void {
        self.playProgressValueChanged?(slider.value)
        
    }
    
    /// 改变播放状态样式
    func playingChanged(status: KJPlayerStatus) {
        operationButton.setImage(status == .playing ? stopIcon : playIcon, for: .normal)
    }
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        layer.insertSublayer(gl, at: 0)
        addSubview(operationButton)
        addSubview(playTimeLabel)
        addSubview(totalTimeLabel)
        addSubview(screenSwitchButton)
        addSubview(cacheProgress)
        addSubview(playProgress)
        
        operationButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(10.0)
            $0.size.equalTo(playIcon?.size ?? CGSize(width: 32.0, height: 32.0))
            $0.bottom.equalToSuperview().offset(-34.0)
        }
        
        playTimeLabel.snp.makeConstraints {
            $0.leading.equalTo(operationButton.snp.trailing).offset(5.0)
            $0.centerY.equalTo(operationButton)
            $0.width.equalTo(55.0)
        }
        
        screenSwitchButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-10.0)
            $0.size.equalTo(fullIcon?.size ?? CGSize(width: 44.0, height: 44.0))
            $0.centerY.equalTo(operationButton)
        }

        totalTimeLabel.snp.makeConstraints {
            $0.trailing.equalTo(screenSwitchButton.snp.leading).offset(-5.0)
            $0.centerY.equalTo(operationButton)
            $0.width.equalTo(playTimeLabel.snp.width)
        }
        
        cacheProgress.snp.makeConstraints {
            $0.leading.equalTo(playTimeLabel.snp.trailing).offset(5.0)
            $0.centerY.equalTo(operationButton)
            $0.trailing.equalTo(totalTimeLabel.snp.leading).offset(-5.0)
        }
        
        playProgress.snp.makeConstraints {
            $0.leading.trailing.equalTo(cacheProgress)
            $0.centerY.equalTo(cacheProgress).offset(-1.0)
        }
        
        operationButton.addTarget(self, action: #selector(playButtonAction), for: .touchUpInside)
    }
    
    /// 播放/暂停按钮点击事件
    @objc func playButtonAction() {
        operationButtonAction?()
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gl.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
    }
}
