//
//  SVGExporter.swift
//  
//
//  Created by Dave DeLong on 9/19/19.
//

import Foundation

public class UnicodeExporter: Exporter {
    
    private func format(_ point: CGPoint) -> String {
        return "\(point.x),\(point.y)"
    }
    
    public func exportGlyph(_ glyph: Glyph, in font: Font, to folder: URL) throws {
        // NOTE: this doesn't write to file. Just output to stdout
        getUnicode(glyph: glyph, font: font)
    }
    
    private func getUnicode(glyph:Glyph, font:Font) {
        let name = "\(glyph.fullName)"
        if glyph2unicode == nil {
            self.glyph2unicode = createUnicodeFontMap(ctFont: font.font)
        }
        let unichar = glyph2unicode![glyph.glyph]
        print("\(name) \(String(format:"%8x",unichar!.value))")
    }
    
    private var glyph2unicode:[CGGlyph: UnicodeScalar]? = nil
    
    public func data(for glyph: Glyph, in font: Font) -> Data {
        var lines = Array<String>()
        
        // NOTE: this is inefficient since the table only needs to be computed once
        
        let glyph2unicode = createUnicodeFontMap(ctFont: font.font)
        lines.append("\(glyph2unicode[glyph.glyph])")
        
        let svg = lines.joined(separator: "\n")
        
        return Data(svg.utf8)
    }
    
    // from https://stackoverflow.com/questions/56782339/how-to-get-all-characters-of-the-font-with-ctfontcopycharacterset-in-swift
    
    private func createUnicodeFontMap(ctFont: CTFont) ->  [CGGlyph : UnicodeScalar] {

        let charset = CTFontCopyCharacterSet(ctFont) as CharacterSet

        var glyphToUnicode = [CGGlyph : UnicodeScalar]() // Start with empty map.

        // Enumerate all Unicode scalar values from the character set:
        for plane: UInt8 in 0...16 where charset.hasMember(inPlane: plane) {
            for unicode in UTF32Char(plane) << 16 ..< UTF32Char(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), charset.contains(uniChar) {

                    // Get glyph for this `uniChar` ...
                    let utf16 = Array(uniChar.utf16)
                    var glyphs = [CGGlyph](repeating: 0, count: utf16.count)
                    if CTFontGetGlyphsForCharacters(ctFont, utf16, &glyphs, utf16.count) {
                        // ... and add it to the map.
                        glyphToUnicode[glyphs[0]] = uniChar
                    }
                }
            }
        }

        return glyphToUnicode
    }
}
