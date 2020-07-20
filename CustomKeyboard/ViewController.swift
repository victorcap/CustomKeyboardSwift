//
//  ViewController.swift
//
//  Created by Marcus Titton on 03/05/2020.
//  Copyright © 2020 Marcus Titton. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet weak var instructions: UITextView!
	@IBOutlet weak var dismissKeyboardButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
//		instructions.becomeFirstResponder()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupUI()
	}
	
	@IBAction func dismissKeyboardPressed(_ sender: Any) {
	instructions.resignFirstResponder()
	}
	
	func setupUI(){
		instructions.text = "Instruções para o teclado"
        instructions.autocorrectionType = .yes
	}



}

