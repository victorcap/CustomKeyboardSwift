//
//  Constants.swift
//
//  Created by Marcus Titton on 03/05/2020.
//  Copyright © 2020 Marcus Titton. All rights reserved.
//

import Foundation
import UIKit

enum Constants{
	
    static let keyNormalColour: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return UIColor(red: 67/255.0, green: 67/255.0, blue: 67/255.0, alpha: 1)
                } else {
                    /// Return the color for Light Mode
                    return UIColor(red: 252/255.0, green: 252/255.0, blue: 254/255.0, alpha: 1)
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return UIColor(red: 252/255.0, green: 252/255.0, blue: 254/255.0, alpha: 1)
        }
    }()
        
    static let keyPressedColour: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return UIColor.darkText
                } else {
                    /// Return the color for Light Mode
                    return UIColor.lightText
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return UIColor.lightText
        }
    }()
    
    static let buttonSuggestionTextColour: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return UIColor.white
                } else {
                    /// Return the color for Light Mode
                    return UIColor.darkGray
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return UIColor.darkGray
        }
    }()
    
    static let buttonTextColour: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return UIColor.white
                } else {
                    /// Return the color for Light Mode
                    return UIColor.black
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return UIColor.black
        }
    }()
    
	static let specialKeyNormalColour: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return UIColor(red: 36/255.0, green: 36/255.0, blue: 36/255.0, alpha: 1)
                } else {
                    /// Return the color for Light Mode
                    return UIColor(red: 173/255.0, green: 179/255.0, blue: 188/255.0, alpha: 1)
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return UIColor(red: 173/255.0, green: 179/255.0, blue: 188/255.0, alpha: 1)
        }
    }()
    
    static let keyboardViewColour: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return UIColor(red: 29/255.0, green: 29/255.0, blue: 29/255.0, alpha: 1)
                } else {
                    /// Return the color for Light Mode
                    return UIColor(red: 236/255.0, green: 239/255.0, blue: 241/255.0, alpha: 1)
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return UIColor(red: 236/255.0, green: 239/255.0, blue: 241/255.0, alpha: 1)
        }
    }()
    
    static let titleButtonColour: UIColor = {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return UIColor.white
                } else {
                    /// Return the color for Light Mode
                    return UIColor.black
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return UIColor.black
        }
    }()

	static var letterKeys = [
		["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], 
		["a", "s", "d", "f", "g","h", "j", "k", "l"],
		["⬆️", "z", "x", "c", "v", "b", "n", "m", "⌫"],
		["123", "🌐", "espaço", "Bradesco", "Retorno"]
	]
	static let numberKeys = [
		["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
		["-", "/", ":", ";", "(", ")" ,"$", "&", "@", "\""],
		["#+=",".", ",", "?", "!", "\'", "⌫"],
		["ABC", "🌐", "espaço", "Bradesco", "Retorno"]
	]
	
	static let symbolKeys = [
		["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
		["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "·"],
		["123",".", ",", "?", "!", "\'", "⌫"],
		["ABC", "🌐", "espaço", "Bradesco", "Retorno"]
	]
    
    static let extrasLettersE = ["e", "è", "é", "ê", "ë", "ē", "ė", "ę"]
    
    static let extrasLettersY = ["y", "ÿ"]
    
    static let extrasLettersU = ["u", "ū", "ú", "ù", "ü", "û"]
    
    static let extrasLettersI = ["i", "ì", "į", "ī", "í", "ï", "î"]
    
    static let extrasLettersO = ["o", "õ", "ō", "ø", "œ", "ó", "ò", "ö", "ô", "º"]
    
    static let extrasLettersA = ["a", "à", "á", "â", "ä", "æ", "ã", "å", "ª"]
    
    static let extrasLettersS = ["s", "ß", "š"]
    
    static let extrasLettersZ = ["z", "ž", "ź"]
    
    static let extrasLettersC = ["c", "ç", "ć", "č"]
    
    static let extrasLettersN = ["n", "ñ", "ń"]
    
    //Gradiente linha de separação do suggestion words
    //CLASSIC
    static let gradientFirstColorClassic = UIColor(red: 245/255.0, green: 96/255.0, blue: 119/255.0, alpha: 1)
    static let gradientSecondColorClassic = UIColor(red: 226/255.0, green: 48/255.0, blue: 80/255.0, alpha: 1)
    static let gradienteThirdColorClassic = UIColor(red: 206/255.0, green: 0/255.0, blue: 41/255.0, alpha: 1)
    static let gradienteFourthColorClassic = UIColor(red: 194/255.0, green: 7/255.0, blue: 87/255.0, alpha: 1)
    static let gradienteFifthColorClassic = UIColor(red: 182/255.0, green: 14/255.0, blue: 132/255.0, alpha: 1)
    
    
    //Gradiente botão RETORNO
    //CLASSIC
    static let gradientFirstColorReturnClassic = UIColor(red: 238/255.0, green: 78/255.0, blue: 105/255.0, alpha: 1)
    static let gradientSecondColorReturnClassic = UIColor(red: 209/255.0, green: 6/255.0, blue: 46/255.0, alpha: 1)
    static let gradientThirdColorReturnClassic = UIColor(red: 184/255.0, green: 14/255.0, blue: 128/255.0, alpha: 1)
}
