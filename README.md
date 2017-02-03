# Autolayout动态设置tableviewCell高度学习研究

### 背景
在类似微信朋友圈的UI中都会遇到图文兼有。比如这种
![image](http://upload-images.jianshu.io/upload_images/296926-d71f2ba3f3b47ed2.png?imageView2/2/w/1240/q/100)
总结起来有以下几个需求：
1. 文字的行数不定，需要自动换行，因此高度不定。
2. 还可能有图片，在有图片和没图片时需要有不同的高度。
3. 横向和shu竖向的图片需要占用不同的高度。
4. 图片从网络异步加载，因此不能在一开始获取到图片的高度。

因此UItableViewCell需要有动态高度，在网上有不少的解决方案，如果使用frame layout自然是没有什么问题的，今天主要想研究cell通过AutoLayout实现的解决方案
比如：

1. [Autolayout uitableviewcell 自适应cell高度](http://blog.csdn.net/damon2989/article/details/46373309)
通过为cell实现一个专用的获取height的方法，然后在uitableview的heightForRowAtIndexPath返回cell的高度，解决的是在autolayout情况下如何获取约束计算后的实际frame size的问题。
2. [AutoLayout在TableVew,CollectionView中的使用](http://www.jianshu.com/p/39bdb106e07e)
让tableView自适应cell高度，不用专门调用heightForRowAtIndexPath，但是这篇博客并没有提供源码，截图和代码也比较混乱，本屌愣是没看明白 :(

因此有了这片博文~

### 自己构建一个图文兼有的demo
> 本项目使用cocoapods构建，因为习惯使用SnapKit来写autolayout布局代码， 原生的写法实在看着想吐....， ib拖拽的又无法清晰的展现约束的详情。 代码基于Swift3.0

1.首先是 tableView的基础设置,在默认的ViewController中，然后在ViewDidLoad调用
```
fileprivate func buildTableView() {
        tableView = UITableView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        //设置这个让tableView自己决定高度,必须>0
        tableView.estimatedRowHeight = 100
        tableView.register(AutoLayoutTableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.delegate = self
        tableView.dataSource = self
    }
```
2.构造了一个非常简单的viewModel，用于给cell的控件赋值
```
struct WSCellViewModel {
    var title: String
    var content: String
    var imageUrl: String?
}

```
3.实现tableView的代理和数据源protocol
```
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! AutoLayoutTableViewCell
        cell.viewModel = viewModel[indexPath.row]
        return cell
    }
    
    //后来证明autolayout中并不需要实现这个方法，就可以自动计算高度了，前提是约束必须完整
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if let cell = tableView.dequeueReusableCell(withIdentifier: cellId) as? AutoLayoutTableViewCell {
//            cell.viewModel = viewModel[indexPath.row]
//            let cellHeight = cell.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
//            print("caculate cell height: \(cellHeight)")
//            return cellHeight
//        } else {
//            return 100
//        }
//    }
}
```
4.cell的代码，一共就3个subView, titleLabel, contentLabel和contentImageView, 下载图片后更新image的height constraint， 这里设置了width固定，高度根据图片尺寸比例变化。
```
//subView变量定义
var titleLabel: UILabel!
var contentLabel: UILabel!
var contentImageView: UIImageView!
var imageHeightConstraint: Constraint?

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
        //通过这个属性设置label的最大宽度，从而让UILabel知道什么时候该换行
        titleLabel.preferredMaxLayoutWidth = self.bounds.width - 20
        titleLabel.textColor = UIColor.lightGray
        titleLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
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
        contentLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            //底部和下面的顶部距离，需要用负数，如果是top to bottom就是正数
            make.bottom.equalTo(contentImageView.snp.top).offset(-10)
            make.right.greaterThanOrEqualTo(self).offset(-5)
        }
    }
    
    fileprivate func buildImageView() {
        contentImageView.contentMode = .scaleAspectFit
        contentImageView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.bottom.equalTo(self).offset(0)
            make.width.equalTo(fixedWidth)
            imageHeightConstraint = make.height.equalTo(0).constraint
        }
    }

```
5.加载cell数据的方法

```
func loadData() {
        guard let viewModel = viewModel else {
            return
        }
        titleLabel.text = viewModel.title
        //titleLabel.sizeToFit()
        contentLabel.text = viewModel.content
        contentLabel.sizeToFit()
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
                //一开始的就是image height约束冲突，如果不设置这个约束看看可以不
                updateImageHeight(height: scaledSize.height)
                
            } else { //没有缓存才下载
                imageManager.downloadImage(with: url, options: .retryFailed, progress: nil) {[weak self] (image, error, cacheType, isFinished, url) in
                    if error == nil {
                        if let weakSelf = self {
                            weakSelf.contentImageView.image = image
                            let scaledSize = weakSelf.getScaledSize(image: image!, fixWidth: weakSelf.fixedWidth)
                            print("getScaledSize \(NSStringFromCGSize(scaledSize))")
                            weakSelf.updateImageHeight(height: scaledSize.height)
                            if let delegate = weakSelf.delegate {
                                delegate.needUpdateConstraintCell()
                            }
                            //调用这个方法才会触发updateConstraints
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
```

### 遇到的问题
这段代码在第一次运行时会有约束冲突问题，爆两个UILabel的高度约束冲突。如图：
![约束冲突](http://p1.bpimg.com/567571/97b5fcc8097f622a.jpg)
我在网上找到一些相关的问题，
> [Ambiguous layout warnings for UILabels in UITableViewCell](http://note.youdahttp://stackoverflow.com/questions/28696264/ambiguous-layout-warnings-for-uilabels-in-uitableviewcell)
,通过设置UILabel的ContentHuggingPriority = UILayoutPriorityFittingSizeLevel 来解决，但是我这里并没有解决问题。

经过仔细分析错误日至，其实冲突实际上是出在
***
[LayoutConstraints] Unable to simultaneously satisfy constraints.
	Probably at least one of the constraints in the following list is one you don't want. 
	Try this: 
		(1) look at each constraint and try to figure out which you don't expect; 
		(2) find the code that added the unwanted constraint or constraints and fix it. 
(
    "<SnapKit.LayoutConstraint:0x6000000b42e0@AutoLayoutTableViewCell.swift#93 UILabel:0x7fecd1623ea0.top == MyPodDemo2.AutoLayoutTableViewCell:0x7fecd30b3a00.top + 10.0>",
    "<SnapKit.LayoutConstraint:0x6080000b4760@AutoLayoutTableViewCell.swift#106 UILabel:0x7fecd1624b00.top == UILabel:0x7fecd1623ea0.bottom + 10.0>",
    "<SnapKit.LayoutConstraint:0x6080000b47c0@AutoLayoutTableViewCell.swift#108 UILabel:0x7fecd1624b00.bottom == UIImageView:0x7fecd1624d90.top - 10.0>",
    "<SnapKit.LayoutConstraint:0x6000000b4520@AutoLayoutTableViewCell.swift#117 UIImageView:0x7fecd1624d90.bottom == MyPodDemo2.AutoLayoutTableViewCell:0x7fecd30b3a00.bottom>",
    "<SnapKit.LayoutConstraint:0x6000000b4460@AutoLayoutTableViewCell.swift#119 UIImageView:0x7fecd1624d90.height == 109.31768158474>",
    **"<NSLayoutConstraint:0x600000282f30 'UIView-Encapsulated-Layout-Height' MyPodDemo2.AutoLayoutTableViewCell:0x7fecd30b3a00'AutoLayoutTableViewCell'.height == 132   (active)>"**
)

Will attempt to recover by breaking constraint 
**<SnapKit.LayoutConstraint:0x6000000b4460@AutoLayoutTableViewCell.swift#119 UIImageView:0x7fecd1624d90.height == 109.31768158474>**
***
当异步图片加载完成后，我执行了更新imageView的height Constraint的操作，这时tableView的cellHeight并没有触发更新，因此高度冲突了，这个问题在网上也有遇到，但是没有完全消除警告。
> [what is NSLayoutConstraint “UIView-Encapsulated-Layout-Height” and how should I go about forcing it to recalculate cleanly](http://stackoverflow.com/questions/25059443/what-is-nslayoutconstraint-uiview-encapsulated-layout-height-and-how-should-i)

图片加载完成后，刷新cellView本身的layout是不能解决问题的，因为cell的高度已经由tableView自动计算好了，必须触发tableView的高度重算，我尝试去重写了tableView.heightForRowAt， 发现并没有用，因为这个方法是在渲染cell前触发的，那时候图片的高度也没有获取到。 不过由于我使用了SDWebImage库，第二次下载图片直接从缓存读取了，这时用heightForRowAt方法能获取到autolayout的完整size，因此可以正确的显示，也不会有约束冲突，但是在第一次加载图片时仍然会有问题。

并且如果是已经有缓存，能同步获取到imageView的height约束，那么就算不实现heightForRowAt也是会自动计算出正确高度的，因此如果使用autolayout，完全不用实现heightForRowAt方法。

### 解决异步加载图片后更新cell高度的问题

那么最后问题就集中在这里了，我们想实现cell中的imageView宽度固定，高度根据尺寸动态变化。
那理论上只需要通知tableView更新约束就可以了。
> 这个解决方案其实我在以前的项目中参考其他网上资料实现过，就是在cell中定义一个delegate,当图片加载完成后，触发delegate,由viewController处理，找到需要更新高度的cell，然后refreshRowAtIndexPath指定刷新那一行的数据。 但是cell自己怎么知道自己时哪一行数据呢？于是我还不得不在cell的model中定义了一个index字段，这样回调方在能获取行数，构造indexPath。stupid至极...

这次参考刚才的资料[what is NSLayoutConstraint “UIView-Encapsulated-Layout-Height” and how should I go about forcing it to recalculate cleanly](http://stackoverflow.com/questions/25059443/what-is-nslayoutconstraint-uiview-encapsulated-layout-height-and-how-should-i)中的解决方案， 还是在cell中定义了一个delegate,但是不需要传参数
```
protocol AutoLayoutTableViewCellDelegate {
    func needUpdateConstraintCell()
}
```
而viewController处理这个回调也很简单，只需要简单的setNeedsUpdateConstraints,不用reloadData了
```
func needUpdateConstraintCell() {
        tableView.beginUpdates()
        tableView.setNeedsUpdateConstraints()
        tableView.endUpdates()
    }
```
自此，动态高度变化已经完全实现了，除了约束冲突的提示仍然还存在，这个不知道怎么才能消除，但是显示效果是完全没有问题了，不管是第一次加载图片还是从缓存读取，高度都能正确适应，UILabel的多行显示也没有问题了。
最终效果：
![最终效果](http://i1.piimg.com/567571/009a4c7208aca331.jpg)

### 源码下载
[欢迎下载源码](https://github.com/wantsor/AutoResizeTableViewCell)

### 总结
这是本屌学习iOS两年来第一次写博客，目的除了想深入的理解一个原来项目中出现又没有处理好的场景之外，还想顺便熟悉下markdown书写语法，和博客的语言组织，整篇文章看下来非常乱，就请见谅啦，毕竟是处女作～ 