//
//  BitmapGlyphLabel.swift
//  
//
//  Created by Gabriel Nica on 09/01/2020.
//

import SpriteKit

public enum BitmapGlyphHorizontalAlignment {
    case left, right, center
}

public enum BitmapGlyphVerticalAlignment {
    case top, middle, bottom
}

public enum BitmapGlyphJustification {
    case left, right, center
}

public class BitmapGlyphLabel: SKNode {
    public var text: String? {
        didSet {
            if text != oldValue {
                updateLabel()
                justifyText()
            }
        }
    }
    
    public var horizontalAlignment: BitmapGlyphHorizontalAlignment = .center {
        didSet {
            if horizontalAlignment != oldValue {
            justifyText()
            }
        }
    }
    public var verticalAlignment: BitmapGlyphVerticalAlignment = .middle {
        didSet {
            if verticalAlignment != oldValue {
            justifyText()
            }
        }
    }
    public var justification: BitmapGlyphJustification = .left {
        didSet {
            if justification != oldValue {
            justifyText()
            }
        }
    }
    
    public var color: SKColor {
        didSet {
            for child in children {
                (child as? SKSpriteNode)?.color = color
            }
        }
    }
    public var colorBlendFactor: CGFloat = 1 {
        didSet {
            for child in children {
                (child as? SKSpriteNode)?.colorBlendFactor = CGFloat(simd_clamp(Double(self.colorBlendFactor), 0.0, 1.0))
            }
        }
    }
    
    public private(set) var totalSize: CGSize = CGSize.zero
    public private(set) var font: BitmapGlyphFont
    
    public init(text: String?, font: BitmapGlyphFont) {
        self.font = font
        self.text = text
        color = .white
        
        super.init()
        
        updateLabel()
        justifyText()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func justifyText() {
        guard let text = text else {
            return
        }
        var shift = CGPoint.zero
        
        switch horizontalAlignment {
        case .left:
            shift.x = 0
        case .right:
            shift.x = -totalSize.width
        case.center:
            shift.x = -totalSize.width / 2
        }
        
        switch verticalAlignment {
        case .bottom:
            shift.y = -totalSize.height
        case .top:
            shift.y = 0
        case .middle:
            shift.y = -totalSize.height / 2
        }
        
        for node in children {
            if let originalPosition = node.userData?["originalPosition"] as? CGPoint {
                node.position = CGPoint(x: originalPosition.x + shift.x, y: originalPosition.y - shift.y)
            }
        }
        
        if justification != .left {
            var numNodes = 0
            var nodePosition = 0
            var widthForLine = CGFloat.zero
            
            let charId: unichar
            
            var node: SKSpriteNode?
            
            for i in 0 ... text.count {
                let char = i != text.count ? text[i] : "\n"
                if char == "\n" {
                    if numNodes > 0 {
                        while nodePosition < numNodes {
                            if let node = children[nodePosition] as? SKSpriteNode {
                                if justification == .right {
                                    node.position = CGPoint(x: node.position.x + totalSize.width - widthForLine + shift.x, y: node.position.y)
                                } else { //center
                                    node.position = CGPoint(x: node.position.x + (totalSize.width - widthForLine) / 2 + shift.x / 2, y: node.position.y)
                                }
                            }
                        }
                    }
                    widthForLine = 0
                } else {
                    if let node = children[numNodes] as? SKSpriteNode {
                        numNodes += 1
                        widthForLine = node.position.x + node.size.width
                    }
                }
            }
        }
    }
    
    func updateLabel() {
        guard let text = text else {
            return
        }
        
        var lastCharId = "0"
        var size = CGSize.zero
        var pos = CGPoint.zero
        let scaleFactor: CGFloat
        
        #if os(macOS)
        scaleFactor = 1
        #else
        scaleFactor = UIScreen.main.nativeScale
        #endif
        
        var letterSprite: SKSpriteNode
        
        let linesCount = text.components(separatedBy: CharacterSet.newlines).count - 1
        
        // remove unused
        if text.count - linesCount < children.count && children.count > 0 {
            var toRemove: [SKNode] = []
            for index in stride(from: children.count, to: text.count - linesCount, by: -1) {
                toRemove.append(children[index - 1])
            }
            
            toRemove.forEach { (node) in
                node.removeFromParent()
            }
        }
        
        if text.count > 0 {
            size.height += font.lineHeight / scaleFactor
        }
        
        var realCharCount = 0
        
        for i in 0 ..< text.count {
            var char = text[i]
            if char == "\n" {
                pos.y -= font.lineHeight / scaleFactor
                size.height += font.lineHeight / scaleFactor
                pos.x = 0
            } else {
                char = String(char.unicodeScalars[char.startIndex].value)
                //re-use existing SKSpriteNode and re-assign the correct texture
                if realCharCount < children.count {
                    letterSprite = children[realCharCount] as! SKSpriteNode
                    letterSprite.texture = font.texture(charId: char)
                    if let texture = letterSprite.texture {
                        letterSprite.size = texture.size()
                    }
                } else {
                    letterSprite = SKSpriteNode(texture: font.texture(charId: char))
                    addChild(letterSprite)
                }
                
                letterSprite.colorBlendFactor = colorBlendFactor
                letterSprite.color = color
                letterSprite.anchorPoint = .zero
                letterSprite.position = CGPoint(x: pos.x + (font.xOffset(charId: char) + font.kerningBetween(lastCharId, and: char)) / scaleFactor, y: pos.y - (letterSprite.size.height + (font.yOffset(charId: char))/scaleFactor))
                
                letterSprite.userData = ["originalPosition": letterSprite.position]
                
                pos.x += font.xAdvance(charId: char) + font.kerningBetween(lastCharId, and: char)
                
                size.width = size.width < pos.x ? pos.x : size.width
                
                realCharCount += 1
            }
            
            lastCharId = char
        }
        
        totalSize = size
    }
}

extension String {
    
    var length: Int {
        return count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
}
