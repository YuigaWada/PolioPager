//
//  SearchViewController.swift
//  Example
//
//  Created by Yuiga Wada on 2019/08/29.
//  Copyright © 2019 Yuiga Wada. All rights reserved.
//

import PolioPager
import UIKit

class SearchViewController: UIViewController, PolioPagerSearchTabDelegate, UITextFieldDelegate {
    @IBOutlet weak var label: UILabel!
    
    var searchBar: UIView!
    var searchTextField: UITextField!
    var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.delegate = self
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        label.text = text
        return true
    }
}
