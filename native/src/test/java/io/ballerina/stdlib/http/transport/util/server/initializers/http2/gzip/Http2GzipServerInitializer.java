/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.util.server.initializers.http2.gzip;

import io.ballerina.stdlib.http.transport.util.server.initializers.http2.Http2ServerInitializer;
import io.netty.channel.ChannelHandler;
import io.netty.handler.codec.http2.Http2ConnectionHandler;

/**
 * Initializer for a HTTP/2 server which always declares a gzip content encoding.
 */
public class Http2GzipServerInitializer extends Http2ServerInitializer {

    @Override
    protected ChannelHandler getBusinessLogicHandler() {
        return new H2GzipHandlerBuilder().build();
    }

    @Override
    protected Http2ConnectionHandler getBusinessLogicHandlerViaBuiler() {
        return new H2GzipHandlerBuilder().build();
    }
}
