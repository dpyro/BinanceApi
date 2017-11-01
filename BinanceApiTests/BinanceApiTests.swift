//
//  BinanceApiTests.swift
//  BinanceApiTests
//
//  Created by Sumant Manne on 10/20/17.
//  Copyright © 2017 Sumant Manne. All rights reserved.
//

import XCTest
@testable import BinanceApi

class BinanceApiTests: XCTestCase {
    let timeout: TimeInterval = 20.0
    let apiKey = "<api key>"
    let secretKey = "<secret key>"
    let querySymbol = "BNBETH"
    let queryOrderId = UInt64(0)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func asyncTest(_ description: String, testHandler: (XCTestExpectation) -> Void) -> Void {
        let expectation = self.expectation(description: description)

        testHandler(expectation)

        self.wait(for: [expectation], timeout: self.timeout)
    }
    
    func testSignature() {
        // let apiKey = "vmPUZE6mv9SD5VNHk4HlWFsOr6aKE2zvsw0MuIgwCIPy6utIco14y7Ju91duEh8A"
        let secretKey = "NhqPtmdSJYdKjVHjA7PZj4Mge3R5YNiP1e3UZjInClVN65XAbvqqM6A7H5fATj0j"
        let message = "symbol=LTCBTC&side=BUY&type=LIMIT&timeInForce=GTC&quantity=1&price=0.1&recvWindow=5000&timestamp=1499827319559"
        
        let result = message.hmac(base64key: secretKey)
        
        XCTAssertEqual(result, "c8db56825ae71d6d79447849e617115f4a920fa2acdcab2b053c4b2838bd6b71")
    }

    func testPing() {
        let api = BinanceApi()
        let request = BinancePingRequest()

        asyncTest("ping") { expectation in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                expectation.fulfill()
            }
        }
    }

    func testTime() {
        let api = BinanceApi()
        let request = BinanceTimeRequest()

        asyncTest("time") { expectation in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let value = response.result.value!
                let interval = value.serverTime.timeIntervalSinceNow
                XCTAssertLessThan(abs(interval), 5)
                expectation.fulfill()
            }
        }
    }

    func testDepth() {
        let api = BinanceApi()
        let symbol = "ETHBTC"
        let request = BinanceDepthRequest(symbol: symbol)

        asyncTest("depth") { expectation in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let value = response.result.value!
                XCTAssertGreaterThan(value.asks.count, 0)
                XCTAssertGreaterThan(value.bids.count, 0)
                expectation.fulfill()
            }
        }
    }

    func testAggregateTrades() {
        let api = BinanceApi()
        let symbol = "ETHBTC"
        let request = BinanceAggregateTradesRequest(symbol: symbol)

        asyncTest("aggregate trades") { expectation in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let elements = response.result.value!
                elements.forEach({ (element) in
                    XCTAssertGreaterThan(element.aggregateTradeId, 0)
                    XCTAssertGreaterThan(element.price, 0)
                    XCTAssertGreaterThan(element.quantity, 0)
                    XCTAssertGreaterThan(element.firstTradeId, 0)
                    XCTAssertGreaterThan(element.lastTradeId, 0)
                    XCTAssertGreaterThan(element.timestamp, Date.distantPast)
                    XCTAssertLessThan(element.timestamp, Date.distantFuture)
                })
                expectation.fulfill()
            }
        }
    }

    func testCandlesticks() {
        let api = BinanceApi()
        let symbol = "ETHBTC"
        let interval = BinanceCandlesticksInterval.min5
        let request = BinanceCandlesticksRequest(symbol: symbol, interval: interval, limit: 50)

        asyncTest("klines/candlesticks") { expectation in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let elements = response.result.value!
                XCTAssertGreaterThan(elements.count, 0)
                elements.forEach({ element in
                    XCTAssertGreaterThanOrEqual(element.closeTime, element.openTime)
                    XCTAssertGreaterThanOrEqual(element.high, element.low)
                    XCTAssertGreaterThanOrEqual(element.high, element.open)
                    XCTAssertGreaterThanOrEqual(element.high, element.close)
                    XCTAssertLessThanOrEqual(element.low, element.open)
                    XCTAssertLessThanOrEqual(element.low, element.close)
                })
                expectation.fulfill()
            }
        }
    }

    func test24HourTicker() {
        let api = BinanceApi()
        let symbol = "ETHBTC"
        let request = Binance24HourTickerRequest(symbol: symbol)

        asyncTest("24hr ticker") { expectation in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let value = response.result.value!
                XCTAssertGreaterThanOrEqual(value.highPrice, value.lowPrice)
                XCTAssertGreaterThanOrEqual(value.closeTime, value.openTime)
                expectation.fulfill()
            }
        }
    }

    func testAllPrices() {
        let api = BinanceApi()
        let request = BinanceAllPricesRequest()

        asyncTest("all prices") { expectation in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let elements = response.result.value!.elements
                XCTAssertGreaterThan(elements.keys.count, 0)
                expectation.fulfill()
            }
        }
    }

    func testAllBookTickers() {
        let api = BinanceApi()
        let request = BinanceAllBookTickersRequest()

        asyncTest("book tickers") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let elements = response.result.value!.elements

                XCTAssertGreaterThan(elements.count, 0)

                for (asset, prices) in elements {
                    let bidPrice = prices.bidPrice
                    let bidQuantity = prices.bidQuantity
                    let askPrice = prices.askPrice
                    let askQuantity = prices.askQuantity
                    print("\(asset): \(bidPrice) @ \(bidQuantity) - \(askPrice) @ \(askQuantity)")
                }

                expectation.fulfill()
            }
        }
    }

    /*func testNewOrder() {
        let api = BinanceApi(apiKey: self.apiKey, secretKey: self.secretKey)
        let symbol = "ETHBTC"
        let request = BinanceNewOrderRequest(
            symbol: symbol,
            side: .sell,
            type: .limit,
            quantity: Decimal(string: "0.001")!,
            price: Decimal(string: "1.1")!, timeInForce: .goodTilCancelled)

        asyncTest("new order") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let value = response.result.value!
                XCTAssertEqual(value.symbol, symbol)
                print("Created new order #\(value.orderId)")
                expectation.fulfill()
            }
        }
    }*/
    
    func testTestNewOrder() {
        let api = BinanceApi(apiKey: self.apiKey, secretKey: self.secretKey)
        let symbol = "ETHBTC"
        let request = BinanceTestNewOrderRequest(
            symbol: symbol,
            side: .buy,
            type: .market,
            quantity: Decimal(string: "1.1")!)

        asyncTest("test new order") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let _ = response.result.value!
                expectation.fulfill()
            }
        }
    }

    func testQueryOrder() {
        let api = BinanceApi(apiKey: self.apiKey, secretKey: self.secretKey)
        let request = BinanceQueryOrderRequest(symbol: self.querySymbol, orderId: self.queryOrderId)

        asyncTest("query order") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let order = response.result.value!
                print(order)
                expectation.fulfill()
            }
        }
    }

    /*func testCancelOrder() {
        let api = BinanceApi(apiKey: self.apiKey, secretKey: self.secretKey)
        let symbol = "ETHBTC"
        let orderId = UInt64(11691907)
        let request = BinanceCancelOrderRequest(symbol: symbol, orderId: orderId)

        asyncTest("cancel order") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let value = response.result.value!
                XCTAssertEqual(value.symbol, symbol)
                XCTAssertEqual(value.orderId, orderId)
                print("Cancelled order #\(value.orderId)")
                expectation.fulfill()
            }
        }
    }*/

    func testOpenOrders() {
        let api = BinanceApi(apiKey: self.apiKey, secretKey: self.secretKey)
        let symbol = "BNBETH"
        let request = BinanceOpenOrdersRequest(symbol: symbol)

        asyncTest("open orders") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let elements = response.result.value!
                print("Got \(elements.count) open orders.")
                expectation.fulfill()
            }
        }
    }

    func testAllOrders() {
        let api = BinanceApi(apiKey: self.apiKey, secretKey: self.secretKey)
        let symbol = "BNBETH"
        let request = BinanceAllOrdersRequest(symbol: symbol, limit: 20)

        asyncTest("all orders") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let elements = response.result.value!
                print("=== All orders ===")
                print("Got \(elements.count) orders.")
                for element in elements {
                    print(element)
                }
                expectation.fulfill()
            }
        }
    }

    func testAccountInformation() {
        let api = BinanceApi(apiKey: self.apiKey, secretKey: self.secretKey)
        let request = BinanceAccountInformationRequest()

        asyncTest("account information") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let account = response.result.value!
                print("=== Account information ===")
                print("Maker: \(account.makerCommission)")
                print("Taker: \(account.takerCommission)")
                print("Buyer: \(account.buyerCommission)")
                print("Seller: \(account.sellerCommission)")
                print("Can trade: \(account.canTrade)")
                print("Can deposit: \(account.canDeposit)")
                let balances = account.balances
                if !balances.isEmpty {
                    for (asset, balance) in balances {
                        print("\(asset): \(balance.total)")
                    }
                }
                expectation.fulfill()
            }
        }
    }

    func testAccountTradeList() {
        let api = BinanceApi(apiKey: self.apiKey, secretKey: self.secretKey)
        let symbol = "BNBETH"
        let request = BinanceAccountTradeListRequest(symbol: symbol)

        asyncTest("account trade list") { (expectation) in
            api.send(request) { response in
                XCTAssertTrue(response.result.isSuccess)
                XCTAssertNotNil(response.result.value)
                let elements = response.result.value!
                let now = Date()
                for element in elements {
                    XCTAssertLessThanOrEqual(element.time, now)
                }
                expectation.fulfill()
            }
        }
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
