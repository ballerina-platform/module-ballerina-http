/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.logging.util;

import java.io.FilterOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.concurrent.atomic.AtomicLong;

/**
 * An OutputStream wrapper that counts the number of bytes written to it.
 *
 * @since 2.16.0
 */
public class CountingOutputStream extends FilterOutputStream {

    private final AtomicLong byteCount;

    public CountingOutputStream(OutputStream out, long initialCount) {
        super(out);
        this.byteCount = new AtomicLong(initialCount);
    }

    @Override
    public void write(int b) throws IOException {
        out.write(b);
        byteCount.incrementAndGet();
    }

    @Override
    public void write(byte[] b, int off, int len) throws IOException {
        out.write(b, off, len);
        byteCount.addAndGet(len);
    }

    @Override
    public void write(byte[] b) throws IOException {
        out.write(b);
        byteCount.addAndGet(b.length);
    }

    public long getByteCount() {
        return byteCount.get();
    }

    public void resetByteCount(long value) {
        byteCount.set(value);
    }
}
