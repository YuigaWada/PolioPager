//
//  PolioPagerViewController.swift
//  PolioPager
//
//  Created by Yuiga Wada on 2019/08/22.
//  Copyright © 2019 Yuiga Wada. All rights reserved.
//

import UIKit

public protocol PolioPagerDataSource
{
    func viewControllers()-> [UIViewController]
    func tabItems()-> [TabItem]
}

public protocol PolioPagerSearchTabDelegate
{
    var searchBar: UIView! { get set }
    var searchTextField: UITextField! { get set }
    var cancelButton: UIButton! { get set }
}


open class PolioPagerViewController: UIViewController, TabCellDelegate, PolioPagerDataSource, PageViewParent {
    
    
    //MARK: open IBOutlet
    @IBOutlet weak open var collectionView: UICollectionView!
    @IBOutlet weak open var searchBar: UIView!
    @IBOutlet weak open var selectedBar: UIView!
    @IBOutlet weak open var pageView: UIView!
    @IBOutlet weak open var searchTextField: UITextField!
    @IBOutlet weak open var cancelButton: UIButton!
    
    @IBOutlet weak private var borderView: UIView!
    
    
    //MARK: Input
    public var items: [TabItem] = []
    public var searchTab: Bool = true
    public var initialIndex:Int = 0
    
    public var tabBackgroundColor: UIColor = .white
    
    public var barAnimationDuration: Double = 0.23
    
    
    public var eachLineSpacing: CGFloat = 5
    public var sectionInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 10)
    public var selectedBarHeight: CGFloat = 3
    
    public var needBorder: Bool = false {
        didSet{
            self.borderView.isHidden = !needBorder
        }
    }
    public var boderHeight: CGFloat = 1
    public var borderColor: UIColor = .lightGray {
        didSet{
            self.borderView.backgroundColor = borderColor
        }
    }
    
    
    
    
    //MARK: Var
    private var initialized: Bool = false
    private var defaultCellHeight: CGFloat?
    private lazy var bundle = Bundle(for: PolioPagerViewController.self)
    private var itemsFrame: [CGRect] = []
    private var itemsWidths: [CGFloat] = []
    public lazy var pageViewController = PageViewController(transitionStyle: .scroll,
                                                            navigationOrientation: .horizontal,
                                                            options: nil)
    
    
    
    
    //MARK: IBAction
    @IBAction func tappedCancel(_ sender: Any) {
        self.searchTextField.endEditing(true)
        self.moveTo(index: 1)
    }
    
    
    
    
    //MARK: LifeCycle
    override open func loadView() {
        guard let view = UINib(nibName: "PolioPagerViewController", bundle: self.bundle).instantiate(withOwner: self).first as? UIView else {return}
        
        self.view = view
    }
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.initialIndex += searchTab ? 1 : 0 //TODO: ここいる？
        self.pageViewController.parentVC = self
        
        setupCell()
        setupPageView()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !initialized else {return}
        
        setupComponent()
        
        if searchTab{ changeCellAlpha(alpha: 0) }
        
        setupAnimator()
        setPages(viewControllers())
        setupAutoLayout()
        
        initialized = true
    }
    
    
    
    
    
    //MARK: Protocol
    open func viewControllers()->[UIViewController]
    {
        fatalError("viewControllers are not provided.") //When this method wasn't overrided.
    }
    
    open func tabItems()->[TabItem]
    {
        fatalError("tabItems are not provided.") //When this method wasn't overrided.
    }
    
    public func changeUserInteractionEnabled(searchTab: Bool) { // cf. PageViewController.swift
        searchBar.isUserInteractionEnabled = searchTab
        collectionView.isUserInteractionEnabled = !searchTab
    }
    
    
    
    
    
    //MARK: Setup
    private func setupCell()
    {
        collectionView.register(UINib(nibName: "TabCell", bundle: self.bundle),forCellWithReuseIdentifier:"cell")
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = (1/414) * self.eachLineSpacing * self.view.frame.width
        layout.scrollDirection = .horizontal
        layout.sectionInset = self.sectionInset
        
        self.collectionView.collectionViewLayout = layout
    }
    
    private func setupPageView()
    {
        pageViewController.view.frame = self.pageView.frame
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.pageView.addSubview(pageViewController.view)
        
        
        pageViewController.initialIndex = self.initialIndex
    }
    
    private func setupComponent()
    {
        //selectedBar: iPhoneXR(height=896)で、デフォルトheight=3なので、割合計算を行う。
        selectedBar.frame = CGRect(x: itemsFrame[0].origin.x,
                                   y: self.collectionView.frame.origin.y + self.collectionView.frame.height + 1,
                                   width:itemsFrame[0].width,
                                   height: ( 1/896 * self.view.frame.height ) * self.selectedBarHeight)
        
        
        //Tab
        changeUserInteractionEnabled(searchTab: false)
        
        //Color
        collectionView.backgroundColor = self.tabBackgroundColor
    }
    
    private func setupAnimator()
    {
        guard pageViewController.barAnimators.count == 0 else {return}
        
        var animators: [UIViewPropertyAnimator] = []
        var actions: [()->()] = []
        let maxIndex = self.itemsFrame.count-2
        
        
        for index in 0...maxIndex
        {
            let searchTabAction  = {
                if self.searchTab && index == 0
                {
                    self.changeCellAlpha(alpha: 1)
                    self.searchBar.alpha = 0.1
                }
            }
            
            
            let nextFrame = self.itemsFrame[index+1]
            let action = {
                //Selected Bar
                let barFrame = self.selectedBar.frame
                self.selectedBar.frame = CGRect(x: nextFrame.origin.x,//barFrame.origin.x + margin,
                    y: barFrame.origin.y,
                    width: nextFrame.width,
                    height: barFrame.height)
                
                searchTabAction()
            }
            
            let barAnimator = UIViewPropertyAnimator(duration: self.barAnimationDuration, curve: .easeInOut, animations: action)
            barAnimator.pausesOnCompletion = true //preventing animator from stopping when you leave your app.
            
            animators.append(barAnimator)
            actions.append(action)
        }
        
        let searchAction: (()->())? = !searchTab ? nil : {
            let barFrame = self.selectedBar.frame
            
            self.selectedBar.frame = CGRect(x: self.itemsFrame[0].origin.x,//barFrame.origin.x + margin,
                y: barFrame.origin.y,
                width: self.itemsFrame[0].width,
                height: barFrame.height)
            
            self.changeCellAlpha(alpha: 0)
            self.searchBar.alpha = 1
        }
        
        
        
        pageViewController.setAnimators(animators, originalActions: actions, searchAction: searchAction)
    }
    
    private func setPages(_ viewControllers: [UIViewController])
    {
        guard viewControllers.count == items.count
            else { fatalError("The number of ViewControllers must equal to the number of TabItems.") }
        
        pageViewController.setPages(viewControllers)
        if searchTab
        {
            guard var searchTabViewController = viewControllers[0] as? PolioPagerSearchTabDelegate else{return}
            
            searchTabViewController.searchTextField = self.searchTextField
            searchTabViewController.searchBar = self.searchBar
            searchTabViewController.cancelButton = self.cancelButton
        }
    }
    
    private func setupAutoLayout()
    {
        //pageView
        if let pageView = self.pageView
        {
            pageView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraints([
                NSLayoutConstraint(item: pageView,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .bottom,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: pageView,
                                   attribute: .left,
                                   relatedBy: .equal,
                                   toItem: self.view.safeAreaLayoutGuide,
                                   attribute: .left,
                                   multiplier: 1.0,
                                   constant:0),
                
                NSLayoutConstraint(item: pageView,
                                   attribute: .right,
                                   relatedBy: .equal,
                                   toItem: self.view.safeAreaLayoutGuide,
                                   attribute: .right,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: pageView,
                                   attribute: .top,
                                   relatedBy: .equal,
                                   toItem: self.collectionView,
                                   attribute: .bottom,
                                   multiplier: 1.0,
                                   constant: self.selectedBar.frame.height + 2 + (needBorder ? self.boderHeight : 0))
                ])
        }
        
        //PageViewController
        if let view = self.pageViewController.view
        {
            self.pageView.addConstraints([
                NSLayoutConstraint(item: view,
                                   attribute: .centerX,
                                   relatedBy: .equal,
                                   toItem: self.pageView,
                                   attribute: .centerX,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: view,
                                   attribute: .centerY,
                                   relatedBy: .equal,
                                   toItem: self.pageView,
                                   attribute: .centerY,
                                   multiplier: 1.0,
                                   constant:0),
                
                NSLayoutConstraint(item: view,
                                   attribute: .width,
                                   relatedBy: .equal,
                                   toItem: self.pageView,
                                   attribute: .width,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: view,
                                   attribute: .height,
                                   relatedBy: .equal,
                                   toItem: self.pageView,
                                   attribute: .height,
                                   multiplier: 1.0,
                                   constant:0)
                ])
        }
        
        //border
        if let border = self.borderView
        {
            border.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraints([
                NSLayoutConstraint(item: border,
                                   attribute: .centerX,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .centerX,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: border,
                                   attribute: .bottom,
                                   relatedBy: .equal,
                                   toItem: self.pageView,
                                   attribute: .top,
                                   multiplier: 1.0,
                                   constant:0),
                
                NSLayoutConstraint(item: border,
                                   attribute: .width,
                                   relatedBy: .equal,
                                   toItem: self.view,
                                   attribute: .width,
                                   multiplier: 1.0,
                                   constant: 0),
                
                NSLayoutConstraint(item: border,
                                   attribute: .height,
                                   relatedBy: .equal,
                                   toItem: nil,
                                   attribute: .height,
                                   multiplier: 1.0,
                                   constant: self.boderHeight)
                ])
        }
        
    }
    
    
    
    
    
    
    //MARK: UI
    private func changeCellAlpha(alpha: CGFloat)
    {
        self.collectionView.visibleCells.filter{
            
            guard let indexPath = self.collectionView.indexPath(for: $0 as UICollectionViewCell) else {return false}
            return indexPath.row != 0
            
            }.forEach{$0.alpha = alpha}
        
        self.collectionView.backgroundColor = alpha == 1 ? tabBackgroundColor : .clear
        self.selectedBar.alpha = alpha
    }
    
    private func setSearchTab()
    {
        guard self.searchTab else {return}
        
        let searchItem = TabItem(image: UIImage(named: "search", in: self.bundle, compatibleWith: nil),
                                 cellWidth: 20)
        
        self.items.insert(searchItem, at: 0)
    }
    
    private func setTabItem(_ items: [TabItem])
    {
        self.items = items
        self.setSearchTab()
        
        //フォントサイズをXRに合わせて計算し直す
        for i in 0...self.items.count-1
        {
            let item = self.items[i]
            var width: CGFloat
            let fontSize = ( 1/414 * self.view.frame.width ) * self.items[i].font.pointSize

            
            self.items[i].font = item.font.withSize(fontSize)
            if let _ = item.image
            {
                width = item.cellWidth == nil ? defaultCellHeight! : item.cellWidth!
            }
            else
            {
                width = labelWidth(text: item.title!, font: item.font)
            }
            
            itemsWidths.append(width)
        }
        
        itemsWidths = self.recalculateWidths()
    }
    
    private func recalculateWidths()-> [CGFloat] //distribute extra margin to each cell.
    {
        var itemsWidths: [CGFloat] = []
        let cellMarginSum = CGFloat(items.count - 1) * eachLineSpacing
        let maxWidth = self.view.frame.width
        
        var cellSizeSum: CGFloat = 0
        self.itemsWidths.forEach{
            cellSizeSum += $0
        }
        
        let extraMargin = maxWidth - (sectionInset.right + sectionInset.left + cellMarginSum + cellSizeSum)
        let distributee = items.count - (searchTab ? 1 : 0) //下記コメント参照
        
        
        guard extraMargin > 0 else {
            //収まるようにフォントサイズを調整
            
            self.itemsWidths.removeAll()
            for i in 0...self.items.count-1
            {
                let item = self.items[i]
                var width: CGFloat = 0
                let fontSize = self.items[i].font.pointSize * 0.9 // * 0.9, 0.8, 0.7, 0.65, 0.6, 0.5 ...
                
                
                self.items[i].font = item.font.withSize(fontSize)
                
                if let _ = item.image
                {
                    width = item.cellWidth == nil ? defaultCellHeight! : item.cellWidth!
                }
                else{
                    width = labelWidth(text: item.title!, font: item.font)
                }
                
                self.itemsWidths.append(width)
            }
            
            return self.recalculateWidths() //recursion
        }
        
        
        
        self.itemsWidths.forEach{
            itemsWidths.append($0 + extraMargin / CGFloat(distributee))
        }
        
        
        if searchTab
        {
            itemsWidths[0] = self.itemsWidths[0] //searchTabのwidthは保持しておく
        }
        
        return itemsWidths
    }
    
    public func moveTo(index: Int)
    {
        self.pageViewController.moveTo(index: index)
    }
    
    
    
    
    
    
    //MARK: Utility
    private func labelWidth(text:String, font:UIFont) -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text + "AA" //微調整
        
        label.sizeToFit()
        return label.frame.width
    }
    
}







extension PolioPagerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if defaultCellHeight == nil
        {
            defaultCellHeight = self.collectionView.frame.height
            setTabItem(tabItems())
        }
        
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.row
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        guard let tabCell = cell as? TabCell else {return cell}
        
        tabCell.delegate = self
        tabCell.index = index
        
        if let image = items[index].image{ //image優先
            tabCell.imageView.image = image
            tabCell.titleLabel.isHidden = true
        }
        else if let title = items[index].title{
            tabCell.titleLabel.text = title
            tabCell.titleLabel.font = items[index].font
        }
        
        //print(tabCell) //4Debug
        itemsFrame.append(tabCell.frame)
        
        return tabCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = itemsWidths[indexPath.row]
        
        guard let height = defaultCellHeight else{
            return CGSize(width: width, height: self.collectionView.frame.height)
        }
        
        
        return CGSize(width: width, height: height)
    }
    
}
