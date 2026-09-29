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

import io.netty.handler.codec.http2.AbstractHttp2ConnectionHandlerBuilder;
import io.netty.handler.codec.http2.Http2ConnectionDecoder;
import io.netty.handler.codec.http2.Http2ConnectionEncoder;
import io.netty.handler.codec.http2.Http2Settings;

/**
 * Represents the gzip response handler builder.
 */
public final class H2GzipHandlerBuilder
        extends AbstractHttp2ConnectionHandlerBuilder<H2GzipHandler, H2GzipHandlerBuilder> {

    @Override
    public H2GzipHandler build() {
        return super.build();
    }

    @Override
    protected H2GzipHandler build(Http2ConnectionDecoder decoder, Http2ConnectionEncoder encoder,
                                  Http2Settings initialSettings) {
        H2GzipHandler handler = new H2GzipHandler(decoder, encoder, initialSettings);
        frameListener(handler);
        return handler;
    }
}
