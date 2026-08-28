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

import org.testng.annotations.Test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

import static org.testng.Assert.assertEquals;

/**
 * Unit tests for {@link CountingOutputStream}, the byte counter the access log rotation thresholds are
 * measured with.
 */
public class CountingOutputStreamTest {

    @Test(description = "A stream starts from the initial count it was given, so an appended file keeps its size")
    public void testInitialCountIsRetained() throws IOException {
        ByteArrayOutputStream sink = new ByteArrayOutputStream();
        try (CountingOutputStream stream = new CountingOutputStream(sink, 42L)) {
            assertEquals(stream.getByteCount(), 42L, "Initial count was not retained");
        }
    }

    @Test(description = "Single byte writes are counted and passed through to the wrapped stream")
    public void testSingleByteWriteIsCounted() throws IOException {
        ByteArrayOutputStream sink = new ByteArrayOutputStream();
        try (CountingOutputStream stream = new CountingOutputStream(sink, 0L)) {
            stream.write('a');
            stream.write('b');
            stream.flush();
            assertEquals(stream.getByteCount(), 2L, "Byte count does not match the bytes written");
            assertEquals(sink.toString(StandardCharsets.UTF_8), "ab", "Bytes did not reach the wrapped stream");
        }
    }

    @Test(description = "Whole array writes add the full array length to the count")
    public void testArrayWriteIsCounted() throws IOException {
        ByteArrayOutputStream sink = new ByteArrayOutputStream();
        byte[] payload = "hello".getBytes(StandardCharsets.UTF_8);
        try (CountingOutputStream stream = new CountingOutputStream(sink, 0L)) {
            stream.write(payload);
            stream.flush();
            assertEquals(stream.getByteCount(), payload.length, "Byte count does not match the array length");
            assertEquals(sink.toString(StandardCharsets.UTF_8), "hello", "Bytes did not reach the wrapped stream");
        }
    }

    @Test(description = "Ranged writes count only the requested length, not the whole array")
    public void testRangedWriteCountsOnlyTheRequestedLength() throws IOException {
        ByteArrayOutputStream sink = new ByteArrayOutputStream();
        byte[] payload = "abcdefgh".getBytes(StandardCharsets.UTF_8);
        try (CountingOutputStream stream = new CountingOutputStream(sink, 0L)) {
            stream.write(payload, 2, 3);
            stream.flush();
            assertEquals(stream.getByteCount(), 3L, "Byte count should cover only the written range");
            assertEquals(sink.toString(StandardCharsets.UTF_8), "cde", "Wrong range reached the wrapped stream");
        }
    }

    @Test(description = "Counts from every write overload accumulate together")
    public void testCountsAccumulateAcrossOverloads() throws IOException {
        ByteArrayOutputStream sink = new ByteArrayOutputStream();
        try (CountingOutputStream stream = new CountingOutputStream(sink, 10L)) {
            stream.write('x');
            stream.write("yz".getBytes(StandardCharsets.UTF_8));
            stream.write("0123".getBytes(StandardCharsets.UTF_8), 1, 2);
            stream.flush();
            assertEquals(stream.getByteCount(), 15L, "Counts from the write overloads did not accumulate");
        }
    }

    @Test(description = "Resetting the count is what lets a rotated file start measuring from zero again")
    public void testResetByteCount() throws IOException {
        ByteArrayOutputStream sink = new ByteArrayOutputStream();
        try (CountingOutputStream stream = new CountingOutputStream(sink, 0L)) {
            stream.write("payload".getBytes(StandardCharsets.UTF_8));
            stream.resetByteCount(0L);
            assertEquals(stream.getByteCount(), 0L, "Count was not reset");
            stream.write('a');
            assertEquals(stream.getByteCount(), 1L, "Counting did not resume from the reset value");
            stream.resetByteCount(100L);
            assertEquals(stream.getByteCount(), 100L, "Count was not reset to an arbitrary value");
        }
    }
}
