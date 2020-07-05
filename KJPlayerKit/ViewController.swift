//
//  ViewController.swift
//  KJPlayerKit
//
//  Created by 黄克瑾 on 2020/7/5.
//  Copyright © 2020 黄克瑾. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var player = KJPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.addSubview(player.contentView)
        
        player.contentView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalToSuperview().offset(44.0)
            $0.height.equalTo(UIScreen.main.bounds.size.width)
        }
//        if let url = URL(string: "https://financial-search.oss-cn-beijing.aliyuncs.com/learningVideo/video/%E9%87%91%E8%9E%8D%E7%90%86%E8%AE%BA%20%E7%AC%AC01%E9%9B%86%EF%BC%9A%E4%B8%BA%E4%BD%95%E7%A0%94%E7%A9%B6%E9%87%91%E8%9E%8D%20.mp4") {
//            player.play(fileUrl: url)
//        }
        
    }


}

