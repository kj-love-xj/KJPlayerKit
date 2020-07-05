//
//  KJContentView.swift
//  KJPlayerKit
//
//  Created by 黄克瑾 on 2020/7/5.
//  Copyright © 2020 黄克瑾. All rights reserved.
//

import UIKit

class KJContentView: UIView {

    var observerBoundsChaned: ((_ bounds: CGRect)->Void)?
    
    func loadSubviews() {
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.observerBoundsChaned?(bounds)
    }

}
