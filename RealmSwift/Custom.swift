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

public protocol RealmBackingStorageType {
    static func propType() -> PropertyType
}
extension Data: RealmBackingStorageType {
    public static func propType() -> PropertyType {
        return .data
    }
}
extension String: RealmBackingStorageType {
    public static func propType() -> PropertyType {
        return .string
    }
}
extension Int: RealmBackingStorageType {
    public static func propType() -> PropertyType {
        return .int
    }
}
extension Int8: RealmBackingStorageType {
    public static func propType() -> PropertyType  {
        return .int
    }
}
extension Int16: RealmBackingStorageType {
    public static func propType() -> PropertyType {
        return .int
    }
}
extension Int32: RealmBackingStorageType {
    public static func propType() -> PropertyType  {
        return .int
    }
}
extension Int64: RealmBackingStorageType {
    public static func propType() -> PropertyType {
        return .int
    }
}
extension Float: RealmBackingStorageType {
    public static func propType() -> PropertyType {
        return .float
    }
}
extension Double: RealmBackingStorageType {
    public static func propType() -> PropertyType {
        return .double
    }
}
extension Bool: RealmBackingStorageType {
    public static func propType() -> PropertyType {
        return .bool
    }
}

public protocol RealmBackable {
    associatedtype BackableStorageType: RealmBackingStorageType

    func toRealmBackableStorage() throws -> BackableStorageType?
    static func fromRealmBackableStorage(storage: BackableStorageType) throws -> Self?
}

public final class RealmCustom<T: RealmBackable> : RLMOptionalBase, HasPropertyType {

    public var value: T? {
        get {
            guard let storage = underlyingValue as? T.BackableStorageType else {
                return nil
            }
            // swiftlint:disable:next force_try
            return try! T.fromRealmBackableStorage(storage:storage)
        }
        set {
            // swiftlint:disable:next force_try
            underlyingValue = try! newValue?.toRealmBackableStorage()
        }
    }

    /**
     Creates a `RealmCustom` instance encapsulating the given default value.

     - parameter value: The value to store in the optional, or `nil` if not specified.
     */
    public init(_ value: T? = nil) {
        super.init()
        self.value = value
    }

    internal var propType: PropertyType {
        return T.BackableStorageType.propType()
    }

}


extension RawRepresentable {
    public typealias BackableStorageType = RawValue

    public func toRealmBackableStorage() throws -> RawValue? {
        return self.rawValue
    }
    public static func fromRealmBackableStorage(storage: RawValue) throws -> Self? {
        return Self(rawValue:storage)
    }
}

#if swift(>=4)
extension RealmCustom : Encodable /* where Wrapped : Encodable */ {
    public func encode(to encoder: Encoder) throws {
        assertTypeIsEncodable(T.self, in: type(of: self))

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
        assertTypeIsDecodable(T.self, in: type(of: self))

        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            let metaType = (T.self as! Decodable.Type) // swiftlint:disable:this force_cast
            let element = try metaType.init(from: decoder)
            self.value = (element as! T)  // swiftlint:disable:this force_cast
        }
    }
}


extension Decodable where Self: Encodable {
    public typealias BackableStorageType = Data

    public func toRealmBackableStorage() throws -> Data? {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }

    public static func fromRealmBackableStorage(storage: Data) throws -> Self? {
        let decoder = JSONDecoder()
        let value = try decoder.decode(Self.self, from: storage)
        return value
    }
}

extension URL: RealmBackable {}

#else
extension URL: RealmBackable {
    public typealias BackableStorageType = String

    public func toRealmBackableStorage() throws -> String? {
        return self.absoluteString
    }

    public static func fromRealmBackableStorage(storage: String) throws -> URL? {
        return URL(string: storage)
    }
}

#endif

