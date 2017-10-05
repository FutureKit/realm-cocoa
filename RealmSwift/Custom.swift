////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

import Realm


public protocol RealmBackable  {
    associatedtype BackableStorageType: RealmBackingStorageType

    func toRealmBackableStorage() -> BackableStorageType?

    init?(fromRealmBackableStorage: BackableStorageType)
}

extension RealmBackable {
    public static var propType: PropertyType {
        return BackableStorageType.propType
    }
}

public final class RealmCustom<Value: RealmBackable> : RLMOptionalBase, RealmOptionalProtocol {

    public var value: Value? {
        get {
            guard let storage = underlyingValue as? Value.BackableStorageType else {
                return nil
            }
            // swiftlint:disable:next force_try
            return Value(fromRealmBackableStorage:storage)
        }
        set {
            // swiftlint:disable:next force_try
            underlyingValue = newValue?.toRealmBackableStorage()
        }
    }

    /**
     Creates a `RealmCustom` instance encapsulating the given default value.

     - parameter value: The value to store in the optional, or `nil` if not specified.
     */
    public init(_ value: Value? = nil) {
        super.init()
        self.value = value
    }

    public static var propType: PropertyType {
        return Value.BackableStorageType.propType
    }

}


extension RawRepresentable where RawValue: RealmBackingStorageType {
    public typealias BackableStorageType = RawValue

    public func toRealmBackableStorage() -> RawValue? {
        return self.rawValue
    }
    public static func fromRealmBackableStorage(storage: RawValue) throws -> Self? {
        return Self(rawValue:storage)
    }
}

#if swift(>=4)
extension RealmCustom : Encodable /* where Wrapped : Encodable */ {
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

extension RealmCustom : Decodable /* where Wrapped : Decodable */ {
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

#endif
extension URL: RealmBackable {
    public typealias BackableStorageType = String

    public func toRealmBackableStorage() -> String? {
        return self.absoluteString
    }

    public init?(fromRealmBackableStorage: String) {
        self.init(string: fromRealmBackableStorage)
    }
}


