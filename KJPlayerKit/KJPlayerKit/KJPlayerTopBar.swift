//
//  KJNaviTopBar.swift
//  KJPlayerKit
//
//  Created by 黄克瑾 on 2020/7/5.
//  Copyright © 2020 黄克瑾. All rights reserved.
//

import UIKit

class KJPlayerTopBar: UIView {
    
    /// 返回按钮点击的回调
    var backButtonAction:(() -> Void)?
    /// 外部控制全屏
    var isFullScreen: Bool = false {
        didSet {
            backButton.snp.updateConstraints({
                $0.leading.equalToSuperview().offset(isFullScreen ? 60.0 : 10)
            })
        }
    }
    
    /// 返回按钮
    private(set) lazy var backButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(backIcon, for: .normal)
        btn.addTarget(self, action: #selector(didBackAction), for: .touchUpInside)
        return btn
    }()
    /// 返回按钮图标
    private let backIcon = UIImage(named: "kj_player_back_icon")
    
    /// 标题
    private(set) lazy var titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.systemFont(ofSize: 15.0)
        lb.textColor = .white
        return lb
    }()
    
    /// 渐变层
    private(set) lazy var gl: CAGradientLayer = {
        let gl = CAGradientLayer()
        gl.startPoint = CGPoint(x: 0.5, y: 1.0)
        gl.endPoint = CGPoint(x: 0.5, y: 0.0)
        gl.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.1).cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor
        ]
        gl.locations = [0, 0.5, 0.9]
        return gl
    }()
    
    @objc func didBackAction() {
        backButtonAction?()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gl, at: 0)
        addSubview(backButton)
        addSubview(titleLabel)
        
        backButton.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 40.0, height: 40.0))
            $0.leading.equalToSuperview().offset(10.0)
            $0.top.equalToSuperview().offset(4.0)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing)
            $0.centerY.equalTo(backButton)
            $0.trailing.equalToSuperview().offset(-20.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gl.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
    }
}
