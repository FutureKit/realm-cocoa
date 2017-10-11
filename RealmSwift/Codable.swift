////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation

#if swift(>=4 )

// swiftlint:disable line_length identifier_name
// stolen functions from the Swift stdlib
// https://github.com/apple/swift/blob/a24998a5b12151e8acfbe5f1f70dcf80685334b1/stdlib/public/core/Codable.swift
//
@_inlineable
@_versioned
internal func assertTypeIsEncodable<T>(_ type: T.Type, in wrappingType: Any.Type) {
    guard T.self is Encodable.Type else {
        if T.self == Encodable.self || T.self == Codable.self {
            preconditionFailure("\(wrappingType) does not conform to Encodable because Encodable does not conform to itself. You must use a concrete type to encode or decode.")
        } else {
            preconditionFailure("\(wrappingType) does not conform to Encodable because \(T.self) does not conform to Encodable.")
        }
    }
}

@_inlineable
@_versioned
internal func assertTypeIsDecodable<T>(_ type: T.Type, in wrappingType: Any.Type) {
    guard T.self is Decodable.Type else {
        if T.self == Decodable.self || T.self == Codable.self {
            preconditionFailure("\(wrappingType) does not conform to Decodable because Decodable does not conform to itself. You must use a concrete type to encode or decode.")
        } else {
            preconditionFailure("\(wrappingType) does not conform to Decodable because \(T.self) does not conform to Decodable.")
        }
    }
}

extension Encodable {
    @_inlineable
    @_versioned
    internal func __encode(to container: inout SingleValueEncodingContainer) throws { try container.encode(self) }
    @_inlineable
    @_versioned
    internal func __encode(to container: inout UnkeyedEncodingContainer)     throws { try container.encode(self) }
    @_inlineable
    @_versioned
    internal func __encode<Key>(to container: inout KeyedEncodingContainer<Key>, forKey key: Key) throws { try container.encode(self, forKey: key) }
}

extension Decodable {
    // Since we cannot call these __init, we'll give the parameter a '__'.
    @_inlineable
    @_versioned
    internal init(__from container: SingleValueDecodingContainer)   throws { self = try container.decode(Self.self) }
    @_inlineable
    @_versioned
    internal init(__from container: inout UnkeyedDecodingContainer) throws { self = try container.decode(Self.self) }
    @_inlineable
    @_versioned
    internal init<Key>(__from container: KeyedDecodingContainer<Key>, forKey key: Key) throws { self = try container.decode(Self.self, forKey: key) }
}

public protocol DecodableWithDefault: Decodable {
    static func defaultDecodableValue() -> Self
}


extension KeyedDecodingContainerProtocol {
    public func decode<T>(_ type: T.Type, forKey key: Self.Key) throws -> T where T: DecodableWithDefault {
        if let t = try self.decodeIfPresent(T.self, forKey: key) {
            return t
        }
        return T.defaultDecodableValue()
    }
}


extension RealmOptional : Encodable /* where Wrapped : Encodable */ {
    @_inlineable
    public func encode(to encoder: Encoder) throws {
        assertTypeIsEncodable(Value.self, in: type(of: self))

        var container = encoder.singleValueContainer()
        if let v = self.value {
            try (v as! Encodable).encode(to: encoder)  // swiftlint:disable:this force_cast
        } else {
            try container.encodeNil()
        }
    }
}

extension RealmOptional : DecodableWithDefault /* where Wrapped : Decodable */ {
    public static func defaultDecodableValue() -> RealmOptional<Value> {
        return RealmOptional<Value>(nil)
    }


    @_inlineable // FIXME(sil-serialize-all)
    public convenience init(from decoder: Decoder) throws {
        // Initialize self here so we can get type(of: self).
        self.init()
        assertTypeIsDecodable(Value.self, in: type(of: self))

        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            let metaType = (Value.self as! Decodable.Type) // swiftlint:disable:this force_cast
            let element = try metaType.init(from: decoder)
            self.value = (element as! Value)  // swiftlint:disable:this force_cast
        }
    }
}
extension List : DecodableWithDefault /* where Element : Decodable */ {
    public static func defaultDecodableValue() -> List<Element> {
        return List<Element>()
    }

   @_inlineable // FIXME(sil-serialize-all)
    public convenience init(from decoder: Decoder) throws {
        // Initialize self here so we can get type(of: self).
        self.init()
        assertTypeIsDecodable(Element.self, in: type(of: self))

        let metaType = (Element.self as! Decodable.Type) // swiftlint:disable:this force_cast

        do {
            var container = try decoder.unkeyedContainer()
            while !container.isAtEnd {
                let element = try metaType.init(__from: &container)
                self.append(element as! Element) // swiftlint:disable:this force_cast
            }
        }
        catch DecodingError.valueNotFound(let type, let context) {
            do {
                let container = try decoder.singleValueContainer()
                if !container.decodeNil() {
                    throw DecodingError.valueNotFound(type, context)
                }
            }
            catch {
                throw DecodingError.valueNotFound(type, context)
            }
        }
    }
}

extension List: Encodable /* where Element : Decodable */ {

    @_inlineable // FIXME(sil-serialize-all)
    public func encode(to encoder: Encoder) throws {
        assertTypeIsEncodable(Element.self, in: type(of: self))

        var container = encoder.unkeyedContainer()
        for element in self {
            // superEncoder appends an empty element and wraps an Encoder around it.
            // This is normally appropriate for encoding super, but this is really what we want to do.
            let subencoder = container.superEncoder()
            try (element as! Encodable).encode(to: subencoder) // swiftlint:disable:this force_cast
        }
    }
}

#endif
