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
import ballerina/lang.value;

# Request context attribute type.
public type ReqCtxAttribute value:Cloneable|isolated object {};

# Request context attribute type descriptor.
public type ReqCtxAttributeType typedesc<ReqCtxAttribute>;

# Represents an HTTP Context that allows user to pass data between interceptors.
public isolated class RequestContext {
    private final map<ReqCtxAttribute> attributes = {};

    # Sets an attribute to the request context object.
    #
    # + key - Represents the attribute key
    # + value - Represents the attribute value
    public isolated function set(string key, ReqCtxAttribute value) {
        if value is value:Cloneable {
            lock {
                self.attributes[key] = value.clone();
            }
        }
        else {
            lock {
                self.attributes[key] = value;
            }   
        }
    }

    # Gets an attribute value from the request context object.
    #
    # + key - Represents the attribute key
    # + return - Attribute value
    public isolated function get(string key) returns ReqCtxAttribute {
        lock {
            value:Cloneable|isolated object {} value = self.attributes.get(key);

            if value is value:Cloneable {
                return value.clone();
            } else {
                return value;
            }
        }
    }

    # Checks whether the request context object has an attribute corresponds to the key.
    #
    # + key - Represents the attribute key
    # + return - true if the attribute exists, else false
    public isolated function hasKey(string key) returns boolean {
        lock {
            return self.attributes.hasKey(key);
        }
    }

    # Returns the attribute keys of the request context object.
    #
    # + return - Array of attribute keys
    public isolated function keys() returns string[] {
        lock {
            return self.attributes.keys().clone();
        }
    }

    # Gets an attribute value with type from the request context object.
    #
    # + key - Represents the attribute key
    # + targetType - Represents the expected type of the attribute value
    # + return - Attribute value or an error if the attribute value is not of the expected type
    public isolated function getWithType(string key, ReqCtxAttributeType targetType = <>)
        returns targetType|ListenerError = @java:Method {
        'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternRequestContext"
    } external;

    # Removes an attribute from the request context object. It panics if there is no such member.
    #
    # + key - Represents the attribute key
    public isolated function remove(string key) {
        lock {
            ReqCtxAttribute err = trap self.attributes.remove(key);
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
