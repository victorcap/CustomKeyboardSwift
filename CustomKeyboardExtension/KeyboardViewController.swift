//
//  KeyboardViewController.swift
//
//  Created by Marcus Titton on 03/05/2020.
//  Copyright © 2020 Marcus Titton. All rights reserved.
//

import UIKit

var proxy : UITextDocumentProxy!

class KeyboardViewController: UIInputViewController {
	
	@IBOutlet var nextKeyboardButton: UIButton!
    @IBOutlet var keyboardView: UIView!
    @IBOutlet var bradescoView: UIView!
    
    //let autoCorrectObject: AutoCorrect = AutoCorrect.init()
    
    var popUpView: UIView!
    var popUpLetters: UIStackView!
    var keys: [UIButton] = []
    var suggestedKeys: [UIButton] = []
    var keyPressed: String = ""
	var paddingViews: [UIButton] = []
	var backspaceTimer: Timer?
    var userLexicon: UILexicon?
    
    var currentWord: String? {
        var lastWord: String?
        // 1
        if let stringBeforeCursor = textDocumentProxy.documentContextBeforeInput {
            // 2
            stringBeforeCursor.enumerateSubstrings(in: stringBeforeCursor.startIndex...,
                                                   options: .byWords)
            { word, _, _, _ in
                // 3
                if let word = word {
                    lastWord = word
                }
            }
        }
        return lastWord
    }
	
	enum KeyboardState{
		case letters
		case numbers
		case symbols
	}
	
	enum ShiftButtonState {
		case normal
		case shift
		case caps
	}
	
	var keyboardState: KeyboardState = .letters
	var shiftButtonState:ShiftButtonState = .normal
	
    @IBOutlet weak var stackView0: UIStackView!
    @IBOutlet weak var stackView1: UIStackView!
	@IBOutlet weak var stackView2: UIStackView!
	@IBOutlet weak var stackView3: UIStackView!
	@IBOutlet weak var stackView4: UIStackView!
    @IBOutlet weak var labelBradesco: UILabel!
    
	override func updateViewConstraints() {
		super.updateViewConstraints()
		// Add custom view sizing constraints here
        keyboardView.frame.size = view.frame.size
        //bradescoView.frame.size = view.frame.size
	} 
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		proxy = textDocumentProxy as UITextDocumentProxy
		loadInterface()
		self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
		
        requestSupplementaryLexicon { lexicon in
            self.userLexicon = lexicon
        }
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	override func viewWillLayoutSubviews() {
		self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey 
		super.viewWillLayoutSubviews()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		let heightConstraint = NSLayoutConstraint(item: view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: 270)
		view.addConstraint(heightConstraint)
		
	}
	
	func loadInterface(){
		let keyboardNib = UINib(nibName: "Keyboard", bundle: nil)
		keyboardView = keyboardNib.instantiate(withOwner: self, options: nil)[0] as? UIView
        
		view.addSubview(keyboardView)
		loadKeys()
	}
    
    func attemptToReplaceCurrentWord() {
        // 1
        guard let entries = userLexicon?.entries,
            let currentWord = currentWord?.lowercased() else {
            return
        }

        // 2
        let replacementEntries = entries.filter {
            $0.userInput.lowercased() == currentWord
        }

        if let replacement = replacementEntries.first {
            // 3
            for _ in 0..<currentWord.count {
                proxy.deleteBackward()
            }

            // 4
            proxy.insertText(replacement.documentText)
        }
    }
    
    func predictionWords()
    {
        suggestedKeys.forEach{$0.removeFromSuperview()}
        stackView0.subviews.forEach({$0.removeFromSuperview()})
        
        guard let currentWord = currentWord?.lowercased() else {
            return
        }
        
        if let items = self.autoSuggest(currentWord) {
            var numItems = items.count
            
            if numItems > 0 {
                
                if numItems > 2 {
                    numItems = 3
                }
                
                for row in 0...numItems - 1 {
                    if stackView0.arrangedSubviews.count > 0 {
                        let separator = UIView()
                        separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
                        separator.backgroundColor = .lightGray
                        stackView0.addArrangedSubview(separator)
                        separator.heightAnchor.constraint(equalTo: stackView0.heightAnchor, multiplier: 0.4).isActive = true
                    }
                    
                    let button = UIButton(type: .custom)
                    let key = items[row]
                    button.layer.setValue(key, forKey: "original")
                    button.setTitle(key, for: .normal)
                    button.setTitleColor(.darkGray, for: .normal)
                    button.addTarget(self, action: #selector(suggestionKeyPressedTouchUp), for: .touchUpInside)

                    suggestedKeys.append(button)
                    stackView0.addArrangedSubview(button)
                }
            }
        }
    }
	
	func addPadding(to stackView: UIStackView, width: CGFloat, key: String){
		let padding = UIButton(frame: CGRect(x: 0, y: 0, width: 5, height: 5))
		padding.setTitleColor(.clear, for: .normal)
		padding.alpha = 0.02
		padding.widthAnchor.constraint(equalToConstant: width).isActive = true
		
		//if we want to use this padding as a key, for example the a and l buttons
		let keyToDisplay = shiftButtonState == .normal ? key : key.capitalized
		padding.layer.setValue(key, forKey: "original")
		padding.layer.setValue(keyToDisplay, forKey: "keyToDisplay")
		padding.layer.setValue(false, forKey: "isSpecial")
		padding.addTarget(self, action: #selector(keyPressedTouchUp), for: .touchUpInside)
		padding.addTarget(self, action: #selector(keyTouchDown), for: .touchDown)
		padding.addTarget(self, action: #selector(keyUntouched), for: .touchDragExit)
		
		paddingViews.append(padding)
		stackView.addArrangedSubview(padding)
	}
	
	func loadKeys(){
		keys.forEach{$0.removeFromSuperview()}
		paddingViews.forEach{$0.removeFromSuperview()}
		
		let buttonWidth = (UIScreen.main.bounds.width - 6) / CGFloat(Constants.letterKeys[0].count)
		
		var keyboard: [[String]]
		
		//start padding
		switch keyboardState {
		case .letters:
			keyboard = Constants.letterKeys 
			addPadding(to: stackView2, width: buttonWidth/2, key: "a")
		case .numbers:
			keyboard = Constants.numberKeys
		case .symbols: 
			keyboard = Constants.symbolKeys
		}
		
		let numRows = keyboard.count
		for row in 0...numRows - 1{
			for col in 0...keyboard[row].count - 1{
				let button = UIButton(type: .custom)
				button.backgroundColor = Constants.keyNormalColour
				button.setTitleColor(.black, for: .normal) 
                let key = keyboard[row][col]
				let capsKey = key.capitalized
				let keyToDisplay = shiftButtonState == .normal ? key : capsKey
				button.layer.setValue(key, forKey: "original")
				button.layer.setValue(keyToDisplay, forKey: "keyToDisplay")
				button.layer.setValue(false, forKey: "isSpecial")
				button.setTitle(keyToDisplay, for: .normal)
				button.layer.borderColor = keyboardView.backgroundColor?.cgColor 
				button.layer.borderWidth = 4
				button.addTarget(self, action: #selector(keyPressedTouchUp), for: .touchUpInside)
				button.addTarget(self, action: #selector(keyTouchDown), for: .touchDown)
				button.addTarget(self, action: #selector(keyUntouched), for: .touchDragExit)
				button.addTarget(self, action: #selector(keyMultiPress(_:event:)), for: .touchDownRepeat)

                let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(keyLongPressed(_:)))
                button.addGestureRecognizer(longPressRecognizer)
                
//				if key == "⌫"{
//					let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(keyLongPressed(_:)))
//					button.addGestureRecognizer(longPressRecognizer)
//				}
				
				button.layer.cornerRadius = buttonWidth/4
				keys.append(button)
				switch row{
				case 0: stackView1.addArrangedSubview(button)
				case 1: stackView2.addArrangedSubview(button)
				case 2: stackView3.addArrangedSubview(button)
				case 3: stackView4.addArrangedSubview(button)
				default:
					break
				}
				if key == "🌐"{
					nextKeyboardButton = button
				}
				
				//top row is longest row so it should decide button width 
				print("button width: ", buttonWidth)
				if key == "⌫" || key == "💰" || key == "↩" || key == "#+=" || key == "ABC" || key == "123" || key == "⬆️" || key == "🌐"{
					button.widthAnchor.constraint(equalToConstant: buttonWidth + buttonWidth/2).isActive = true
					button.layer.setValue(true, forKey: "isSpecial")
					button.backgroundColor = Constants.specialKeyNormalColour
					if key == "⬆️" {
						if shiftButtonState != .normal{
							button.backgroundColor = Constants.keyPressedColour
						}
						if shiftButtonState == .caps{
							button.setTitle("⏫", for: .normal)
						}
					}
				}else if (keyboardState == .numbers || keyboardState == .symbols) && row == 2{
					button.widthAnchor.constraint(equalToConstant: buttonWidth * 1.4).isActive = true
				}else if key != "space"{
					button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true					
				}else{
					button.layer.setValue(key, forKey: "original")
					button.setTitle(key, for: .normal)
				}
			}
		} 
		
		
		//end padding
		switch keyboardState {
		case .letters:
			addPadding(to: stackView2, width: buttonWidth/2, key: "l")
		case .numbers: 
			break
		case .symbols: break
		}
		
	}
		
	func changeKeyboardToNumberKeys(){
		keyboardState = .numbers
		shiftButtonState = .normal
		loadKeys()
	}
	func changeKeyboardToLetterKeys(){
		keyboardState = .letters
		loadKeys()
	}
	func changeKeyboardToSymbolKeys(){
		keyboardState = .symbols
		loadKeys()
	}
	func handlDeleteButtonPressed(){
		proxy.deleteBackward()
	}
    
    func changeToBradesco(){
        bradescoView.frame.size = view.frame.size
        
        view.addSubview(bradescoView)
    }
    
    @IBAction func voltarTeclado(_ sender: Any) {
        view.addSubview(keyboardView)
    }
	
	@IBAction func keyPressedTouchUp(_ sender: UIButton) {
		guard let originalKey = sender.layer.value(forKey: "original") as? String, let keyToDisplay = sender.layer.value(forKey: "keyToDisplay") as? String else {return}
		
		guard let isSpecial = sender.layer.value(forKey: "isSpecial") as? Bool else {return}
		sender.backgroundColor = isSpecial ? Constants.specialKeyNormalColour : Constants.keyNormalColour

		switch originalKey {
		case "⌫":
			if shiftButtonState == .shift {
				shiftButtonState = .normal
				loadKeys()
			}
			handlDeleteButtonPressed()
		case "space":
            attemptToReplaceCurrentWord()
			proxy.insertText(" ")
		case "🌐":
			break
		case "↩":
			proxy.insertText("\n")
		case "123":
			changeKeyboardToNumberKeys()
		case "ABC":
			changeKeyboardToLetterKeys()
		case "#+=":
			changeKeyboardToSymbolKeys()
		case "⬆️": 
			shiftButtonState = shiftButtonState == .normal ? .shift : .normal
			loadKeys()
        case "💰":
            changeToBradesco()
		default:
			if shiftButtonState == .shift {
				shiftButtonState = .normal
				loadKeys()
			}
			proxy.insertText(keyToDisplay)
            predictionWords()
		}
	}
    
    @IBAction func suggestionKeyPressedTouchUp(_ sender: UIButton) {
        guard let originalKey = sender.layer.value(forKey: "original") as? String else {return}
        
        guard let currentWord = self.currentWord?.lowercased() else { return }
        
        for _ in 0..<currentWord.count {
            proxy.deleteBackward()
        }
        
        proxy.insertText(originalKey)
    }
	
	@objc func keyMultiPress(_ sender: UIButton, event: UIEvent){
		guard let originalKey = sender.layer.value(forKey: "original") as? String else {return}

		let touch: UITouch = event.allTouches!.first!
		if (touch.tapCount == 2 && originalKey == "⬆️") {
			shiftButtonState = .caps
			loadKeys()
		}
	}	
	
	@objc func keyLongPressed(_ gesture: UIGestureRecognizer){
		if gesture.state == .began {
            if self.view.viewWithTag(1001) != nil {
                 // remove popUpLetters
                //popUpKeys.forEach{$0.removeFromSuperview()}
                popUpView.removeFromSuperview()
            }
            
            var popUpKeys: [UIButton] = []
            
            let buttonWidth:CGFloat = 35.0
            let buttonHeight:CGFloat = 45.0
            var extraKeyboard: [String]

            let tapLocation = gesture.location(in: self.view)

            if let key = (gesture.view as! UIButton).titleLabel?.text {
                
                switch key {
                    case "a":
                        extraKeyboard = Constants.extrasLettersA
                    case "c":
                        extraKeyboard = Constants.extrasLettersC
                    case "e":
                        extraKeyboard = Constants.extrasLettersE
                    case "i":
                        extraKeyboard = Constants.extrasLettersI
                    case "n":
                        extraKeyboard = Constants.extrasLettersN
                    case "o":
                        extraKeyboard = Constants.extrasLettersO
                    case "s":
                        extraKeyboard = Constants.extrasLettersS
                    case "u":
                        extraKeyboard = Constants.extrasLettersU
                    case "y":
                        extraKeyboard = Constants.extrasLettersY
                    case "z":
                        extraKeyboard = Constants.extrasLettersZ
                    default:
                        extraKeyboard = [key]
                }
                
                let letters = extraKeyboard.count
                for row in 0...letters - 1{
                    let button = UIButton(type: .custom)
                    button.backgroundColor = Constants.keyNormalColour
                    button.setTitleColor(.black, for: .normal)
                    let key = extraKeyboard[row]
                    let capsKey = key.capitalized
                    let keyToDisplay = shiftButtonState == .normal ? key : capsKey
                    button.layer.setValue(key, forKey: "original")
                    button.layer.setValue(keyToDisplay, forKey: "keyToDisplay")
                    button.layer.setValue(false, forKey: "isSpecial")
                    button.setTitle(keyToDisplay, for: .normal)
                    button.layer.borderColor = keyboardView.backgroundColor?.cgColor
                    button.layer.borderWidth = 4
                    button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
                    button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
                    button.frame.size.width = buttonWidth
                    button.frame.size.height = buttonHeight
                    button.addTarget(self, action: #selector(keyPressedTouchUp), for: .touchUpInside)
                    button.addTarget(self, action: #selector(keyTouchDown), for: .touchDown)
                    button.addTarget(self, action: #selector(keyUntouched), for: .touchDragExit)
                    button.addTarget(self, action: #selector(keyMultiPress(_:event:)), for: .touchDownRepeat)
                    button.layer.cornerRadius = buttonWidth/4

                    popUpKeys.append(button)
                }
                
                popUpLetters = UIStackView(arrangedSubviews: popUpKeys)
                popUpLetters.axis = .horizontal
                popUpLetters.distribution = .equalSpacing
                popUpLetters.alignment = .center
                popUpLetters.spacing = 2.0
                popUpLetters.frame.size.width = popUpLetters.frame.size.width + 20
                popUpLetters.frame.size.height = popUpLetters.frame.size.height + 10
                popUpLetters.translatesAutoresizingMaskIntoConstraints = false
                popUpLetters.setNeedsLayout()
                popUpLetters.layoutIfNeeded()
                
                //proxy.insertText("\n \(popUpLetters.frame)")
                
                //popUpView=UIView(frame: CGRect(x: tapLocation.x-10, y: tapLocation.y-65, width: 100, height: 40))
                
                //PopUpView
                popUpView=UIView(frame: CGRect(x: tapLocation.x-10, y: tapLocation.y-65, width: popUpLetters.frame.size.width, height: popUpLetters.frame.size.height))
                popUpView.backgroundColor=keyboardView.backgroundColor
                popUpView.layer.cornerRadius=5
                popUpView.layer.borderWidth=2
                popUpView.tag=1001
                popUpView.layer.borderColor=UIColor.gray.cgColor
                popUpView.setNeedsLayout()
                popUpView.layoutIfNeeded()
                popUpView.addSubview(popUpLetters)
                
                self.view.addSubview(popUpView)
            }

//			backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
//				self.handlDeleteButtonPressed()
//			}
		} else if gesture.state == .ended || gesture.state == .cancelled {
            //popUpKeys.forEach{$0.removeFromSuperview()}
            popUpView.removeFromSuperview()
            (gesture.view as! UIButton).backgroundColor = Constants.keyNormalColour
//			backspaceTimer?.invalidate()
//			backspaceTimer = nil
//			(gesture.view as! UIButton).backgroundColor = Constants.specialKeyNormalColour
		}
	}
    
    @objc func extraButtonAction(sender: Any) {

        print("Entrou aqui")

        //Than remove popView
        popUpView.removeFromSuperview()
        //popUpKeys.forEach{$0.removeFromSuperview()}
    }
	
	@objc func keyUntouched(_ sender: UIButton){
		guard let isSpecial = sender.layer.value(forKey: "isSpecial") as? Bool else {return}
		sender.backgroundColor = isSpecial ? Constants.specialKeyNormalColour : Constants.keyNormalColour
	}
	
	@objc func keyTouchDown(_ sender: UIButton){
		sender.backgroundColor = Constants.keyPressedColour
	}
	
	override func textWillChange(_ textInput: UITextInput?) {
		// The app is about to change the document's contents. Perform any preparation here.
	}
	
	override func textDidChange(_ textInput: UITextInput?) {
		// The app has just changed the document's contents, the document context has been updated.
		
		var textColor: UIColor
		let proxy = self.textDocumentProxy
		if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
			textColor = UIColor.white
		} else {
			textColor = UIColor.black
		}
		self.nextKeyboardButton.setTitleColor(textColor, for: [])
	}
    
    func autoSuggest(_ word: String) -> [String]? {
        let textChecker = UITextChecker()
        let availableLanguages = UITextChecker.availableLanguages
        let preferredLanguage = (availableLanguages.count > 0 ? availableLanguages[0] : "en-US");
        
        let completions = textChecker.completions(forPartialWordRange: NSRange(0..<word.utf8.count), in: word, language: preferredLanguage)

        return completions
    }
    
//    private func topArrowView() -> UIView {
//        let arrowView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 8))
//        arrowView.translatesAutoresizingMaskIntoConstraints = false
//
//        let arrowHeight = arrowView.frame.height
//        let arrowWidth = arrowView.frame.width
//
//        let path = CGMutablePath()
//        path.move(to: CGPoint(x: 0, y: arrowHeight))
//        path.addLine(to: CGPoint(x: arrowWidth / 2, y: 0))
//        path.addLine(to: CGPoint(x: arrowWidth, y: arrowHeight))
//        path.addLine(to: CGPoint(x: 0, y: arrowHeight))
//
//        let shape = CAShapeLayer()
//        shape.path = path
//        shape.fillColor = UIColor.white.cgColor
//
//        arrowView.layer.insertSublayer(shape, at: 0)
//        return arrowView
//    }
	
}

extension UIStackView {
    func addHorizontalSeparators(color : UIColor) {
        var i = self.arrangedSubviews.count
        while i >= 0 {
            let separator = createSeparator(color: color)
            insertArrangedSubview(separator, at: i)
            separator.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1).isActive = true
            i -= 1
        }
    }

    private func createSeparator(color : UIColor) -> UIView {
        let separator = UIView()
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.backgroundColor = color
        return separator
    }
    
    func addVerticalSeparators(color : UIColor) {
        var i = self.arrangedSubviews.count
        while i > 1 {
            let separator = verticalCreateSeparator(color: color)
            insertArrangedSubview(separator, at: i-1)   // (i-1) for centers only
            separator.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 1).isActive = true
            i -= 1
        }
    }

    private func verticalCreateSeparator(color : UIColor) -> UIView {
        let separator = UIView()
        separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separator.backgroundColor = color
        return separator
    }
}
