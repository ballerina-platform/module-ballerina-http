/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

module io.ballerina.stdlib.http {
    requires io.ballerina.runtime;
    requires io.ballerina.tools.api;
    requires io.ballerina.lang;
    requires io.ballerina.lang.value;
    requires io.ballerina.stdlib.mime;
    requires io.ballerina.stdlib.io;
    requires io.ballerina.stdlib.constraint;
    requires org.bouncycastle.provider;
    requires org.bouncycastle.pkix;
    requires jakarta.xml.bind;
    requires java.management;
    requires org.slf4j;
    requires java.logging;
    requires gson;
    requires io.netty.codec.http;
    requires io.netty.buffer;
    requires io.netty.common;
    requires io.netty.transport;
    requires io.netty.codec.http2;
    requires org.eclipse.osgi;
    requires io.netty.codec;
    requires io.netty.handler;
    requires commons.pool;
    requires io.netty.handler.proxy;
    requires io.ballerina.lib.data;
    exports io.ballerina.stdlib.http.api;
    exports io.ballerina.stdlib.http.transport.contract.websocket;
    exports io.ballerina.stdlib.http.transport.contract;
    exports io.ballerina.stdlib.http.transport.contract.exceptions;
    exports io.ballerina.stdlib.http.transport.contract.config;
    exports io.ballerina.stdlib.http.transport.contractimpl;
    exports io.ballerina.stdlib.http.transport.contractimpl.sender.channel.pool;
    exports io.ballerina.stdlib.http.transport.contractimpl.sender.http2;
    exports io.ballerina.stdlib.http.transport.internal;
    exports io.ballerina.stdlib.http.transport.message;
    exports io.ballerina.stdlib.http.uri;
    exports io.ballerina.stdlib.http.uri.parser;
    exports io.ballerina.stdlib.http.api.nativeimpl;
}
