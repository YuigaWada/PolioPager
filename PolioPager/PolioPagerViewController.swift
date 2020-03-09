//
//  PolioPagerViewController.swift
//  PolioPager
//
//  Created by Yuiga Wada on 2019/08/22.
//  Copyright © 2019 Yuiga Wada. All rights reserved.
//

import UIKit

public protocol PolioPagerDataSource {
    func viewControllers() -> [UIViewController]
    func tabItems() -> [TabItem]
}

public protocol PolioPagerSearchTabDelegate {
    var searchBar: UIView! { get set }
    var searchTextField: UITextField! { get set }
    var cancelButton: UIButton! { get set }
}

open class PolioPagerViewController: UIViewController, TabCellDelegate, PolioPagerDataSource, PageViewParent {
    // MARK: open IBOutlet
    
    @IBOutlet open weak var collectionView: UICollectionView!
    @IBOutlet open weak var searchBar: UIView!
    @IBOutlet open weak var selectedBar: UIView!
    @IBOutlet open weak var pageView: UIView!
    @IBOutlet open weak var searchTextField: UITextField!
    @IBOutlet open weak var cancelButton: UIButton!
    
    @IBOutlet private weak var borderView: UIView!
    
    // MARK: Input
    
    // Tab
    public var items: [TabItem] = []
    public var needSearchTab: Bool = true
    public var initialIndex: Int = 0
    public var tabBackgroundColor: UIColor = .white
    
    public var eachLineSpacing: CGFloat = 5
    public var sectionInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 10)
    public var selectedBarHeight: CGFloat = 3
    
    // selectedBar
    public var barAnimationDuration: Double = 0.23
    public var selectedBarMargins: (upper: CGFloat, lower: CGFloat) = (1, 2)
    
    // pageView
    public var pageViewMargin: CGFloat = 1
    public lazy var pageViewController = PageViewController(transitionStyle: .scroll,
                                                            navigationOrientation: .horizontal,
                                                            options: nil)
    
    // border
    public var needBorder: Bool = false {
        didSet {
            borderView.isHidden = !needBorder
        }
    }
    
    public var boderHeight: CGFloat = 1
    public var borderColor: UIColor = .lightGray {
        didSet {
            borderView.backgroundColor = borderColor
        }
    }
    
    // MARK: Var
    
    private var initialized: Bool = false
    private var defaultCellHeight: CGFloat?
    private lazy var bundle = Bundle(for: PolioPagerViewController.self)
    private var itemsFrame: [CGRect] = []
    private var itemsWidths: [CGFloat] = []
    
    // MARK: IBAction
    
    @IBAction func tappedCancel(_ sender: Any) {
        searchTextField.endEditing(true)
        moveTo(index: 1)
    }
    
    // MARK: LifeCycle
    
    open override func loadView() {
        guard let view = UINib(nibName: "PolioPagerViewController", bundle: bundle).instantiate(withOwner: self).first as? UIView else { return }
        
        self.view = view
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        initialIndex += needSearchTab ? 1 : 0
        pageViewController.parentVC = self
        
        setupCell()
        setupPageView()
        selectedBar.isHidden = true
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        defer { initialized = true }
        
        guard !initialized else { super.viewDidAppear(animated); return }
        
        setupComponent()
        
        if needSearchTab { changeCellAlpha(alpha: 0) }
        
        setupAnimator()
        setPages(viewControllers())
        setupAutoLayout()
        
        selectedBar.isHidden = false
        super.viewDidAppear(animated)
    }
    
    // MARK: Protocol
    
    open func viewControllers() -> [UIViewController] {
        fatalError("viewControllers are not provided.") // When this method wasn't overrided.
    }
    
    open func tabItems() -> [TabItem] {
        fatalError("tabItems are not provided.") // When this method wasn't overrided.
    }
    
    public func changeUserInteractionEnabled(searchTab: Bool) { // cf. PageViewController.swift
        searchBar.isUserInteractionEnabled = searchTab
        collectionView.isUserInteractionEnabled = !searchTab
    }
    
    // MARK: Setup
    
    private func setupCell() {
        collectionView.register(UINib(nibName: "TabCell", bundle: bundle), forCellWithReuseIdentifier: "cell")
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = (1 / 414) * eachLineSpacing * view.frame.width
        layout.scrollDirection = .horizontal
        layout.sectionInset = sectionInset
        
        collectionView.collectionViewLayout = layout
    }
    
    private func setupPageView() {
        pageViewController.view.frame = pageView.frame
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        pageView.addSubview(pageViewController.view)
        
        pageViewController.initialIndex = initialIndex
    }
    
    private func setupComponent() {
        // selectedBar: iPhoneXR(height=896)で、デフォルトheight=3なので、割合計算を行う。
        selectedBar.frame = CGRect(x: itemsFrame[0].origin.x,
                                   y: collectionView.frame.origin.y + collectionView.frame.height + selectedBarMargins.upper,
                                   width: itemsFrame[0].width,
                                   height: (1 / 896 * view.frame.height) * selectedBarHeight)
        
        // Tab
        changeUserInteractionEnabled(searchTab: false)
        
        // Color
        collectionView.backgroundColor = tabBackgroundColor
        view.backgroundColor = tabBackgroundColor
        searchBar.backgroundColor = .clear
        
        // Others
        collectionView.scrollsToTop = false
    }
    
    private func setupAnimator() {
        guard pageViewController.barAnimators.count == 0 else { return }
        
        var animators: [UIViewPropertyAnimator] = []
        var actions: [() -> Void] = []
        let maxIndex = itemsFrame.count - 2
        
        for index in 0 ... maxIndex {
            let nextFrame = itemsFrame[index + 1]
            let action = {
                // Selected Bar
                let barFrame = self.selectedBar.frame
                self.selectedBar.frame = CGRect(x: nextFrame.origin.x,
                                                y: barFrame.origin.y,
                                                width: nextFrame.width,
                                                height: barFrame.height)
                
                if self.needSearchTab, index == 0 {
                    self.changeCellAlpha(alpha: 1)
                    self.searchBar.alpha = 0.1
                }
            }
            
            let barAnimator = UIViewPropertyAnimator(duration: barAnimationDuration, curve: .easeInOut, animations: action)
            barAnimator.pausesOnCompletion = true // preventing animator from stopping when you leave your app.
            
            animators.append(barAnimator)
            actions.append(action)
        }
        
        var initialAction: (() -> Void)?
        
        if needSearchTab {
            let searchAction: (() -> Void)? = {
                let barFrame = self.selectedBar.frame
                
                self.selectedBar.frame = CGRect(x: self.itemsFrame[0].origin.x, // barFrame.origin.x + margin,
                                                y: barFrame.origin.y,
                                                width: self.itemsFrame[0].width,
                                                height: barFrame.height)
                
                self.changeCellAlpha(alpha: 0)
                self.searchBar.alpha = 1
            }
            
            initialAction = searchAction
        } else {
            let firstCellFrame = itemsFrame[0]
            initialAction = {
                let barFrame = self.selectedBar.frame
                self.selectedBar.frame = CGRect(x: firstCellFrame.origin.x,
                                                y: barFrame.origin.y,
                                                width: firstCellFrame.width,
                                                height: barFrame.height)
            }
        }
        
        pageViewController.setAnimators(needSearchTab: needSearchTab,
                                        animators: animators,
                                        originalActions: actions,
                                        initialAction: initialAction)
    }
    
    private func setPages(_ viewControllers: [UIViewController]) {
        guard viewControllers.count == items.count
        else { fatalError("The number of ViewControllers must equal to the number of TabItems.") }
        
        pageViewController.setPages(viewControllers)
        if needSearchTab {
            guard var searchTabViewController = viewControllers[0] as? PolioPagerSearchTabDelegate else { return }
            
            searchTabViewController.searchTextField = searchTextField
            searchTabViewController.searchBar = searchBar
            searchTabViewController.cancelButton = cancelButton
        }
    }
    
    private func setupAutoLayout() {
        // pageView
        if let pageView = self.pageView {
            pageView.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraints([
                NSLayoutConstraint(item: pageView,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .bottom,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: pageView,
                                   attribute: .left,
                                   relatedBy: .equal,
                                   toItem: view.safeAreaLayoutGuide,
                                   attribute: .left,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: pageView,
                                   attribute: .right,
                                   relatedBy: .equal,
                                   toItem: view.safeAreaLayoutGuide,
                                   attribute: .right,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: pageView,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: collectionView,
                                   attribute: .bottom,
                                   multiplier: 1.0,
                                   constant: selectedBarMargins.upper + selectedBarMargins.lower + pageViewMargin + selectedBar.frame.height + (needBorder ? boderHeight : 0))
            ])
        }
        
        // PageViewController
        if let view = pageViewController.view {
            pageView.addConstraints([
                NSLayoutConstraint(item: view,
                                   attribute: .centerX,
                                   relatedBy: .equal,
                                   toItem: pageView,
                                   attribute: .centerX,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: view,
                                   attribute: .centerY,
                                   relatedBy: .equal,
                                   toItem: pageView,
                                   attribute: .centerY,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: view,
                                   attribute: .width,
                                   relatedBy: .equal,
                                   toItem: pageView,
                                   attribute: .width,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: view,
                                   attribute: .height,
                                   relatedBy: .equal,
                                   toItem: pageView,
                                   attribute: .height,
                                   multiplier: 1.0,
                                   constant: 0)
            ])
        }
        
        // border
        if let border = borderView {
            border.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraints([
                NSLayoutConstraint(item: border,
                                   attribute: .centerX,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .centerX,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: border,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: pageView,
                                   attribute: .top,
                                   multiplier: 1.0,
                                   constant: (-1) * pageViewMargin),
                
                NSLayoutConstraint(item: border,
                                   attribute: .width,
                                   relatedBy: .equal,
                                   toItem: view,
                                   attribute: .width,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: border,
                                   attribute: .height,
                                   relatedBy: .equal,
                                   toItem: nil,
                                   attribute: .height,
                                   multiplier: 1.0,
                                   constant: boderHeight)
            ])
        }
    }
    
    // MARK: UI
    
    private func changeCellAlpha(alpha: CGFloat) {
        collectionView.visibleCells.filter {
            guard let indexPath = self.collectionView.indexPath(for: $0 as UICollectionViewCell) else { return false }
            return indexPath.row != 0
            
        }.forEach { $0.alpha = alpha }
        
        collectionView.backgroundColor = alpha == 1 ? tabBackgroundColor : .clear
        selectedBar.alpha = alpha
    }
    
    private func setSearchTab() {
        guard needSearchTab else { return }
        
        let searchItem = TabItem(image: UIImage(named: "search", in: bundle, compatibleWith: nil),
                                 cellWidth: 20)
        
        items.insert(searchItem, at: 0)
    }
    
    private func setTabItem(_ items: [TabItem]) {
        self.items = items
        setSearchTab()
        
        // フォントサイズをXRに合わせて計算し直す
        for i in 0 ... self.items.count - 1 {
            let item = self.items[i]
            var width: CGFloat
            let fontSize = (1 / 414 * view.frame.width) * self.items[i].font.pointSize
            
            self.items[i].font = item.font.withSize(fontSize)
            if let _ = item.image {
                width = item.cellWidth == nil ? defaultCellHeight! : item.cellWidth!
            } else {
                width = labelWidth(text: item.title!, font: item.font)
            }
            
            itemsWidths.append(width)
        }
        
        itemsWidths = recalculateWidths()
    }
    
    private func recalculateWidths() -> [CGFloat] // distribute extra margin to each cell.
    {
        var itemsWidths: [CGFloat] = []
        let cellMarginSum = CGFloat(items.count - 1) * eachLineSpacing
        let maxWidth = view.frame.width
        
        var cellSizeSum: CGFloat = 0
        self.itemsWidths.forEach {
            cellSizeSum += $0
        }
        
        let extraMargin = maxWidth - (sectionInset.right + sectionInset.left + cellMarginSum + cellSizeSum)
        let distributee = items.count - (needSearchTab ? 1 : 0) // 下記コメント参照
        
        guard extraMargin > 0 else {
            // 収まるようにフォントサイズを調整
            
            self.itemsWidths.removeAll()
            for i in 0 ... items.count - 1 {
                let item = items[i]
                var width: CGFloat = 0
                let fontSize = items[i].font.pointSize * 0.9 // * 0.9, 0.8, 0.7, 0.65, 0.6, 0.5 ...
                
                items[i].font = item.font.withSize(fontSize)
                
                if let _ = item.image {
                    width = item.cellWidth == nil ? defaultCellHeight! : item.cellWidth!
                } else {
                    width = labelWidth(text: item.title!, font: item.font)
                }
                
                self.itemsWidths.append(width)
            }
            
            return recalculateWidths() // recursion
        }
        
        self.itemsWidths.forEach {
            itemsWidths.append($0 + extraMargin / CGFloat(distributee))
        }
        
        if needSearchTab {
            itemsWidths[0] = self.itemsWidths[0] // searchTabのwidthは保持しておく
        }
        
        return itemsWidths
    }
    
    public func moveTo(index: Int) {
        pageViewController.moveTo(index: index)
    }
    
    // MARK: Utility
    
    private func labelWidth(text: String, font: UIFont) -> CGFloat {
        let label: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text + "AA" // 微調整
        
        label.sizeToFit()
        return label.frame.width
    }
}

extension PolioPagerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if defaultCellHeight == nil {
            defaultCellHeight = self.collectionView.frame.height
            setTabItem(tabItems())
        }
        
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.row
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        guard let tabCell = cell as? TabCell else { return cell }
        
        tabCell.delegate = self
        tabCell.index = index
        tabCell.backgroundColor = items[index].backgroundColor
        tabCell.titleLabel.textColor = items[index].normalColor
        tabCell.titleLabel.font = items[index].font
        
        if let image = items[index].image { // image優先
            tabCell.imageView.image = image
            tabCell.titleLabel.isHidden = true
        } else if let title = items[index].title {
            tabCell.titleLabel.text = title
            tabCell.titleLabel.font = items[index].font
        }
        
        // print(tabCell) //4Debug
        itemsFrame.append(tabCell.frame)
        
        return tabCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = itemsWidths[indexPath.row]
        
        guard let height = defaultCellHeight else {
            return CGSize(width: width, height: self.collectionView.frame.height)
        }
        
        return CGSize(width: width, height: height)
    }
}
