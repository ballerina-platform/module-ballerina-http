// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/jballerina.java;

// This is same as the `value:Cloneable`, except that it does not include `error` type.
# Represents a non-error type that can be cloned.
public type Cloneable (any & readonly)|xml|Cloneable[]|map<Cloneable>|table<map<Cloneable>>;

# Request context member type.
public type ReqCtxMember Cloneable|isolated object {};

# Request context member type descriptor.
public type ReqCtxMemberType typedesc<ReqCtxMember>;

# Represents an HTTP Context that allows user to pass data between interceptors.
public isolated class RequestContext {
    private final map<ReqCtxMember> members = {};

    # Sets a member to the request context object.
    #
    # + key - Represents the member key
    # + value - Represents the member value
    public isolated function set(string key, ReqCtxMember value) {
        if value is Cloneable {
            lock {
                self.members[key] = value.clone();
            }
        }
        else {
            lock {
                self.members[key] = value;
            }
        }
    }

    # Gets a member value from the request context object. It panics if there is no such member.
    #
    # + key - Represents the member key
    # + return - Member value
    public isolated function get(string key) returns ReqCtxMember {
        lock {
            Cloneable|isolated object {} value = self.members.get(key);

            if value is Cloneable {
                return value.clone();
            } else {
                return value;
            }
        }
    }

    # Checks whether the request context object has a member corresponds to the key.
    #
    # + key - Represents the member key
    # + return - true if the member exists, else false
    public isolated function hasKey(string key) returns boolean {
        lock {
            return self.members.hasKey(key);
        }
    }

    # Returns the member keys of the request context object.
    #
    # + return - Array of member keys
    public isolated function keys() returns string[] {
        lock {
            return self.members.keys().clone();
        }
    }

    # Gets a member value with type from the request context object.
    #
    # + key - Represents the member key
    # + targetType - Represents the expected type of the member value
    # + return - Attribute value or an error. The error is returned if the member does not exist or
    #  if the member value is not of the expected type
    public isolated function getWithType(string key, ReqCtxMemberType targetType = <>)
        returns targetType|ListenerError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternRequestContext"
    } external;

    # Removes a member from the request context object. It panics if there is no such member.
    #
    # + key - Represents the member key
    public isolated function remove(string key) {
        lock {
            ReqCtxMember|error err = trap self.members.remove(key);
            if err is error {
                panic err;
            }
        }
    }

    # Calls the next service in the interceptor pipeline.
    #
    # + return - The next service object in the pipeline. An error is returned, if the call fails
    public isolated function next() returns NextService|error? = @java:Method {
        'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternRequestContext"
    } external;
}
