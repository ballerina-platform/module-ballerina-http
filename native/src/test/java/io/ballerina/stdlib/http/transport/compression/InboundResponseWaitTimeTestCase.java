/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.compression;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.message.HttpCarbonResponse;
import io.ballerina.stdlib.http.transport.message.HttpMessageDataStreamer;
import io.netty.handler.codec.DecoderException;
import io.netty.handler.codec.http.DefaultHttpResponse;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import org.testng.annotations.Test;

import java.io.InputStream;
import java.util.concurrent.TimeUnit;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertTrue;
import static org.testng.Assert.expectThrows;

/**
 * Tests the bound on an inbound response body read, which covers a stalled body when no terminal event ever reaches
 * the response. The idle timeout handlers end a stalled body at the configured client timeout, so the bound is
 * resolved to trail it and never preempts their more precise report.
 */
public class InboundResponseWaitTimeTestCase {

    private static final int CONFIGURED_WAIT_MILLIS = 500;
    private static final int GUARD_MILLIS = 30_000;

    @Test(description = "A read on a body that never arrives fails after the configured wait", timeOut = 60_000)
    public void testBodyReadIsBoundedByConfiguredWait() {
        HttpCarbonResponse response = new HttpCarbonResponse(
                new DefaultHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.OK),
                CONFIGURED_WAIT_MILLIS, null);
        InputStream inputStream = new HttpMessageDataStreamer(response).getInputStream();

        long start = System.nanoTime();
        expectThrows(DecoderException.class, inputStream::read);
        long elapsedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);

        assertTrue(elapsedMillis < GUARD_MILLIS, "Read was not bounded by the configured wait: " + elapsedMillis);
    }

    @Test(description = "A missing or non-positive timeout keeps the endpoint default")
    public void testNonPositiveTimeoutFallsBackToEndpointTimeout() {
        assertEquals(Util.resolveEntityWaitTime(0), Constants.ENDPOINT_TIMEOUT);
        assertEquals(Util.resolveEntityWaitTime(-1), Constants.ENDPOINT_TIMEOUT);
    }

    @Test(description = "The read bound trails the idle timeout so the idle handlers report a stall first")
    public void testReadBoundTrailsConfiguredTimeout() {
        assertEquals(Util.resolveEntityWaitTime(CONFIGURED_WAIT_MILLIS),
                CONFIGURED_WAIT_MILLIS + Util.ENTITY_WAIT_GRACE_MILLIS);
        assertEquals(Util.resolveEntityWaitTime(Integer.MAX_VALUE), Integer.MAX_VALUE);
    }
}
