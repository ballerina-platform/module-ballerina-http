// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

isolated Listener? defaultListener = ();

# Default HTTP listener port used by the HTTP Default Listener.
# The default value is 9090.
public configurable int defaultListenerPort = 9090;

# Default HTTP listener configuration used by the HTTP Default Listener.
public configurable ListenerConfiguration defaultListenerConfig = {};

# Returns the default HTTP listener. If the default listener is not already created, a new
# listener will be created with the port and configuration. An error will be returned if
# the listener creation fails.
#
# The default listener configuration can be changed in the `Config.toml` file. Example:
# ```toml
# [ballerina.http]
# defaultListenerPort = 8080
#
# [ballerina.http.defaultListenerConfig]
# httpVersion = "1.1"
#
# [ballerina.http.defaultListenerConfig.secureSocket.key]
# path = "resources/certs/key.pem"
# password = "password"
# ```
#
# + return - The default HTTP listener or an error if the listener creation fails.
public isolated function getDefaultListener() returns Listener|ListenerError {
    lock {
        if defaultListener is () {
            defaultListener = check new (defaultListenerPort, defaultListenerConfig);
        }
        return checkpanic defaultListener.ensureType();
    }
}
