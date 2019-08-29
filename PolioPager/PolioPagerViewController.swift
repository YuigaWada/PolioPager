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
    
    //MARK: Input
    public var items: [TabItem] = []
    public var searchTab: Bool = true
    public var initialIndex:Int = 0
    
    public var tabBackgroundColor: UIColor = .white
    
    public var barAnimationDuration: Double = 0.23
    
    
    public var eachLineSpacing: CGFloat = 10
    public var sectionInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    public var selectedBarHeight: CGFloat = 3
    
    
    
    //MARK: Var
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
        setTabItem(tabItems())
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupComponent()
        
        if searchTab{ changeCellAlpha(alpha: 0) }

        setupAnimator()
        setPages(viewControllers())
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
        layout.minimumInteritemSpacing = self.eachLineSpacing
        layout.scrollDirection = .horizontal
        layout.sectionInset = self.sectionInset
        
        self.collectionView.collectionViewLayout = layout
    }
    
    private func setupPageView()
    {
        self.pageView.addSubview(pageViewController.view)
        pageViewController.initialIndex = self.initialIndex
    }
    
    private func setupComponent()
    {
        //selectedBar
        let frame = selectedBar.frame
        selectedBar.frame = CGRect(x: itemsFrame[0].origin.x, y: frame.origin.y, width:itemsFrame[0].width , height: self.selectedBarHeight)
        
        //Tab
        changeUserInteractionEnabled(searchTab: false)
        
        //Color
        collectionView.backgroundColor = self.tabBackgroundColor
        
        //TODO: fix color bug
//        let cells = self.collectionView.visibleCells
//        for i in 0...cells.count-1
//        {
//            if let cell = cells[i] as? TabCell
//            {
//                //cell.titleLabel.textColor = items[i].normalColor
//            }
//        }
    }
    
    private func setupAnimator()
    {
        guard pageViewController.barAnimators.count == 0 else {return}
        
        var animators: [UIViewPropertyAnimator] = []
        var animations: [()->()] = []
        let maxIndex = self.itemsFrame.count-2
        
        
        for index in 0...maxIndex
        {
            let searchTabAnimation  = {
                if self.searchTab && index == 0
                {
                    self.changeCellAlpha(alpha: 1)
                    self.searchBar.alpha = 0.1
                }
            }
            
            
            let nowFrame = self.itemsFrame[index]
            let nextFrame = self.itemsFrame[index+1]
            //let margin = nextFrame.origin.x - nowFrame.origin.x //(always positive)
            
            let animation =
            {
                //Selected Bar
                let barFrame = self.selectedBar.frame
                self.selectedBar.frame = CGRect(x: nextFrame.origin.x,//barFrame.origin.x + margin,
                    y: barFrame.origin.y,
                    width: nextFrame.width,
                    height: barFrame.height)
                
                
                //Cell Color   TODO: fix bug
                if index != 0
                {
                    if let nowCell = self.collectionView.visibleCells[index] as? TabCell
                    {
                       //nowCell.titleLabel.textColor = self.items[index].normalColor
                    }
                }
                
                if index+1 < self.items.count
                {
                    if let nextCell = self.collectionView.visibleCells[index+1] as? TabCell
                    {
                        //nextCell.titleLabel.textColor = self.items[index+1].highlightedColor
                        nextCell.alpha=1
                    }
                }
                
                
                
                searchTabAnimation()
            }
            
            let barAnimator = UIViewPropertyAnimator(duration: self.barAnimationDuration, curve: .easeInOut, animations: animation)
            barAnimator.pausesOnCompletion = true //preventing animator from stopping when you leave your app.
            
            animators.append(barAnimator)
            animations.append(animation)
        }
        
        var searchAnimation: (()->())?
        if searchTab
        {
            searchAnimation =
                {
                    let barFrame = self.selectedBar.frame
                    
                    self.selectedBar.frame = CGRect(x: self.itemsFrame[0].origin.x,//barFrame.origin.x + margin,
                        y: barFrame.origin.y,
                        width: self.itemsFrame[0].width,
                        height: barFrame.height)
                    
                    self.changeCellAlpha(alpha: 0)
                    self.searchBar.alpha = 1
            }
            
        }
        
        pageViewController.setAnimators(animators, original: animations, searchAnimation: searchAnimation)
    }
    
    private func setPages(_ viewControllers: [UIViewController])
    {
        guard viewControllers.count == items.count else
        {
            fatalError("The number of ViewControllers must equal to the number of TabItems.")
        }
        
        pageViewController.setPages(viewControllers)
        
        if searchTab
        {
            guard var searchTabViewController = viewControllers[0] as? PolioPagerSearchTabDelegate else{return}
            
            searchTabViewController.searchTextField = self.searchTextField
            searchTabViewController.searchBar = self.searchBar
            searchTabViewController.cancelButton = self.cancelButton
        }
    }
    
    
    
    
    
    
    
    //MARK: UI
    private func changeCellAlpha(alpha: CGFloat)
    {
        self.collectionView.visibleCells.filter{
            
            guard let indexPath = self.collectionView.indexPath(for: $0 as UICollectionViewCell) else {return false}
            return indexPath.row != 0
            
            }.forEach{$0.alpha = alpha}
        
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
        
        
        self.items.forEach{item in
            var width: CGFloat
            
            if let _ = item.image
            {
                width = item.cellWidth == nil ? 50 : item.cellWidth!
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
        guard extraMargin > 0 else {return self.itemsWidths}
        
        
        
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
        return label.frame.width + 10
    }
    
}







extension PolioPagerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        else if let title = items[index].title {
            tabCell.titleLabel.text = title
        }
        
        print(tabCell)
        itemsFrame.append(tabCell.frame)
        
        return tabCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = itemsWidths[indexPath.row]
        
        return CGSize(width: width, height: 50)
    }
    
}
