//
//  BinanceApiObjCTests.m
//  BinanceApiTests
//
//  Created by Sumant Manne on 10/27/17.
//  Copyright © 2017 Sumant Manne. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BinanceApi/BinanceApi-Swift.h>

@interface BinanceApiObjCTests : XCTestCase

@property (nonatomic) NSString *apiKey;
@property (nonatomic) NSString *secretKey;
@property (nonatomic) NSString *querySymbol;
@property (nonatomic) UInt64 queryOrderId;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) int32_t limit;

@end

@implementation BinanceApiObjCTests

- (void)setUp {
    [super setUp];
    [self setContinueAfterFailure:false];

    // Put configuration information here for testing
    [self setApiKey:@"<api key>"];
    [self setSecretKey:@"<secret key>"];
    [self setQuerySymbol:@"ETHBTC"];
    [self setQueryOrderId:0];
    [self setTimeout:20];
    [self setLimit:5];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPing {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"ping"];

    BinanceApi *api = [[BinanceApi alloc] init];
    [api pingWithResponseHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testTime {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"time"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:nil secretKey:nil];
    [api timeWithResponseHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);

        XCTAssert([[result valueForKey:@"serverTime"] isKindOfClass:[NSDate class]]);

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testDepth {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"depth"];

    NSString *symbol = @"ETHBTC";

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:nil secretKey:nil];
    [api depthWithSymbol:symbol limit:0 responseHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);

        XCTAssert([[result valueForKey:@"lastUpdateId"] isKindOfClass:[NSNumber class]]);
        XCTAssert([[result valueForKey:@"bids"] isKindOfClass:[NSArray class]]);
        XCTAssert([[result valueForKey:@"asks"] isKindOfClass:[NSArray class]]);

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testAggregateTrades {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"aggregate trades"];

    NSString *symbol = @"ETHBTC";

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:nil secretKey:nil];
    [api aggregateTradesWithSymbol:symbol fromId:0 startTime:nil endTime:nil limit:0 responseHandler:^(NSArray<NSDictionary<NSString *, id> *> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);

        XCTAssert([result isKindOfClass:[NSArray class]]);

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testCandlestickTrades {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"candlestick trades"];

    NSString *symbol = @"ETHBTC";

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:nil secretKey:nil];
    [api candlesticksWithSymbol:symbol interval:BinanceCandlestickInterval.Min5 limit:self.limit startTime:nil endTime:nil responseHandler:^(NSArray<NSDictionary<NSString *, id> *> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);

        XCTAssert([result isKindOfClass:[NSArray class]]);
        for (id element in result) {
            XCTAssert([element isKindOfClass:[NSDictionary class]]);
        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testAllPrices {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"all prices"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:nil secretKey:nil];
    [api allPricesWithResponseHandler:^(NSDictionary<NSString *,NSDecimalNumber *> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);

        XCTAssert([result isKindOfClass:[NSDictionary class]]);
        XCTAssertGreaterThan(result.count, 0);

        for (NSString *symbol in result) {
            XCTAssert(![symbol isEqualToString:@""]);
        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testAllBookTickers {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"all book tickers"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:nil secretKey:nil];
    [api allBookTickersWithResponseHandler:^(NSDictionary<NSString *, id> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(result);

        XCTAssert([result isKindOfClass:[NSDictionary class]]);
        XCTAssert(result.count > 10);

        for (NSString *asset in result) {
            NSDictionary *dict = [result valueForKey:asset];
            XCTAssert([dict isKindOfClass:[NSDictionary class]]);
            NSDecimalNumber *bidPrice = [dict valueForKey:@"bidPrice"];
            NSDecimalNumber *bidQuantity = [dict valueForKey:@"bidQuantity"];
            NSDecimalNumber *askPrice = [dict valueForKey:@"askPrice"];
            NSDecimalNumber *askQuantity = [dict valueForKey:@"askQuantity"];
            NSLog(@"%@: %@ @ %@ - %@ @ %@", asset, bidPrice, bidQuantity, askPrice, askQuantity);
        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testTestNewOrder {
    NSString *symbol = @"ETHBTC";
    NSDecimalNumber *quantity = [NSDecimalNumber decimalNumberWithString:@"1.0"];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"all book tickers"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:self.apiKey secretKey:self.secretKey];
    [api testNewOrderWithSymbol:symbol side:BinanceOrderSide.Buy type:BinanceOrderType.Market timeInForce:nil quantity:quantity price:nil newClientOrderId:nil stopPrice:nil icebergQuantity:nil responseHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testQueryOrder {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"query order"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:self.apiKey secretKey:self.secretKey];
    [api queryOrderWithSymbol:self.querySymbol orderId:self.queryOrderId originalClientOrderId:nil responseHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssert(result);

        XCTAssert([(NSString *)[result valueForKey:@"symbol"] isEqualToString:self.querySymbol]);
        XCTAssertEqual([(NSNumber *)[result valueForKey:@"orderId"] unsignedLongLongValue], self.queryOrderId);

        NSLog(@"%@: %@", [result valueForKey:@"symbol"], [result valueForKey:@"status"]);

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}


- (void)testCancelOrder {
    NSString *symbol = @"BNBETH";
    UInt64 orderId = 10000;

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"cancel order"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:self.apiKey secretKey:self.secretKey];
    [api cancelOrderWithSymbol:symbol orderId:orderId originalClientOrderId:nil newClientOrderId:nil responseHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssert(result);

        UInt64 orderId = [[result valueForKey:@"orderId"] unsignedLongLongValue];
        NSLog(@"Cancelled order %llu", orderId);

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}


- (void)testOpenOrders {
    NSString *symbol = @"BNBETH";

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"open orders"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:self.apiKey secretKey:self.secretKey];
    [api openOrdersWithSymbol:symbol responseHandler:^(NSArray<NSDictionary<NSString *, id> *> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssert(result);

        XCTAssert([result isKindOfClass:[NSArray class]]);
        for (id object in result) {
            XCTAssert([object isKindOfClass:[NSDictionary class]]);
            NSDictionary *dict = object;
            XCTAssert([[dict valueForKey:@"symbol"] isEqualToString:symbol]);
            XCTAssert([[dict valueForKey:@"orderId"] isKindOfClass:[NSNumber class]]);
        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testAllOrders {
    NSString *symbol = @"BNBETH";

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"all orders"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:self.apiKey secretKey:self.secretKey];
    [api allOrdersWithSymbol:symbol orderId:0 limit:self.limit responseHandler:^(NSArray<NSDictionary<NSString *, id> *> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssert(result);

        XCTAssert([result isKindOfClass:[NSArray class]]);
        for (id object in result) {
            XCTAssert([object isKindOfClass:[NSDictionary class]]);
            NSDictionary *dict = object;
            XCTAssert([[dict valueForKey:@"symbol"] isEqualToString:symbol]);
            XCTAssert([[dict valueForKey:@"orderId"] isKindOfClass:[NSNumber class]]);
        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testAccountInformation {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"account information"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:self.apiKey secretKey:self.secretKey];
    [api accountInformationWithResponseHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssert(result);

        NSDictionary<NSString *, id> *balances = [result valueForKey:@"balances"];
        if (balances.count > 0) {
            NSLog(@"Balances");

            for (NSString *key in balances) {
                NSDictionary<NSString *, NSDecimalNumber *> *balance = [balances valueForKey:key];
                NSLog(@"%@ %@", [balance valueForKey:@"total"], key);
            }
        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

- (void)testAccountTradeList {
    NSString *symbol = @"BNBETH";

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"account trade list"];

    BinanceApi *api = [[BinanceApi alloc] initWithApiKey:self.apiKey secretKey:self.secretKey];
    [api accountTradeListWithSymbol:symbol limit:self.limit fromId:0 responseHandler:^(NSArray<NSDictionary<NSString *, id> *> * _Nullable result, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssert(result);

        XCTAssert([result isKindOfClass:[NSArray class]]);
        for (NSDictionary<NSString *, id> *object in result) {
            XCTAssert([object isKindOfClass:[NSDictionary class]]);
            NSNumber *orderId = [object valueForKey:@"id"];
            XCTAssertGreaterThan([orderId unsignedLongLongValue], 0);
        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:self.timeout];
}

@end

