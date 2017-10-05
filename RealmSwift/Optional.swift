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

// this defines Swift types that can be used inside Realm as storage.
// each maps to a PropertyType
public protocol RealmBackingStorageType : Equatable {
    static var propType: PropertyType { get }

}

/// A protocol describing types that can parameterize a `RealmOptional`.
public protocol RealmOptionalType: RealmBackingStorageType {}


public extension RealmOptionalType {
    /// :nodoc:
    public static func className() -> String {
        return ""
    }
}

extension Int: RealmOptionalType {
    public static var propType: PropertyType {
        return .int
    }
}
extension Int8: RealmOptionalType {
    public static var propType: PropertyType {
        return .int
    }
}
extension Int16: RealmOptionalType {
    public static var propType: PropertyType {
        return .int
    }
}
extension Int32: RealmOptionalType {
    public static var propType: PropertyType {
        return .int
    }
}
extension Int64: RealmOptionalType {
    public static var propType: PropertyType {
        return .int
    }
}
extension Float: RealmOptionalType {
    public static var propType: PropertyType {
        return .float
    }
}
extension Double: RealmOptionalType {
    public static var propType: PropertyType {
        return .double
    }
}

extension Bool: RealmOptionalType {
    public static var propType: PropertyType {
        return .bool
    }
}

extension Date: RealmBackingStorageType {
    public static var propType: PropertyType {
        return .date
    }
}

extension NSDate: RealmBackingStorageType {
    public static var propType: PropertyType {
        return .date
    }
}

extension NSData: RealmBackingStorageType {
    public static var propType: PropertyType {
        return .data
    }
}

extension Data: RealmBackingStorageType {
    public static var propType: PropertyType {
        return .data
    }
}



extension String: RealmBackingStorageType {
    public static var propType: PropertyType {
        return .string
    }
}

extension NSString: RealmBackingStorageType {
    public static var propType: PropertyType {
        return .string
    }
}


extension Object: RealmOptionalType {
    public static var propType: PropertyType {
        return .object
    }
}

public protocol RealmOptionalProtocol {
    static var propType: PropertyType { get }
}

/**
 A `RealmOptional` instance represents an optional value for types that can't be
 directly declared as `@objc` in Swift, such as `Int`, `Float`, `Double`, and `Bool`.

 To change the underlying value stored by a `RealmOptional` instance, mutate the instance's `value` property.
 */
public final class RealmOptional<Value: RealmOptionalType>: RLMOptionalBase, RealmOptionalProtocol {
    /// The value the optional represents.
    public var value: Value? {
        get {
            return underlyingValue.map(dynamicBridgeCast)
        }
        set {
            underlyingValue = newValue.map(dynamicBridgeCast)
        }
    }

    /**
     Creates a `RealmOptional` instance encapsulating the given default value.

     - parameter value: The value to store in the optional, or `nil` if not specified.
     */
    public init(_ value: Value? = nil) {
        super.init()
        self.value = value
    }

    public static var propType: PropertyType {
        return Value.propType
    }
}
