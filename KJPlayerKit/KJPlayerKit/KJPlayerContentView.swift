//
//  KJContentView.swift
//  KJPlayerKit
//
//  Created by 黄克瑾 on 2020/7/5.
//  Copyright © 2020 黄克瑾. All rights reserved.
//

import UIKit
import AVFoundation

class KJPlayerContentView: UIView {
    
    /// 播放前的预览图
    private(set) lazy var preview: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.isHidden = true
        return v
    }()
    
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
    
    /// 播放视图层
    private(set) var playerLayer: AVPlayerLayer = AVPlayerLayer(player: nil)
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(player: AVPlayer) {
        super.init(frame:.zero)
        playerLayer.player = player
        layer.addSublayer(playerLayer)
        addSubview(preview)
        addSubview(activityView)
        
        preview.snp.makeConstraints({
            $0.edges.equalToSuperview()
        })
        
        activityView.snp.makeConstraints({
            $0.center.equalToSuperview()
        })
    }
    
    /// 显示加载
    open func showLoadingAnimating() {
        activityView.startAnimating()
    }
    
    /// 隐藏加载
    open func hideLoadingAnimating() {
        activityView.stopAnimating()
    }
    
    /// 显示预览图
    open func showPreview() {
        preview.isHidden = false
    }
    
    /// 隐藏预览图
    open func hidePreview() {
        preview.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        
    }

}
