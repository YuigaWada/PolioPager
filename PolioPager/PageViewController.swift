//
//  PageViewController.swift
//  PolioPager
//
//  Created by Yuiga Wada on 2019/08/22.
//  Copyright © 2019 Yuiga Wada. All rights reserved.
//

import UIKit

public protocol PageViewParent
{
    var collectionView: UICollectionView! { get set }
    var barAnimationDuration: Double { get set }
    
    func changeUserInteractionEnabled(searchTab: Bool)
}

public class PageViewController: UIPageViewController, UIScrollViewDelegate {
    
    public var initialIndex: Int?
    public var barAnimators: [UIViewPropertyAnimator] = []
    public var animations: [()->()] = []
    public var searchAnimation: (()->())?
    
    
    private var pages: [UIViewController] = []
    private var nowIndex: Int = 0
    
    private var barAnimationDuration:Double = 0.23
    
    public var parentVC: PageViewParent?{
        didSet
        {
            self.barAnimationDuration = parentVC!.barAnimationDuration
        }
    }
    private var autoScrolled: Bool = false {
        didSet
        {
            //Auto Scroll時はユーザーの操作を受け付けないようにする
            guard let parentVC = self.parentVC else {return}
            parentVC.collectionView.isUserInteractionEnabled = !autoScrolled
        }
    }
    
    
    
    
    //MARK: LifeCycle
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.dataSource = self
        self.delegate = self
        
        let scrollView = view.subviews.filter { $0 is UIScrollView }.first as! UIScrollView
        scrollView.delegate = self // ** HACK **
    }
    
    
    
    
    //MARK: SetMethod
    public func setAnimators(_ animators: [UIViewPropertyAnimator], original: [()->()], searchAnimation: (()->())?)
    {
        for i in 0...(animators.count-1)
        {
            animators[i].fractionComplete = (i >= initialIndex! ? 0 : 1 )
        }
        
        self.barAnimators = animators
        self.animations = original
        self.searchAnimation = searchAnimation
    }
    
    public func setPages(_ vcs: [UIViewController])
    {
        guard let index = self.initialIndex else{return}
        
        self.pages = vcs
        self.setViewControllers([self.pages[index]], direction: .forward, animated: true, completion: nil)
        
        self.nowIndex = index
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
    
    
    public func moveTo(index: Int)
    {
        guard index >= 0 && index < pages.count else {return}
        guard index != nowIndex && !autoScrolled else {return}
        
        //タブ遷移のアニメーション, うまい方法見つからんかった
        //I couldn't find better solution to animate selectedBar when tabs is tapped.
        
        
        if index < nowIndex //to left
        {
            //After we call startAnimation() method to start the animations, each animators become unusable.
            //So, we have to recreate animators.
            
            var animators: [UIViewPropertyAnimator]  = []
            
            if index==0
            {
                animators.append(UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut, animations: searchAnimation))
            }
            else
            {
                for i in index-1...nowIndex-2
                {
                    animators.append(UIViewPropertyAnimator(duration: barAnimationDuration, curve: .easeInOut, animations: animations[i]))
                }
            }
            
            let n = animators.count-1
            for i in 0...n
            {
                if n-i-1 >= 0
                {
                    animators[n-i].addCompletion{ _ in
                        animators[n-i-1].startAnimation()
                    }
                }
            }
            
            autoScrolled = true
            self.barAnimators.forEach{ $0.stopAnimation(true) }
            
            /*
             ~Memo~
             ・Each animations depends on the current position of selectedBar, so we have to move selectedBar to index=0 once.(1)
             */
            animators[0].addCompletion({ _ in
                self.nowIndex = index
                
                self.barAnimators.removeAll()
                
                if self.searchAnimation != nil
                {
                    self.searchAnimation!() // memo: (1)
                }
                
                self.animations.forEach
                    {
                        self.barAnimators.append(UIViewPropertyAnimator(duration: self.barAnimationDuration, curve: .easeInOut, animations: $0))
                }
                
                for i in 0...self.barAnimators.count-1
                {
                    self.barAnimators[i].fractionComplete = (i < index ? 1 : 0) // memo: (1)→Undo
                    self.barAnimators[i].pausesOnCompletion = true //preventing animator from stopping when you leave your app.
                }
                
                //4Debug
//                self.barAnimators.forEach{
//                    print("fractionComplete:")
//                    print($0.fractionComplete)
//                }
                
                
                //TODO: 下二ついる？
                animators.filter{$0.state == .active}.forEach{
                    $0.stopAnimation(true)
                }
                
                animators.removeAll()
                
                
                if index==0
                {
                    self.changeUserInteractionEnabled(searchTab:true)
                }
            })
            
            animators[n].startAnimation()
            self.setViewControllers([self.pages[index]], direction: .reverse, animated: true, completion: {_ in  self.autoScrolled = false})
        }
        else //to right
        {
            //After we call startAnimation() method to start the animations, each animators become unusable.
            //So, we have to recreate animators.
            
            var animators: [UIViewPropertyAnimator]  = []
            for i in nowIndex...(index-1)
            {
                animators.append(UIViewPropertyAnimator(duration: barAnimationDuration, curve: .easeInOut, animations: animations[i]))
            }
            
            for i in 0...animators.count-1
            {
                if i+1 < animators.count
                {
                    animators[i].addCompletion{ _ in
                        animators[i+1].startAnimation()
                    }
                }
            }
            
            
            autoScrolled = true
            self.barAnimators.filter{ $0.state == .active }.forEach { $0.stopAnimation(true) }
            
            /*
             ~Memo~
             ・Each animations depends on the current position of selectedBar, so we have to move selectedBar to index=0 once.(1)
             */
            animators[animators.count-1].addCompletion({ _ in
                let now = self.nowIndex
                self.nowIndex = index
                
                self.barAnimators.removeAll()
                
                if self.searchAnimation != nil
                {
                    self.searchAnimation!() // memo: (1)
                }
                
                self.animations.forEach
                    {
                        self.barAnimators.append(UIViewPropertyAnimator(duration: self.barAnimationDuration, curve: .easeInOut, animations: $0))
                }
                
                for i in 0...self.barAnimators.count-1
                {
                    self.barAnimators[i].fractionComplete = (i < index ? 1 : 0) // memo: (1)→Undo
                    self.barAnimators[i].pausesOnCompletion = true//preventing animator from stopping when you leave your app.
                }
                
                
                //TODO: 下二ついる？
                animators.filter{$0.state == .active}.forEach{
                    $0.stopAnimation(true)
                }
                
                animators.removeAll()
                
                if now==0
                {
                    self.changeUserInteractionEnabled(searchTab:false)
                }
            })
            
            animators[0].startAnimation()
            self.setViewControllers([self.pages[index]], direction: .forward, animated: true, completion: {_ in                 self.autoScrolled = false})
            
        }
    }
    
    
    
    
    
    //MARK: DelegateMethod
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !autoScrolled else {return}
        
        
        let maxWidth = self.view.frame.width
        
        var animator: UIViewPropertyAnimator?
        var complete: CGFloat?
        
        
        //0.2,0.98というのは、たまに0.9975845410628019のような値になる時があるためです。
        if scrollView.contentOffset.x < maxWidth && nowIndex > 0 //left
        {
            animator = barAnimators[nowIndex-1]
            complete = scrollView.contentOffset.x / maxWidth // 1 → 0
            
            if complete! < 0.2 && nowIndex-1==0
            {
                changeUserInteractionEnabled(searchTab: true)
            }
        }
        else if scrollView.contentOffset.x >= maxWidth && nowIndex < pages.count - 1 //right
        {
            animator = barAnimators[nowIndex]
            complete = (scrollView.contentOffset.x - maxWidth) / maxWidth // 0 → 1
            
            if complete! > 0.98 && nowIndex==0
            {
                changeUserInteractionEnabled(searchTab: false)
            }
        }
        
        
        guard complete != nil else {return}
        animator!.fractionComplete = complete!
        
        
        
        //For Debug
//        print("--------")
//        for i in 0...barAnimators.count-1
//        {
//            print("right" + i.description + ": " + barAnimators[i].fractionComplete.description + " state: " + state2String(barAnimators[i].state))
//        }
//        print("nowIndex: " + nowIndex.description)
    }
    
    private func changeUserInteractionEnabled(searchTab: Bool)
    {
        guard let parentVC = self.parentVC else{return}
        
        parentVC.changeUserInteractionEnabled(searchTab: searchTab)
    }
    
    
    
    //MARK: 4Debug
    private func state2String(_ state: UIViewAnimatingState)-> String
    {
        switch state
        {
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
    
}






extension PageViewController : UIPageViewControllerDataSource
{
    public func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        guard (index - 1) >= 0  && pages.count > (index - 1) else {
            return nil
        }
        
        return pages[index - 1]
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController)  else {
            return nil
        }
        
        guard index+1 != pages.count && pages.count > (index+1) else {
            return nil
        }
        
        return pages[index+1]
    }
    
}






extension PageViewController: UIPageViewControllerDelegate{
    
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)
    {
        if completed {
            let current = pageViewController.viewControllers![0]
            
            if let index = pages.firstIndex(of: current)
            {
                self.nowIndex = index
            }
        }
    }
}
