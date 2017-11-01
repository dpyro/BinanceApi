//
//  DataRequest+BinanceRequest.swift
//  BinanceApi
//
//  Created by Sumant Manne on 10/26/17.
//  Copyright © 2017 Sumant Manne. All rights reserved.
//

import Alamofire
import Foundation

extension Alamofire.DataRequest {
    private static func BinanceRequestResponseSerializer<T: Decodable>(_ keyPath: String?, _ decoder: JSONDecoder) -> DataResponseSerializer<T> {
        return DataResponseSerializer {
            (request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) -> Result<T> in

            if let error = error {
                return .failure(error)
            }

            if let keyPath = keyPath {
                if keyPath.isEmpty {
                    return .failure(BinanceApiError.emptyKeyPath)
                }
                return DataRequest.decodeToObject(T.self, decoder: decoder, response: response, data: data)
            }

            return DataRequest.decodeToObject(T.self, decoder: decoder, response: response, data: data)
        }
    }

    private static func decodeToObject<T: Decodable>(_ type: T.Type, decoder: JSONDecoder, response: HTTPURLResponse?, data: Data?) -> Result<T> {
        let result = Request.serializeResponseData(response: response, data: data, error: nil)

        switch result {
        case .success(let data):
            do {
                let object = try decoder.decode(BinanceResponse<T>.self, from: data)
                switch object {
                case BinanceResponse<T>.error(let error):
                    return .failure(error)
                case BinanceResponse<T>.result(let response):
                    return .success(response)
                }
            } catch {
                return .failure(error)
            }
        case .failure(let error): return .failure(error)
        }
    }

    private static func decodeToObject<T: Decodable>(byKeyPath keyPath: String, decoder: JSONDecoder, response: HTTPURLResponse?, data: Data?) -> Result<T> {
        return .failure(BinanceApiError.unknown)
    }

    @discardableResult
    public func responseBinanceResponse<T: Decodable>(
        _ type: T.Type,
        queue: DispatchQueue? = nil,
        keyPath: String? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        completionHandler: @escaping (DataResponse<T>) -> Void) -> Self
    {
        return response(
            queue: queue,
            responseSerializer: DataRequest.BinanceRequestResponseSerializer(keyPath, decoder),
            completionHandler: completionHandler)
    }
}

/// https://stackoverflow.com/a/46329055/1440740
extension Encodable {
    var asData: Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return try! encoder.encode(self)
    }

    var asParameters: Parameters? {
        guard let dictionary =
            try? JSONSerialization.jsonObject(with: self.asData, options: .allowFragments) else
        {
            return nil
        }
        return dictionary as? [String: Any]
    }
}

extension TimeInterval {
    var asMilliseconds: UInt64 {
        return UInt64(self * 1000)
    }
}

extension KeyedEncodingContainer {
    /// Encode a Date into a milliseconds long
    mutating func encode(_ value: Date, forKey key: Key) throws {
        let result = value.timeIntervalSince1970
        try self.encode(result.asMilliseconds, forKey: key)
    }

    /// Encode a TimeInterval into a milliseconds long
    mutating func encode(_ value: TimeInterval, forKey key: Key) throws {
        try self.encode(value.asMilliseconds, forKey: key)
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: Decimal.Type) throws -> Decimal {
        return Decimal(string: try self.decode(String.self))!
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: Decimal.Type, forKey key: Key) throws -> Decimal {
        return Decimal(string: try self.decode(String.self, forKey: key))!
    }

    /// Decode a UNIX timestamp given in milliseconds
    func decode(_ type: Date.Type, forKey key: Key) throws -> Date {
        return Date(timeIntervalSince1970: Double(try self.decode(UInt64.self, forKey: key))/1000.0)
    }
}
