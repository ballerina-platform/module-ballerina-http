/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.contractimpl.sender.http2;

import io.netty.buffer.ByteBuf;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.HttpHeaders;

import java.util.Objects;

/**
 * {@code Http2ResetContent} represents a HTTP/2 reset content.
 */
public class Http2ResetContent extends DefaultHttpContent {

    private HttpHeaders errorHeaders;

    /**
     * Creates a new instance with the specified chunk content.
     *
     * @param content content to be added to the instance
     * @param errorHeaders relevant error details that caused the reset
     */
    public Http2ResetContent(ByteBuf content, HttpHeaders errorHeaders) {
        super(content);
        this.errorHeaders = errorHeaders;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj instanceof Http2ResetContent) {
            Http2ResetContent that = (Http2ResetContent) obj;
            return errorHeaders.equals(that.errorHeaders);
        }
        return false;
    }

    @Override
    public int hashCode() {
        return Objects.hash(super.hashCode(), errorHeaders);
    }

    public void setErrorHeaders(HttpHeaders errorHeaders) {
        this.errorHeaders = errorHeaders;
    }

    public HttpHeaders getErrorHeaders() {
        return errorHeaders;
    }
}
