//
//  AutoLayoutTableViewCell.swift
//  MyPodDemo2
//
//  Created by 刘先 on 17/2/2.
//  Copyright © 2017年 AsiaInfo. All rights reserved.
//

import UIKit
import SnapKit
import SDWebImage

protocol AutoLayoutTableViewCellDelegate {
    func needUpdateConstraintCell()
}

class AutoLayoutTableViewCell: UITableViewCell {
    
    //MARK: --> IBOutlet vars
    var titleLabel: UILabel!
    var contentLabel: UILabel!
    var contentImageView: UIImageView!
    var imageHeightConstraint: Constraint?
    
    var isInit = false
    var delegate: AutoLayoutTableViewCellDelegate?
    
    var viewModel: WSCellViewModel? {
        didSet {
            if let _ = viewModel {
                loadData()
            }
        }
    }
    
    let fixedWidth: CGFloat = 200
    
    //MARK: --> overrides
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        print("setupViews")
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        setupViews()
    }
    //TODO: 这个是什么时候调用?
    override func updateConstraints() {
        print("updateConstraints!")
        super.updateConstraints()
    }

    //MARK: --> public funcs
    
    //MARK: --> private funcs
    fileprivate func setupViews() {
        //如果是复用，约束可能已经加过了，会造成重复添加约束
        if !isInit {
            createSubViews()
            buildTitleLabel()
            buildContentLabel()
            buildImageView()
            isInit = true
            print("view is first loaded....")
        } else {
            print("view is reusing....")
        }
    }
    
    fileprivate func createSubViews() {
        titleLabel = UILabel()
        contentLabel = UILabel()
        contentImageView = UIImageView()
        self.addSubview(titleLabel)
        self.addSubview(contentLabel)
        self.addSubview(contentImageView)
    }
    
    fileprivate func buildTitleLabel() {
        titleLabel.numberOfLines = 1
        titleLabel.preferredMaxLayoutWidth = self.bounds.width - 20
        titleLabel.textColor = UIColor.lightGray
        //titleLabel.setContentHuggingPriority(UILayoutPriorityFittingSizeLevel, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(10)
            make.left.equalTo(self).offset(10)
            make.right.greaterThanOrEqualTo(self).offset(-5)
        }
    }
    
    fileprivate func buildContentLabel() {
        //最多4行,通过这个属性让label知道什么时候换行
        contentLabel.preferredMaxLayoutWidth = self.bounds.width - 20
        contentLabel.numberOfLines = 4
        //contentLabel.setContentHuggingPriority(UILayoutPriorityFittingSizeLevel, for: .vertical)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            //底部和下面的顶部距离，需要用负数，如果是top to bottom就是正数
            make.bottom.equalTo(contentImageView.snp.top).offset(-10)
            make.right.greaterThanOrEqualTo(self).offset(-5)
        }
    }
    
    fileprivate func buildImageView() {
        //contentImageView.contentMode = .scaleAspectFit
        contentImageView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.bottom.equalTo(self).offset(0)
            make.width.equalTo(fixedWidth)
            imageHeightConstraint = make.height.equalTo(0).constraint
        }
    }
    
    func loadData() {
        guard let viewModel = viewModel else {
            return
        }
        titleLabel.text = viewModel.title
        //设置preferredMaxLayoutWidth后不需要这个方法也能换行了
        //titleLabel.sizeToFit()
        contentLabel.text = viewModel.content
        //contentLabel.sizeToFit()
        //加载图片,默认高度为0
        let imageManager = SDWebImageManager()
        //imageHeightConstraint.update(offset: 0)
        if let imageUrl = viewModel.imageUrl {
            let url = URL(string: imageUrl)!
            //先判断是否已缓存了
            if imageManager.cachedImageExists(for: url) {
                print("getImage from Cache: \(imageUrl)")
                let cacheKey = imageManager.cacheKey(for: url)
                let image = imageManager.imageCache.imageFromDiskCache(forKey: cacheKey)
                contentImageView.image = image
                let scaledSize = getScaledSize(image: image!, fixWidth: fixedWidth)
                //更新高度约束
                updateImageHeight(height: scaledSize.height)
                
            } else { //没有缓存才下载
                imageManager.downloadImage(with: url, options: .retryFailed, progress: nil) {[weak self] (image, error, cacheType, isFinished, url) in
                    if error == nil {
                        if let weakSelf = self {
                            weakSelf.contentImageView.image = image
                            let scaledSize = weakSelf.getScaledSize(image: image!, fixWidth: weakSelf.fixedWidth)
                            print("getScaledSize \(NSStringFromCGSize(scaledSize))")
                            weakSelf.updateImageHeight(height: scaledSize.height)
                            //触发回调，让tableView刷新约束
                            if let delegate = weakSelf.delegate {
                                delegate.needUpdateConstraintCell()
                            }
                            //以下是根据网上资料来更新约束，实践证明并没有什么卵用...
                            //weakSelf.setNeedsLayout()
                            //weakSelf.layoutIfNeeded()
                            //weakSelf.layoutSubviews()
                        }
                        
                    }
                }
            }
            
        } else {
            contentImageView.image = UIImage()
            updateImageHeight(height: 0)
        }
        //这里手工调用以下方法反而会引起更新constraint的冲突
        //setNeedsLayout()
        //layoutIfNeeded()
    }
    
    fileprivate func getScaledSize(image: UIImage, fixWidth: CGFloat) -> CGSize {
        let scaleValue = fixWidth / image.size.width
        return CGSize(width: fixWidth, height: image.size.height * scaleValue)
    }
    
    fileprivate func updateImageHeight(height: CGFloat) {
        imageHeightConstraint?.update(offset: height)
    }
}


