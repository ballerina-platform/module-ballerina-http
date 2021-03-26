// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

# This class is used for creating HTTP listener. An HTTP listener is capable of responding to remote callers. The
# `Listener` is responsible for initializing the endpoint using the provided configurations.
public class Listener {

    private int port;
    private ListenerConfiguration config;

    # Gets invoked during module initialization to initialize the listener.
    #
    # + port - Listening port of the HTTP service listener
    # + config - Configurations for the HTTP service listener
    # + return - A `ListenerError` if an error occurred during the listener initialization
    public isolated function init(int port, *ListenerConfiguration config) returns ListenerError? {
        self.config = config;
        self.port = port;
        return externInitEndpoint(self);
    }

    # Starts the registered service programmatically.
    #
    # + return - A `ListenerError` if an error occurred during the listener starting process
    public isolated function 'start() returns ListenerError? {
        return externStart(self);
    }

    # Stops the service listener gracefully. Already-accepted requests will be served before connection closure.
    #
    # + return - A `ListenerError` if an error occurred during the listener stopping process
    public isolated function gracefulStop() returns ListenerError? {
        return externGracefulStop(self);
    }

    # Stops the service listener immediately. It is not implemented yet.
    #
    # + return - A `ListenerError` if an error occurred during the listener stop process
    public isolated function immediateStop() returns ListenerError? {
        return error ListenerError("not implemented");
    }

    # Attaches a service to the listener.
    #
    # + httpService - The service that needs to be attached
    # + name - Name of the service
    # + return - A `ListenerError` an error occurred during the service attachment process or else nil
    public isolated function attach(Service httpService, string[]|string? name = ()) returns ListenerError? {
        return externRegister(self, httpService, name);
    }

    # Detaches a Http service from the listener.
    #
    # + httpService - The service to be detached
    # + return - A `ListenerError` if one occurred during detaching of a service or else `()`
    public isolated function detach(Service httpService) returns ListenerError? {
        return externDetach(self, httpService);
    }

    # Retrieves the port of the HTTP listener.
    #
    # + return - The HTTP listener port
    public isolated function getPort() returns int {
        return self.port;
    }

    # Retrieves the `ListenerConfiguration` of the HTTP listener.
    #
    # + return - The readonly HTTP listener configuration
    public isolated function getConfig() returns readonly & ListenerConfiguration {
        return <readonly & ListenerConfiguration> self.config.cloneReadOnly();
    }
}

isolated function externInitEndpoint(Listener listenerObj) returns ListenerError? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.InitEndpoint",
    name: "initEndpoint"
} external;

isolated function externRegister(Listener listenerObj, Service httpService, string[]|string? name)
returns ListenerError? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.Register",
    name: "register"
} external;

isolated function externStart(Listener listenerObj) returns ListenerError? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.Start",
    name: "start"
} external;

isolated function externGracefulStop(Listener listenerObj) returns ListenerError? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.GracefulStop",
    name: "gracefulStop"
} external;

isolated function externDetach(Listener listenerObj, Service httpService) returns ListenerError? = @java:Method {
    'class: "org.ballerinalang.net.http.serviceendpoint.Detach",
    name: "detach"
} external;
