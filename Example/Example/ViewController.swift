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
        
         // If you don't need a search tab, add the following code "before" super.viewDidLoad().
        //self.needSearchTab = false
 
        //selectedBar
        self.selectedBarHeight = 2
        self.selectedBar.layer.cornerRadius = 0
        self.selectedBar.backgroundColor = .gray
        
        //cells
        self.eachLineSpacing = 0
    }
    
    override func tabItems()-> [TabItem] {
        
        return [TabItem(title: "Home"),
                TabItem(title: "Memories"),
                TabItem(title: "Shared"),
                TabItem(title: "Albums")]
    }
    
    override func viewControllers()-> [UIViewController]
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let searchViewController = storyboard.instantiateViewController(withIdentifier: "searchView")
        let viewController1 = storyboard.instantiateViewController(withIdentifier: "view1")
        let viewController2 = storyboard.instantiateViewController(withIdentifier: "view2")
        let viewController3 = storyboard.instantiateViewController(withIdentifier: "view3")
        let viewController4 = storyboard.instantiateViewController(withIdentifier: "view4")
        
        return [searchViewController, viewController1, viewController2, viewController3, viewController4]
    }
    
}
