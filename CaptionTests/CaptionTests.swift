//
//  CaptionTests.swift
//  CaptionTests
//
//  Created by Qian on 2021/1/10.
//

import XCTest
@testable import Caption

class CaptionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testChunked() {
        XCTAssertTrue( ["a","b","c","d","e","f","g","h"].chunked(by: [ 1, 4, 5 ])
                        == [["a","b"],["c","d","e"],["f"],["g","h"]] )
        XCTAssertTrue( ["1","2","3","4","5","6","7","8"].chunked(by: [ 1, 4, 5 ])
                        == [["1","2"],["3","4","5"],["6"],["7","8"]] )
        XCTAssertTrue( ["a","b","c","d","e","f","g","h"].chunked(by: [ 1 ])
                        == [["a","b"],["c","d","e","f","g","h"]] )
        
        XCTAssertTrue( ["a","b","c","d","e","f","g","h"].chunked(by: [ -1, 4, 5 ])
                        == [["a","b","c","d","e"],["f"],["g","h"]] )
        XCTAssertTrue( ["a","b","c","d","e","f","g","h"].chunked(by: [ 5, -1, 4 ])
                        == [["a","b","c","d","e"],["f"],["g","h"]] )
        
        let array = [String]()
        let special = array.chunked(by: [ 1 ])
        XCTAssertTrue( special.isEmpty )
//        XCTAssertTrue( special is [[String]] )
        
        XCTAssertTrue( ["a"].chunked(by: [ 1, 4, 5 ]) == [["a"]] )
        XCTAssertTrue( ["a","b","c"].chunked(by: [ 1, 4, 5 ]) == [["a","b"],["c"]] )
        
        XCTAssertTrue( ["a","b","c","d","e","f","g","h"].chunked(by: [])
                        == [["a","b","c","d","e","f","g","h"]] )
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
