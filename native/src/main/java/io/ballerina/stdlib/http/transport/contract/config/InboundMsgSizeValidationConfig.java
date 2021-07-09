/*
 * Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contract.config;

/**
 * Configuration for the inbound request and response size validation.
 */
public class InboundMsgSizeValidationConfig {

    private int maxInitialLineLength = 4096;
    private int maxHeaderSize = 8192;
    private int maxChunkSize = 8192;
    private long maxEntityBodySize = -1;

    /**
     * The maximum length of the initial line (e.g. {@code "GET / HTTP/1.0"} or {@code "HTTP/1.0 200 OK"}) If the length
     * of the initial line exceeds this value, a TooLongFrameException will be raised from netty code.
     */
    public int getMaxInitialLineLength() {
        return maxInitialLineLength;
    }

    public void setMaxInitialLineLength(int maxInitialLineLength) {
        this.maxInitialLineLength = maxInitialLineLength;
    }

    /**
     * The maximum length of all headers.  If the sum of the length of each header exceeds this value, a
     * TooLongFrameException will be raised from netty code.
     */
    public int getMaxHeaderSize() {
        return maxHeaderSize;
    }

    public void setMaxHeaderSize(int maxHeaderSize) {
        this.maxHeaderSize = maxHeaderSize;
    }

    /**
     * The maximum length of the content or each chunk.  If the content length (or the length of each chunk) exceeds
     * this value, the content or chunk will be split into multiple HttpContents whose length is {@code maxChunkSize} at
     * maximum.
     */
    public int getMaxChunkSize() {
        return maxChunkSize;
    }

    public void setMaxChunkSize(int maxChunkSize) {
        this.maxChunkSize = maxChunkSize;
    }

    public long getMaxEntityBodySize() {
        return maxEntityBodySize;
    }

    public void setMaxEntityBodySize(long maxEntityBodySize) {
        this.maxEntityBodySize = maxEntityBodySize;
    }
}
