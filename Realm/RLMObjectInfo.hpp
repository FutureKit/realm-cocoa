////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import <Foundation/Foundation.h>
#import <unordered_map>
#import <vector>

namespace realm {
    class ObjectSchema;
    class Schema;
    class Table;
    struct Property;
}

class RLMObservationInfo;
@class RLMRealm, RLMSchema, RLMObjectSchema, RLMProperty;

NS_ASSUME_NONNULL_BEGIN

namespace std {
// Add specializations so that NSString can be used as the key for hash containers
template<> struct hash<NSString *> {
    size_t operator()(__unsafe_unretained NSString *const str) const {
        return [str hash];
    }
};
template<> struct equal_to<NSString *> {
    bool operator()(__unsafe_unretained NSString * lhs, __unsafe_unretained NSString *rhs) const {
        return [lhs isEqualToString:rhs];
    }
};
}

// The per-RLMRealm object schema information which stores the cached table
// reference, handles table column lookups, and tracks observed objects
struct RLMObjectInfo {
public:
    RLMObjectInfo(RLMRealm *, RLMObjectSchema *, const realm::ObjectSchema *);

    __unsafe_unretained RLMRealm *const realm;
    __unsafe_unretained RLMObjectSchema *const rlmObjectSchema;
    const realm::ObjectSchema *const objectSchema;

    // Storage for the functionality in RLMObservation for handling indirect
    // changes to KVO-observed things
    std::vector<RLMObservationInfo *> observedObjects;

    // Get the table for this object type. Will return nullptr only if it's a
    // read-only Realm that is missing the table entirely.
    realm::Table *_Nullable table() const;

    // Get the RLMProperty for a given table column, or `nil` if it is a column
    // not used by the current schema
    RLMProperty *_Nullable propertyForTableColumn(NSUInteger) const noexcept;

    // Get the table column for the given property. The property must be a valid
    // persisted property.
    NSUInteger tableColumn(NSString *propertyName) const;
    NSUInteger tableColumn(RLMProperty *property) const;

    void releaseTable() { m_table = nullptr; }

private:
    mutable realm::Table *_Nullable m_table = nullptr;
};

// A per-RLMRealm object schema map which stores RLMObjectInfo keyed on the name
class RLMSchemaInfo {
    using impl = std::unordered_map<NSString *, RLMObjectInfo>;
public:
    void init(RLMRealm *realm, RLMSchema *rlmSchema, realm::Schema const& schema);

    // Look up by name, returning `nil` if it's not present
    RLMObjectInfo *_Nullable find(NSString *name) const noexcept;
    // Look up by name, throwing if it's not present
    RLMObjectInfo& operator[](NSString *name) const;

    impl::iterator begin() noexcept;
    impl::iterator end() noexcept;
    impl::const_iterator begin() const noexcept;
    impl::const_iterator end() const noexcept;
private:
    std::unordered_map<NSString *, RLMObjectInfo> m_objects;
};

NS_ASSUME_NONNULL_END
