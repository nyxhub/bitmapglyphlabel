import SpriteKit

public class BitmapGlyphFont: NSObject, XMLParserDelegate {
    private(set) var lineHeight = CGFloat.zero
    private(set) var kernings: [String: CGFloat] = [:]
    private(set) var chars: [String: CGFloat] = [:]
    private(set) var textures: [String: SKTexture] = [:]
    private(set) var atlas: SKTextureAtlas
    
    private var parser: XMLParser?
    
    public init?(named name: String) {
        atlas = SKTextureAtlas(named: name)
        
        let fontFile = String(format: "%@%@", name, BitmapGlyphFont.suffixForDevice())
        guard let url = Bundle.main.url(forResource: fontFile, withExtension: "xml") else {
            return nil
        }
        
        super.init()
        
        let parser = XMLParser(contentsOf: url)
        parser?.delegate = self
        parser?.parse()
    }
    
    public init?(named name: String, usingAtlas atlas: SKTextureAtlas) {
        self.atlas = atlas
        
        let fontFile = "\(name)\(BitmapGlyphFont.suffixForDevice())"
        guard let url = Bundle.main.url(forResource: fontFile, withExtension: "xml") else {
            return nil
        }
        
        super.init()
        let parser = XMLParser(contentsOf: url)
        parser?.delegate = self
        parser?.parse()
    }
    
    @inlinable class func suffixForDevice() -> String {
        #if !os(macOS)
        switch UIScreen.main.nativeScale {
        case 2.0: return "@2x"
        case 2 ..< 3: return "@3x"
        default: return ""
        }
        #else
        return ""
        #endif
    }
    
    func xAdvance(charId: String) -> CGFloat {
        return chars["xadvance_\(charId)"] ?? 0
    }
    
    func xOffset(charId: String) -> CGFloat {
        return chars["xoffset_\(charId)"] ?? 0
    }
    
    func yOffset(charId: String) -> CGFloat {
        return chars["yoffset_\(charId)"] ?? 0
    }
    
    func kerningBetween(_ first: String, and second: String) -> CGFloat {
        return kernings["\(first)/\(second)"] ?? 0
    }
    
    func texture(charId: String) -> SKTexture {
        return atlas.textureNamed(charId)
    }
    
    public func parser(_ parser: XMLParser,
                       didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                       attributes attributeDict: [String : String] = [:])
    {
        switch elementName {
        case "kerning":
            let first = Int(optionalString: attributeDict["first"])
            let second = Int(optionalString: attributeDict["second"])
            let amount = CGFloat(optionalString: attributeDict["amount"])
            
            kernings["\(first)/\(second)"] = amount
        case "char":
            let charId = attributeDict["id"] ?? "0"
            let xAdvance = CGFloat(optionalString: attributeDict["xadvance"])
            let xOffset = CGFloat(optionalString: attributeDict["xoffset"])
            let yOffset = CGFloat(optionalString: attributeDict["yoffset"])
            
            chars["xoffset_\(charId)"] = xOffset
            chars["yoffset_\(charId)"] = yOffset
            chars["xadvance_\(charId)"] = xAdvance
            textures[charId] = texture(charId: charId)
        case "common":
            lineHeight = CGFloat(Int(optionalString: attributeDict["lineHeight"]))
        default: break
        }
    }
}

extension Int {
    init(optionalString: String?) {
        guard let string = optionalString else {
            self = 0
            return
        }
        self = Int(string) ?? 0
    }
}

extension CGFloat {
    init(optionalString: String?) {
        guard let string = optionalString, let floatValue = NumberFormatter().number(from: string)?.floatValue else {
            self = 0
            return
        }
        
        self = CGFloat(floatValue)
    }
}
