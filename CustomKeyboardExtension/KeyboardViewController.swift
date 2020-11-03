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

        if let stringBeforeCursor = textDocumentProxy.documentContextBeforeInput {
            stringBeforeCursor.enumerateSubstrings(in: stringBeforeCursor.startIndex...,
                                                   options: .byWords)
            { word, _, _, _ in
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
	
    @IBOutlet weak var suggestionColorBar: UIView!
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
	} 
	
	override func viewDidLoad() {
		super.viewDidLoad()
		proxy = textDocumentProxy as UITextDocumentProxy
		loadInterface()
		self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
		
        requestSupplementaryLexicon { lexicon in
            self.userLexicon = lexicon
        }
        
        self.suggestionColorBar.frame.size.width = UIScreen.main.bounds.width
        self.suggestionColorBar.applyGradient(colours: [Constants.gradientFirstColorClassic, Constants.gradientSecondColorClassic, Constants.gradienteThirdColorClassic, Constants.gradienteFourthColorClassic, Constants.gradienteFifthColorClassic])
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
		let heightConstraint = NSLayoutConstraint(item: view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: 260)
		view.addConstraint(heightConstraint)
		
	}
	
	func loadInterface(){
		let keyboardNib = UINib(nibName: "Keyboard", bundle: nil)
		keyboardView = keyboardNib.instantiate(withOwner: self, options: nil)[0] as? UIView
        keyboardView.backgroundColor = Constants.keyboardViewColour
        
		view.addSubview(keyboardView)
		loadKeys()
	}
    
    func attemptToReplaceCurrentWord() {
        guard let entries = userLexicon?.entries,
            let currentWord = currentWord?.lowercased() else {
            return
        }

        let replacementEntries = entries.filter {
            $0.userInput.lowercased() == currentWord
        }

        if let replacement = replacementEntries.first {
            for _ in 0..<currentWord.count {
                proxy.deleteBackward()
            }

            proxy.insertText(replacement.documentText)
        }
    }
    
    func predictionWords() {
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
                    button.setTitleColor(Constants.buttonSuggestionTextColour, for: .normal)
                    button.addTarget(self, action: #selector(suggestionKeyPressedTouchUp), for: .touchUpInside)
                    button.widthAnchor.constraint(equalToConstant: stackView0.bounds.width/CGFloat(numItems)-CGFloat(numItems - 1)).isActive = true

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
		
		let buttonWidth = (UIScreen.main.bounds.width - 6) / CGFloat(Constants.letterKeys[0].count + 1)
		
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
                button.setTitleColor(Constants.titleButtonColour, for: .normal)
                let key = keyboard[row][col]
				let capsKey = key.capitalized
				let keyToDisplay = shiftButtonState == .normal ? key : capsKey
                button.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
                button.layer.shadowOffset = CGSize(width: 0, height: 1)
                button.layer.shadowOpacity = 0.5
                button.layer.shadowRadius = 0.0
                button.layer.masksToBounds = false
                button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
				button.layer.setValue(key, forKey: "original")
				button.layer.setValue(keyToDisplay, forKey: "keyToDisplay")
				button.layer.setValue(false, forKey: "isSpecial")
				button.setTitle(keyToDisplay, for: .normal)
//				button.layer.borderColor = keyboardView.backgroundColor?.cgColor
//				button.layer.borderWidth = 3
				button.addTarget(self, action: #selector(keyPressedTouchUp), for: .touchUpInside)
				button.addTarget(self, action: #selector(keyTouchDown), for: .touchDown)
				button.addTarget(self, action: #selector(keyUntouched), for: .touchDragExit)
				button.addTarget(self, action: #selector(keyMultiPress(_:event:)), for: .touchDownRepeat)
                button.layer.cornerRadius = buttonWidth/5
                
                if key != "🌐" && key != "Bradesco" && key != "Retorno" && key != "#+=" && key != "ABC" && key != "123" && key != "⬆️" && key != "space" {
                    if key == "⌫"{
                        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(backspaceKeyLongPressed(_:)))
                        button.addGestureRecognizer(longPressRecognizer)
                    }
                    else
                    {
                        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(keyLongPressed(_:)))
                        button.addGestureRecognizer(longPressRecognizer)
                    }
                }
				
				if key == "🌐"{
					nextKeyboardButton = button
                    button.layer.setValue(false, forKey: "isSpecial")
                    button.backgroundColor = Constants.keyNormalColour
                    button.setTitle("", for: .normal)
                    button.setImage(UIImage(named: "ico_globe"), for: .normal)
				}
                
                if key == "Bradesco" {
                    button.layer.setValue(false, forKey: "isSpecial")
                    button.backgroundColor = Constants.keyNormalColour
                    button.setTitle("", for: .normal)
                    button.setImage(UIImage(named: "ico_bradesco_classic"), for: .normal)
                }
                
				if key == "⌫" || key == "#+=" || key == "ABC" || key == "123" || key == "⬆️" {
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
					button.widthAnchor.constraint(equalToConstant: buttonWidth + buttonWidth/2).isActive = true
					button.layer.setValue(true, forKey: "isSpecial")
					button.backgroundColor = Constants.specialKeyNormalColour
					if key == "⬆️" {
                        button.backgroundColor = Constants.keyNormalColour
                        button.setTitle("", for: .normal)
                        button.setImage(UIImage(named: "ico_arrow"), for: .normal)
                        button.layer.setValue(false, forKey: "isSpecial")
                        
						if shiftButtonState != .normal{
                            button.setImage(UIImage(named: "ico_arrow_selected"), for: .normal)
						}
						if shiftButtonState == .caps{
                            button.setImage(UIImage(named: "ico_arrow_selected"), for: .normal)
						}
					}
                    
                    if key == "⌫" {
                        button.setTitle("", for: .normal)
                        button.setImage(UIImage(named: "ico_backspace"), for: .normal)
                    }
				}else if key == "Retorno"{
                    button.widthAnchor.constraint(equalToConstant: buttonWidth * 2).isActive = true
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
                    button.setTitleColor(.white, for: .normal)
                    
                    let btnWidth:CGFloat = 68.0
                    let btnHeight:CGFloat = 47.0
                    
                    button.widthAnchor.constraint(equalToConstant: btnWidth).isActive = true
                    button.heightAnchor.constraint(equalToConstant: btnHeight).isActive = true
                    button.frame.size.width = btnWidth
                    button.frame.size.height = btnHeight
                    
                    button.updateConstraints()
                    
                    if #available(iOS 13, *) {
                        if traitCollection.userInterfaceStyle == .dark {
                            /// Return the color for Dark Mode
                            button.backgroundColor = Constants.specialKeyNormalColour
                        } else {
                            /// Return the color for Light Mode
                            button.applyGradient(colours: [Constants.gradientFirstColorReturnClassic, Constants.gradientSecondColorReturnClassic, Constants.gradientThirdColorReturnClassic])
                        }
                    } else {
                        /// Return a fallback color for iOS 12 and lower.
                        button.applyGradient(colours: [Constants.gradientFirstColorReturnClassic, Constants.gradientSecondColorReturnClassic, Constants.gradientThirdColorReturnClassic])
                    }
                }else if (keyboardState == .numbers || keyboardState == .symbols) && row == 2{
					button.widthAnchor.constraint(equalToConstant: buttonWidth * 1.4).isActive = true
				}else if key != "espaço"{
                    button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
                }else if key == "espaço" {
                    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
                }else{
					button.layer.setValue(key, forKey: "original")
					button.setTitle(key, for: .normal)
				}
                
                keys.append(button)
                switch row{
                case 0: stackView1.addArrangedSubview(button)
                case 1: stackView2.addArrangedSubview(button)
                case 2: stackView3.addArrangedSubview(button)
                case 3: stackView4.addArrangedSubview(button)
                default:
                    break
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
            predictionWords()
		case "espaço":
            attemptToReplaceCurrentWord()
			proxy.insertText(" ")
            suggestedKeys.forEach{$0.removeFromSuperview()}
            stackView0.subviews.forEach({$0.removeFromSuperview()})
		case "🌐":
			break
		case "Retorno":
			proxy.insertText("\n")
            suggestedKeys.forEach{$0.removeFromSuperview()}
            stackView0.subviews.forEach({$0.removeFromSuperview()})
		case "123":
			changeKeyboardToNumberKeys()
		case "ABC":
			changeKeyboardToLetterKeys()
		case "#+=":
			changeKeyboardToSymbolKeys()
		case "⬆️": 
			shiftButtonState = shiftButtonState == .normal ? .shift : .normal
			loadKeys()
        case "Bradesco":
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
    
    @objc func backspaceKeyLongPressed(_ gesture: UIGestureRecognizer){
        if gesture.state == .began {
            backspaceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
                self.handlDeleteButtonPressed()
            }
        } else if gesture.state == .ended || gesture.state == .cancelled {
            backspaceTimer?.invalidate()
            backspaceTimer = nil
            (gesture.view as! UIButton).backgroundColor = Constants.specialKeyNormalColour
        }
    }
	
	@objc func keyLongPressed(_ gesture: UIGestureRecognizer){
		if gesture.state == .began {
            if self.view.viewWithTag(1001) != nil {
                 // remove popUpLetters
                //popUpKeys.forEach{$0.removeFromSuperview()}
                popUpView.removeFromSuperview()
            }
            
//            let buttonHeightOriginal = suggestionColorBar.bounds
//
//            proxy.insertText("\(buttonHeightOriginal)")
            
            var keyboardColor: UIColor?
            
            if #available(iOS 13, *) {
                if traitCollection.userInterfaceStyle == .dark {
                    keyboardColor = UIColor(red: 29/255.0, green: 29/255.0, blue: 29/255.0, alpha: 1)
                } else {
                    keyboardColor = UIColor(red: 236/255.0, green: 239/255.0, blue: 241/255.0, alpha: 1)
                }
            } else {
                // Fallback on earlier versions
                keyboardColor = UIColor(red: 236/255.0, green: 239/255.0, blue: 241/255.0, alpha: 1)
            }
            
            var popUpKeys: [UIButton] = []
            
            let buttonWidth:CGFloat = 35.0
            let buttonHeight:CGFloat = 45.0
            var extraKeyboard: [String]

            let tapLocation = gesture.location(in: self.view)

            if let key = (gesture.view as! UIButton).titleLabel?.text?.lowercased() {
                
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
                    button.setTitleColor(Constants.buttonTextColour, for: .normal)
                    let key = extraKeyboard[row]
                    let capsKey = key.capitalized
                    let keyToDisplay = shiftButtonState == .normal ? key : capsKey
                    button.layer.setValue(key, forKey: "original")
                    button.layer.setValue(keyToDisplay, forKey: "keyToDisplay")
                    button.layer.setValue(false, forKey: "isSpecial")
                    button.setTitle(keyToDisplay, for: .normal)
                    button.layer.borderColor = keyboardColor?.cgColor
                    button.layer.borderWidth = 4
                    button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
                    button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
                    button.frame.size.width = buttonWidth
                    button.frame.size.height = buttonHeight
//                    button.addTarget(self, action: #selector(keyPressedTouchUp), for: .touchUpInside)
//                    button.addTarget(self, action: #selector(keyTouchDown), for: .touchDown)
//                    button.addTarget(self, action: #selector(keyUntouched), for: .touchDragExit)
//                    button.addTarget(self, action: #selector(keyMultiPress(_:event:)), for: .touchDownRepeat)
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
                
                
                //PopUpView
                popUpView=UIView(frame: CGRect(x: tapLocation.x-10, y: tapLocation.y-65, width: popUpLetters.frame.size.width, height: popUpLetters.frame.size.height))
                
                let maxViewSizeX = view.bounds.width
                let popUpMaxX = tapLocation.x - 10 + popUpView.bounds.maxX
                
                if popUpMaxX > maxViewSizeX {
                    popUpView.frame.origin.x = tapLocation.x - 10 - (popUpMaxX - maxViewSizeX)
                } else if tapLocation.x - 10 < 0 {
                    popUpView.frame.origin.x = 0
                }
                
                if tapLocation.y - 65 < 0 {
                    popUpView.frame.origin.y = 0
                }
                
                popUpView.backgroundColor=keyboardColor
                popUpView.layer.cornerRadius=5
                popUpView.layer.borderWidth=2
                popUpView.clipsToBounds = true
                popUpView.tag=1001
                popUpView.layer.borderColor=UIColor.gray.cgColor
                popUpView.setNeedsLayout()
                popUpView.layoutIfNeeded()
                popUpView.addSubview(popUpLetters)
                popUpView.addPikeOnView(side: .Bottom)
                
                self.view.addSubview(popUpView)
            }
        } else if gesture.state == .changed {
            let xPopUp = gesture.location(in: popUpLetters).x
            let yPopUp = gesture.location(in: popUpLetters).y
            
            let insideX = xPopUp >= 0 && xPopUp < popUpLetters.bounds.width
            let insideY = yPopUp >= 0 && yPopUp < popUpLetters.bounds.height
            
            if insideX && insideY {
                for i in 0..<popUpLetters.subviews.count {
                    let subview = popUpLetters.subviews[i]
                    if subview.isKind(of: UIButton.self) {
                        subview.backgroundColor = Constants.keyNormalColour
                        if i == popUpLetters.subviews.count - 1 {
                            if gesture.location(in: subview).x >= 0 {
                                if gesture.location(in: subview).x >= 0 {
                                    (subview as! UIButton).backgroundColor = Constants.keyButtonPressedColour
                                }
                            } else {
                                if gesture.location(in: popUpLetters.subviews[i-1]).x >= 0 {
                                    (popUpLetters.subviews[i-1] as! UIButton).backgroundColor = Constants.keyButtonPressedColour
                                }
                            }
                        } else {
                            if gesture.location(in: subview).x < 0 {
                                if gesture.location(in: popUpLetters.subviews[i-1]).x >= 0 {
                                    (popUpLetters.subviews[i-1] as! UIButton).backgroundColor = Constants.keyButtonPressedColour
                                }
                            }
                        }
                    }
                }
            } else {
                for i in 0..<popUpLetters.subviews.count {
                    (popUpLetters.subviews[i] as! UIButton).backgroundColor = Constants.keyNormalColour
                }
            }
        } else if gesture.state == .ended || gesture.state == .cancelled {
            //popUpKeys.forEach{$0.removeFromSuperview()}
            let xPopUp = gesture.location(in: popUpLetters).x
            let yPopUp = gesture.location(in: popUpLetters).y
            
            let insideX = xPopUp >= 0 && xPopUp < popUpLetters.bounds.width
            let insideY = yPopUp >= 0 && yPopUp < popUpLetters.bounds.height
            
            if insideX && insideY {
                for i in 0..<popUpLetters.subviews.count {
                    let subview = popUpLetters.subviews[i]
                    if subview.isKind(of: UIButton.self) {
                        if i == popUpLetters.subviews.count - 1 {
                            if gesture.location(in: subview).x >= 0 {
                                keyPressedTouchUp((subview as! UIButton))
                                popUpView.removeFromSuperview()
                                (gesture.view as! UIButton).backgroundColor = Constants.keyNormalColour
                                return
                            } else {
                                if gesture.location(in: popUpLetters.subviews[i-1]).x >= 0 {
                                    keyPressedTouchUp((popUpLetters.subviews[i-1] as! UIButton))
                                    popUpView.removeFromSuperview()
                                    (gesture.view as! UIButton).backgroundColor = Constants.keyNormalColour
                                    return
                                }
                            }
                        } else {
                            if gesture.location(in: subview).x < 0 {
                                if gesture.location(in: popUpLetters.subviews[i-1]).x >= 0 {
                                    keyPressedTouchUp((popUpLetters.subviews[i-1] as! UIButton))
                                    popUpView.removeFromSuperview()
                                    (gesture.view as! UIButton).backgroundColor = Constants.keyNormalColour
                                    return
                                }
                            }
                        }
                    }
                }
            }
            if popUpView != nil {
                popUpView.removeFromSuperview()
            }
            (gesture.view as! UIButton).backgroundColor = Constants.keyNormalColour
		}
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
        let preferredLanguage = "pt_BR"
        
        let completions = textChecker.completions(forPartialWordRange: NSRange(0..<word.utf8.count), in: word, language: preferredLanguage)

        return completions
    }
}
