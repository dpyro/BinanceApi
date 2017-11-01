//
//  BinanceApi.swift
//  BinanceApi
//
//  Created by Sumant Manne on 10/28/17.
//  Copyright © 2017 Sumant Manne. All rights reserved.
//

import Foundation

private func isBridged(_ subject: Any) -> Bool {
    let mirror = Mirror(reflecting: subject)
    if let style = mirror.displayStyle {
        switch style {
        case .enum:
            return false
        case .struct:
            return subject is Data || subject is Date || subject is Decimal
        case .tuple:
            return false
        default:
            break
        }
    }
    return true
}

/// Recursively convert any unbridgeable Swift types using reflection.
private func getReflected(_ subject: Any) -> Any {
    if let array = subject as? Array<Any> {
        return array.map { e in getReflected(e) }
    } else if let dict = subject as? Dictionary<AnyHashable, Any> {
        return dict.mapValues { v in getReflected(v) }
    } else if let set = subject as? Set<AnyHashable> {
        return set.map { e in getReflected(e) }
    } else if isBridged(subject) {
        return subject
    } else {
        // TODO: check for typo canceled enum value
        let mirror = Mirror(reflecting: subject)
        if let style = mirror.displayStyle, style == .enum {
            return String(describing: subject).uppercased()
        } else {
            var result = [String: Any]()
            for property in mirror.children {
                if let label = property.label {
                    let value = getReflected(property.value)
                    result[label] = value
                }
            }
            return result
        }
    }
}

@objc(BinanceOrderStatus) public class _ObjCBinanceOrderStatus: NSObject {}
@objc public extension _ObjCBinanceOrderStatus {
    static let New = "NEW"
    static let Partial = "PARTIALLY_FILLED"
    static let Filled = "FILLED"
    static let Cancelled = "CANCELED" // Yes, this is correct.
    static let PendingCancel = "PENDING_CANCEL"
    static let Rejected = "REJECTED"
    static let Expired = "EXPIRED"
}

@objc(BinanceOrderType) public class _ObjCBinanceOrderType: NSObject {}
@objc public extension _ObjCBinanceOrderType {
    static let Limit = "LIMIT"
    static let Market = "MARKET"
}

@objc(BinanceOrderSide) public class _ObjCBinanceOrderSide: NSObject {}
@objc public extension _ObjCBinanceOrderSide {
    static let Buy = "BUY"
    static let Sell = "SELL"
}

@objc(BinanceOrderTime) public class _ObjCBinanceOrderTime: NSObject {}
@objc public extension _ObjCBinanceOrderTime {
    static let GoodTilCancelled = "GTC"
    static let ImmediateOrCancel = "IOC"
}

@objc(BinanceCandlestickInterval) public class _ObjCBinanceCandlestickInterval: NSObject {}
@objc public extension _ObjCBinanceCandlestickInterval {
    static let Min1 = "1m"
    static let Min3 = "3m"
    static let Min5 = "5m"
    static let Min15 = "15m"
    static let Min30 = "30m"
    static let Hour1 = "1h"
    static let Hour2 = "2h"
    static let Hour4 = "4h"
    static let Hour6 = "6h"
    static let Hour8 = "8h"
    static let Hour12 = "12h"
    static let Day1 = "1d"
    static let Day3 = "3d"
    static let Week1 = "1w"
    static let Month1 = "1M"
}

/// Objective-C interface to Swift-only API
@objc(BinanceApi)
public class _ObjCBinanceApi: NSObject {
    let binanceApi: BinanceApi
    var receiveWindow: TimeInterval = 5000

    @objc public convenience override init() {
        self.init(apiKey: nil, secretKey: nil)
    }

    @objc public init(apiKey: String?, secretKey: String?) {
        self.binanceApi = BinanceApi(apiKey: apiKey, secretKey: secretKey)
        super.init()
    }

    // NOTE: Optional closure parameters are [automatically escaped](https://stackoverflow.com/a/39846519/1440740).

    public typealias ErrorResponseHandler = (_ error: Error?) -> Void

    internal func send<T: BinanceRequest>(_ request: T, errorResponseHandler handler: ErrorResponseHandler?) -> Void {
        self.binanceApi.send(request) { response in
            guard let handler = handler else { return }

            if let error = response.error {
                handler(error)
            } else if let error = response.result.error {
                handler(error)
            } else {
                handler(nil)
            }
        }
    }

    public typealias ResponseHandler<U> = (_ result: U? , _ error: Error?) -> Void

    internal func send<T: BinanceRequest, U>(_ request: T, responseHandler handler: ResponseHandler<U>? = nil) -> Void {
        self.binanceApi.send(request) { response in
            guard let handler = handler else { return }

            if let error = response.error {
                handler(nil, error)
            } else if let error = response.result.error {
                handler(nil, error)
            } else {
                let value = response.result.value!
                let reflected = getReflected(value)
                let typed = reflected as! U
                handler(typed, nil)
            }
        }
    }

    internal func send<T: BinanceRequest, U>(_ request: T, elementsResponseHandler handler: ResponseHandler<U>? = nil) -> Void {
        self.send(request, responseHandler: { (result: [String: Any]?, error) in
            guard let handler = handler else { return }

            if (error != nil) {
                handler(nil, error)
            } else {
                let elements = result!["elements"]!
                handler((elements as! U), nil)
            }
        })
    }
}

@objc public extension _ObjCBinanceApi {
    func ping(responseHandler handler: ErrorResponseHandler?) -> Void {
        let request = BinancePingRequest()
        self.send(request, errorResponseHandler: handler)
    }

    func time(responseHandler handler: ResponseHandler<[String: Date]>?) -> Void {
        let request = BinanceTimeRequest()
        self.send(request, responseHandler: handler)
    }

    func depth(symbol: String, limit: Int32 = 0,
               responseHandler handler: ResponseHandler<[String: Any]>?) -> Void {
        let request = BinanceDepthRequest(symbol: symbol, limit: limit)
        self.send(request, responseHandler: handler)
    }

    func aggregateTrades(symbol: String, fromId: UInt64 = 0, startTime: Date?, endTime: Date?, limit: Int32 = 0,
                         responseHandler handler: ResponseHandler<[[String: Any]]>?) -> Void {
        let request = BinanceAggregateTradesRequest(symbol: symbol, fromId: fromId, startTime: startTime, endTime: endTime, limit: limit)
        self.send(request, responseHandler: handler)
    }

    func candlesticks(symbol: String, interval: String, limit: Int32 = 0, startTime: Date? = nil, endTime: Date? = nil,
                      responseHandler handler: ResponseHandler<[[String: Any]]>?) -> Void {
        let enumInterval = BinanceCandlesticksInterval(rawValue: interval)! // TODO: proper throw or warn on invalid interval
        let request = BinanceCandlesticksRequest(symbol: symbol, interval: enumInterval, limit: limit)
        self.send(request, responseHandler: handler)
    }

    func ticker24Hour(symbol: String,
                      responseHandler handler: ResponseHandler<[String: Any]>?) -> Void {
        let request = Binance24HourTickerRequest(symbol: symbol)
        self.send(request, responseHandler: handler)
    }

    func allPrices(responseHandler handler: ResponseHandler<[String: Decimal]>?) -> Void {
        let request = BinanceAllPricesRequest()
        self.send(request, elementsResponseHandler: handler)
    }

    func allBookTickers(responseHandler handler: ResponseHandler<[String: [String: Decimal]]>?) -> Void {
        let request = BinanceAllBookTickersRequest()
        self.send(request, elementsResponseHandler: handler)
    }

    func newOrder(symbol: String, side: String, type: String, timeInForce: String? = nil, quantity: NSDecimalNumber, price: NSDecimalNumber? = nil,
                  newClientOrderId: String? = nil, stopPrice: NSDecimalNumber? = nil, icebergQuantity: NSDecimalNumber? = nil,
                  responseHandler handler: ResponseHandler<[String: Any]>?) -> Void {
        let enumSide = BinanceOrderSide(rawValue: side.uppercased())!
        let enumType = BinanceOrderType(rawValue: type.uppercased())!
        let enumTimeInForce = timeInForce != nil ? BinanceOrderTime(rawValue: timeInForce!)! : nil

        let request = BinanceNewOrderRequest(
            symbol: symbol, side: enumSide, type: enumType, quantity: quantity as Decimal,
            price: price as Decimal?, timeInForce: enumTimeInForce,
            newClientOrderId: newClientOrderId,
            stopPrice: stopPrice as Decimal?, icebergQuantity: icebergQuantity as Decimal?)
        self.send(request, responseHandler: handler)
    }

    func testNewOrder(symbol: String, side: String, type: String, timeInForce: String? = nil, quantity: NSDecimalNumber, price: NSDecimalNumber? = nil,
                  newClientOrderId: String? = nil, stopPrice: NSDecimalNumber? = nil, icebergQuantity: NSDecimalNumber? = nil,
                  responseHandler handler: ErrorResponseHandler?) -> Void {
        let enumSide = BinanceOrderSide(rawValue: side.uppercased())!
        let enumType = BinanceOrderType(rawValue: type.uppercased())!
        let enumTimeInForce = timeInForce != nil ? BinanceOrderTime(rawValue: timeInForce!)! : nil

        let request = BinanceTestNewOrderRequest(
            symbol: symbol, side: enumSide, type: enumType, quantity: quantity as Decimal,
            price: price as Decimal?, timeInForce: enumTimeInForce,
            newClientOrderId: newClientOrderId,
            stopPrice: stopPrice as Decimal?, icebergQuantity: icebergQuantity as Decimal?)
        self.send(request, errorResponseHandler: handler)
    }

    func queryOrder(symbol: String, orderId: UInt64 = 0, originalClientOrderId: String?,
                    responseHandler handler: ResponseHandler<[String: Any]>?) -> Void {
        let request = BinanceQueryOrderRequest(
            symbol: symbol, orderId: orderId, originalClientOrderId: originalClientOrderId)
        self.send(request, responseHandler: handler)
    }

    func cancelOrder(symbol: String, orderId: UInt64 = 0, originalClientOrderId: String?, newClientOrderId: String?,
                     responseHandler handler: ResponseHandler<[String: Any]>?) -> Void {
        let request = BinanceCancelOrderRequest(
            symbol: symbol, orderId: orderId, originalClientOrderId: originalClientOrderId, newClientOrderId: newClientOrderId)
        self.send(request, responseHandler: handler)
    }

    func openOrders(symbol: String,
                    responseHandler handler: ResponseHandler<[[String: Any]]>?) -> Void {
        let request = BinanceOpenOrdersRequest(symbol: symbol)
        self.send(request, responseHandler: handler)
    }

    func allOrders(symbol: String, orderId: UInt64 = 0, limit: Int32 = 0,
                   responseHandler handler: ResponseHandler<[[String: Any]]>?) -> Void {
        let request = BinanceAllOrdersRequest(symbol: symbol, orderId: orderId, limit: limit)
        self.send(request, responseHandler: handler)
    }

    func accountInformation(responseHandler handler: ResponseHandler<[String: Any]>?) -> Void {
        let request = BinanceAccountInformationRequest()
        self.send(request, responseHandler: handler)
    }

    func accountTradeList(symbol: String, limit: Int32 = 0, fromId: UInt64 = 0,
                          responseHandler handler: ResponseHandler<[[String: Any]]>?) -> Void {
        let request = BinanceAccountTradeListRequest(symbol: symbol, limit: limit, fromId: fromId)
        self.send(request, responseHandler: handler)
    }
}
