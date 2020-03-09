//
//  PageViewController.swift
//  PolioPager
//
//  Created by Yuiga Wada on 2019/08/22.
//  Copyright © 2019 Yuiga Wada. All rights reserved.
//

import UIKit

public protocol PageViewParent {
    var collectionView: UICollectionView! { get set }
    var barAnimationDuration: Double { get set }
    var pageViewController: PageViewController { get set }
    
    func changeUserInteractionEnabled(searchTab: Bool)
}

public class PageViewController: UIPageViewController, UIScrollViewDelegate {
    public var initialIndex: Int?
    public var barAnimators: [UIViewPropertyAnimator] = []
    
    public var tabActions: [() -> Void] = []
    public var initialAction: (() -> Void)?
    
    public var parentVC: PageViewParent? {
        didSet {
            barAnimationDuration = parentVC!.barAnimationDuration
        }
    }
    
    private var pages: [UIViewController] = []
    private var scrollPageView: UIScrollView?
    
    private var initialized: Bool = false
    private var needSearchTab: Bool = true
    
    private var nowIndex: Int = 0 {
        willSet(index) { // Set now page's scrollsToTop to true and other's one to false. (#3)
            guard !initialized, pages.count > 0, index >= 0, index < pages.count else { return }
            
            self.pages.forEach { page in
                let isNowPage = page === pages[index]
                page.view.allSubviews.forEach { subview in
                    guard let scrollView = subview as? UIScrollView else { return }
                    scrollView.scrollsToTop = isNowPage
                }
            }
        }
    }
    
    private var barAnimationDuration: Double = 0.23
    
    private var autoScrolled: Bool = false {
        didSet {
            // Auto Scroll時はユーザーの操作を受け付けないようにする
            guard let parentVC = self.parentVC else { return }
            parentVC.collectionView.isUserInteractionEnabled = !autoScrolled
            
            guard let scrollPageView = self.scrollPageView else { return }
            scrollPageView.isUserInteractionEnabled = !autoScrolled
        }
    }
    
    // MARK: LifeCycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !initialized else { return }
        scrollPageView?.scrollsToTop = false
        dataSource = self
        delegate = self
        
        let scrollView = view.subviews.filter { $0 is UIScrollView }.first as! UIScrollView
        scrollView.delegate = self // ** HACK **
        
        guard let parentVC = self.parentVC else { return }
        parentVC.pageViewController.view.subviews.forEach { subView in
            guard let scrollView = subView as? UIScrollView else { return }
            self.scrollPageView = scrollView
        }
        
        initialized = true
    }
    
    // MARK: SetMethod
    
    public func setAnimators(needSearchTab: Bool, animators: [UIViewPropertyAnimator], originalActions: [() -> Void], initialAction: (() -> Void)?) {
        for i in 0 ... (animators.count - 1) {
            animators[i].fractionComplete = (i >= initialIndex! ? 0 : 1)
        }
        
        barAnimators = animators
        tabActions = originalActions
        self.initialAction = initialAction
        self.needSearchTab = needSearchTab
    }
    
    public func setPages(_ vcs: [UIViewController]) {
        guard let index = initialIndex else { return }
        
        pages = vcs
        setViewControllers([pages[index]], direction: .forward, animated: true, completion: nil)
        
        nowIndex = index
    }
    
    /*
     ** READ THIS. **
     SearchBarはcollectionViewの上に載っていて、左へとスワイプした際、
     UIViewPropertyAnimatorでSearchBarのalphaを、alpha:1→0.1へとアニメーションさせています。
     (0.1なのはalpha:1→0とした場合、alpha=0の時UserInteractionをSearchBarが受け付けないためです。)
     
     alpha=0.1の時、searchBarは見かけ上非表示ですが、実際はcollectionViewの上に乗っかっているので
     collectionViewはUserInteractionを認識しません。
     したがって、searchBarとcollectionViewのisUserInteractionEnabledを入れ替える必要があります。
     (正直な話、UIViewPropertyAnimatorの適切な使い方がわからないだけです)
     
     (追記)
     SearchBarとcollectionViewの重なり順を逆転させました。
     */
    
    // タブ遷移のアニメーション, うまい方法見つからんかった
    // I couldn't find better solution to animate selectedBar when tabs is tapped.
    
    public func moveTo(index: Int) {
        guard index >= 0, index < pages.count else { return }
        guard index != nowIndex, !autoScrolled else { return }
        
        // pageView, selectedBar両者のアニメーション終了確定時の処理
        var isCompleted: Bool = false
        let finalCompletion: (Bool, Bool) -> Void = { needChangeUserInteraction, searchTab in
            if isCompleted {
                self.autoScrolled = false
                if needChangeUserInteraction { self.changeUserInteractionEnabled(searchTab: searchTab) }
            } else
            { isCompleted = true }
        }
        
        // After we call startAnimation() method to start the animations, each animators become unusable.
        // So, we have to recreate animators.
        // Additionaly, We should pay special attention to the fact that each animations depend on the current position of selectedBar.
        // We have to move selectedBar to index=0 once. → (1)
        
        var animators: [UIViewPropertyAnimator] = []
        var ascending: Bool = true // アニメーションの連鎖をindex:0 → n 順に取るか逆順に取るか
        var needChangeUserInteraction: Bool = false
        var toLeft: Bool = false
        
        if index < nowIndex // to left
        {
            toLeft = true
            ascending = false
            needChangeUserInteraction = (index == 0 && needSearchTab) // Bool
            
            if index == 0 {
                animators.append(UIViewPropertyAnimator(duration: needSearchTab ? 0.4 : barAnimationDuration,
                                                        curve: .easeInOut,
                                                        animations: initialAction))
                if !needSearchTab, nowIndex > 1 {
                    for i in 0 ... nowIndex - 2 { animators.append(createAnimator(i)) }
                }
            } else {
                for i in index - 1 ... nowIndex - 2 { animators.append(createAnimator(i)) }
            }
            
            animators = createChainAnimator(animators: animators, ascending: ascending)
        } else // to right
        {
            toLeft = false
            ascending = true
            needChangeUserInteraction = (nowIndex == 0 && needSearchTab) // Bool
            
            for i in nowIndex ... (index - 1) { animators.append(createAnimator(i)) }
            
            animators = createChainAnimator(animators: animators, ascending: ascending)
        }
        
        let n = animators.count - 1
        let startIndex = ascending ? n : 0
        let endIndex = ascending ? 0 : n
        
        let direction: UIPageViewController.NavigationDirection = toLeft ? .reverse : .forward
        
        autoScrolled = true
        barAnimators.forEach { $0.stopAnimation(true) }
        
        animators[startIndex].addCompletion { _ in
            self.nowIndex = index
            
            if self.initialAction != nil { self.initialAction!() } // memo: (1)
            
            self.barAnimators.removeAll()
            self.tabActions.forEach {
                self.barAnimators.append(UIViewPropertyAnimator(duration: self.barAnimationDuration, curve: .easeInOut, animations: $0))
            }
            
            for i in 0 ... self.barAnimators.count - 1 {
                self.barAnimators[i].fractionComplete = (i < index ? 1 : 0) // memo: (1)→Undo
                self.barAnimators[i].pausesOnCompletion = true // preventing animator from stopping when you leave your app.
            }
            
            animators.filter { $0.state == .active }.forEach { $0.stopAnimation(true) }
            animators.removeAll()
            
            finalCompletion(needChangeUserInteraction, toLeft)
        }
        
        animators[endIndex].startAnimation() // 連鎖アニメーションを発火
        setViewControllers([pages[index]], direction: direction, animated: true, completion: { _ in
            
            finalCompletion(needChangeUserInteraction, toLeft)
            
        }) // moves Page.
    }
    
    // MARK: Animator Utility
    
    private func createAnimator(_ index: Int) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: barAnimationDuration, curve: .easeInOut, animations: tabActions[index])
    }
    
    private func createChainAnimator(animators: [UIViewPropertyAnimator], ascending: Bool) -> [UIViewPropertyAnimator] {
        let n = animators.count - 1
        for i in 0 ... n {
            if !ascending, n - i - 1 >= 0 {
                animators[n - i].addCompletion { _ in
                    animators[n - i - 1].startAnimation()
                }
            }
            
            if ascending, i < n {
                animators[i].addCompletion { _ in
                    animators[i + 1].startAnimation()
                }
            }
        }
        
        return animators
    }
    
    // MARK: DelegateMethod
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !autoScrolled else { return }
        
        let maxWidth = view.frame.width
        
        var animator: UIViewPropertyAnimator?
        var complete: CGFloat?
        
        // 0.2,0.98というのは、たまに0.9975845410628019のような値になる時があるためです。
        if scrollView.contentOffset.x < maxWidth, nowIndex > 0 // left
        {
            animator = barAnimators[nowIndex - 1]
            complete = scrollView.contentOffset.x / maxWidth // 1 → 0
            
            if complete! < 0.2, nowIndex - 1 == 0 {
                changeUserInteractionEnabled(searchTab: true)
            }
        } else if scrollView.contentOffset.x >= maxWidth, nowIndex < pages.count - 1 // right
        {
            animator = barAnimators[nowIndex]
            complete = (scrollView.contentOffset.x - maxWidth) / maxWidth // 0 → 1
            
            if complete! > 0.98, nowIndex == 0 {
                changeUserInteractionEnabled(searchTab: false)
            }
        }
        
        guard complete != nil else { return }
        animator!.fractionComplete = complete!
        
        // For Debug
        // printAnimatorStates()
    }
    
    private func changeUserInteractionEnabled(searchTab: Bool) {
        guard let parentVC = self.parentVC else { return }
        
        parentVC.changeUserInteractionEnabled(searchTab: searchTab)
    }
    
    // MARK: 4Debug
    
    private func state2String(_ state: UIViewAnimatingState) -> String {
        switch state {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .stopped:
            return "stopped"
        @unknown default:
            fatalError("Unknown error.")
        }
    }
    
    private func printAnimatorStates() {
        print("--------")
        for i in 0 ... barAnimators.count - 1 {
            print("right" + i.description + ": " + barAnimators[i].fractionComplete.description + " state: " + state2String(barAnimators[i].state))
        }
        print("nowIndex: " + nowIndex.description)
    }
}

extension PageViewController: UIPageViewControllerDataSource
{
    public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        guard (index - 1) >= 0, pages.count > (index - 1) else {
            return nil
        }
        
        return pages[index - 1]
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        guard index + 1 != pages.count, pages.count > (index + 1) else {
            return nil
        }
        
        return pages[index + 1]
    }
}

extension PageViewController: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            let current = pageViewController.viewControllers![0]
            
            if let index = pages.firstIndex(of: current) {
                nowIndex = index
            }
        }
    }
}
