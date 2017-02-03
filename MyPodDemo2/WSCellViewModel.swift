//
//  WSCellViewModel.swift
//  MyPodDemo2
//
//  Created by 刘先 on 17/2/2.
//  Copyright © 2017年 AsiaInfo. All rights reserved.
//

import UIKit

struct WSCellViewModel {
    var title: String
    var content: String
    var imageUrl: String?
    var imageHeight: CGFloat = 0
    
    init(title: String, content: String, imageUrl: String?) {
        self.title = title
        self.content = content
        self.imageUrl = imageUrl
    }
}
