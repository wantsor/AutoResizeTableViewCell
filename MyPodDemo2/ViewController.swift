//
//  ViewController.swift
//  MyPodDemo2
//
//  Created by 刘先 on 16/12/14.
//  Copyright © 2016年 AsiaInfo. All rights reserved.
//

import UIKit
import SnapKit


class ViewController: UIViewController {
    
    var tableView: UITableView!
    
    var viewModel = [WSCellViewModel]()
    
    let cellId = "AutoLayoutTableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        buildTableView()
        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func buildTableView() {
        tableView = UITableView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        //设置这个让tableView自己决定高度,必须>0
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.estimatedRowHeight = UITableViewAutomaticDimension
        tableView.register(AutoLayoutTableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    fileprivate func loadData() {
        viewModel.removeAll()
        viewModel.append(WSCellViewModel(title: "UIViewControllerTransitioningDelegate", content: "用于支持自定义切换或切换交互，定义了一组供animator对象实现的协议，来自定义切换。可以为动画的三个阶段单独提供animator对象：presenting，dismissing，interacting", imageUrl: "http://tse3.mm.bing.net/th?id=OIP.M816be425206464dbd5c65bde360642e9o2&pid=15.1"))
        viewModel.append(WSCellViewModel(title: "UIViewControllerAnimatedTransitioning", content: "主要用于定义切换时的动画。这个动画的运行时间是固定的，而且无法进行交互。", imageUrl: nil))
        viewModel.append(WSCellViewModel(title: "UIViewControllerTransitioningDelegate", content: "用于支持自定义切换或切换交互，定义了一组供animator对象实现的协议，来自定义切换。可以为动画的三个阶段单独提供animator对象：presenting，dismissing，interacting", imageUrl: "http://images.cnitblog.com/blog/256851/201311/19213113-abf3eeb3d9f0457792859b938bcbe8dd.png"))
        viewModel.append(WSCellViewModel(title: "UIViewControllerTransitioningDelegate", content: "下面，我们趁热打铁，来实现一个交互式的custom transion。何谓交互式的custom transion呢？举个简单的例子，有个navController，push了viewController A，在A页面可以通过手指从左向右的滑动的方式pop到上一级ViewController。在滑动的过程中，你也可以取消当前的pop。这种交互的方式，是Apple在iOS7中推荐的", imageUrl: "http://images.cnitblog.com/blog/256851/201311/30222711-9cd6db36dc3e4de9a3d9c8c34f93dc1c.png"))
        tableView.reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource, AutoLayoutTableViewCellDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! AutoLayoutTableViewCell
        cell.delegate = self
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

    func needUpdateConstraintCell() {
        tableView.beginUpdates()
        tableView.setNeedsUpdateConstraints()
        tableView.endUpdates()
    }
}
