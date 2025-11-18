import XCTest
import SwiftTreeSitter
import TreeSitterMonkeyodin

final class TreeSitterMonkeyodinTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_monkeyodin())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Monkeyodin grammar")
    }
}
