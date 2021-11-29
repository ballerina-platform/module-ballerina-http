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

# Represents an HTTP Context that allows user to pass data between filters.
public isolated class RequestContext {
    private final map<value:Cloneable|isolated object {}> attributes = {};

    # Sets an attribute to the request context object.
    #
    # + key - Represents the attribute key
    # + value - Represents the attribute value
    public isolated function set(string key, value:Cloneable|isolated object {} value) {
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
    public isolated function get(string key) returns value:Cloneable|isolated object {} {
        lock {
            value:Cloneable|isolated object {} value = self.attributes.get(key);

            if value is value:Cloneable {
                return value.clone();
            } else {
                return value;
            }
        }
    }

    # Removes an attribute from the request context object. It panics if there is no such member.
    #
    # + key - Represents the attribute key
    public isolated function remove(string key) {
        lock {
            value:Cloneable|isolated object {} err = trap self.attributes.remove(key);
            if (err is error) {
                panic err;
            }
        }
    }

    # Calls the next service in the interceptor pipeline.
    #
    # + return - The next service object in the pipeline. An error is returned, if the call fails 
    public isolated function next() returns NextService|error? {
        lock {
            return externRequestCtxNext(self);
        }
    }
}

isolated function externRequestCtxNext(RequestContext requestCtx) returns NextService|error? = @java:Method {
    name: "next",
    'class: "io.ballerina.stdlib.http.api.nativeimpl.ExternRequestContext"
} external;
