//
//  ViewController.swift
//  Example
//
//  Created by Yuiga Wada on 2019/08/22.
//  Copyright © 2019 Yuiga Wada. All rights reserved.
//

import UIKit
import PolioPager

class ViewController: PolioPagerViewController {
    
    override func viewDidLoad() {
        setup()
        
        super.viewDidLoad()
    }
    
    private func setup()
    {
        /*
         // If you don't need a search tab, add the following code "before" super.viewDidLoad().
         self.needSearchTab = false
         */
    }
    
    override func tabItems()-> [TabItem] {
        
        //I clearly have a caffeine addiction :)
        return [TabItem(title: "Redbull"),
                TabItem(title: "Monster"),
                TabItem(title: "Caffeine Addiction")]
    }
    
    override func viewControllers()-> [UIViewController]
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let viewController1 = storyboard.instantiateViewController(withIdentifier: "searchView")
        let viewController2 = storyboard.instantiateViewController(withIdentifier: "view1")
        let viewController3 = storyboard.instantiateViewController(withIdentifier: "view2")
        let viewController4 = storyboard.instantiateViewController(withIdentifier: "view3")
        
        return [viewController1, viewController2, viewController3, viewController4]
    }
    
}
