/*
 * Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.transport.contractimpl.common;

import io.netty.handler.codec.http2.Http2Connection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isStreamBlockedByFlowControl;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isWithinBackPressureStallLimit;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.remainingBackPressureStallNanos;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.ticksInNanos;

/**
 * Decides, on behalf of both HTTP/2 stream timeout handlers, whether the silence on a stream is down to flow
 * control rather than an unresponsive peer. Also excuses one extra check after the window has just reopened,
 * so a timer landing in that race does not fail a stream a slow peer would otherwise still complete, and caps
 * the whole reprieve at {@code maxBackPressureStallTime} so a peer that never reopens the window cannot pin a
 * stream forever.
 */
public class FlowControlStallTracker {

    private static final Logger LOG = LoggerFactory.getLogger(FlowControlStallTracker.class);
    private static final long MIN_RECHECK_NANOS = TimeUnit.MILLISECONDS.toNanos(1);

    private final Supplier<Http2Connection> connectionSupplier;
    // Streams whose recent timeout checks found them held up by flow control, and when that started.
    private final Map<Integer, Long> stallStartTimes = new ConcurrentHashMap<>();

    public FlowControlStallTracker(Supplier<Http2Connection> connectionSupplier) {
        this.connectionSupplier = connectionSupplier;
    }

    // True if the silence on streamId is explained by flow control and the maxBackPressureStallTime cap has
    // not been reached, i.e. the caller's timeout should be excused rather than failing the stream.
    public boolean isStalledByFlowControl(int streamId) {
        Long stallStartTime = stallStartTimes.get(streamId);
        if (stallStartTime != null && !isWithinBackPressureStallLimit(stallStartTime)) {
            // Left standing: until something actually moves, every further period should time out too.
            LOG.debug("Stream {} has been held up by flow control past the permitted stall time without any "
                              + "progress, letting the idle timeout run", streamId);
            return false;
        }
        if (isStreamBlockedByFlowControl(connectionSupplier.get(), streamId)) {
            // First time seen stalled: still check against the limit immediately, so a zero (or already
            // elapsed) allowance is not excused for one free period.
            long startTime = stallStartTime != null ? stallStartTime
                    : stallStartTimes.merge(streamId, ticksInNanos(), (existing, fresh) -> existing);
            return isWithinBackPressureStallLimit(startTime);
        }
        if (stallStartTime != null) {
            // The window has only just reopened; give the peer one full period to act before failing it.
            stallStartTimes.remove(streamId);
            return true;
        }
        return false;
    }

    // Delay before rechecking a stream currently excused for flow control: idleTimeNanos, unless
    // maxBackPressureStallTime is shorter, so a short cap does not have to wait a full idle period.
    public long nextRecheckDelayNanos(int streamId, long idleTimeNanos) {
        Long stallStartTime = stallStartTimes.get(streamId);
        if (stallStartTime == null) {
            return idleTimeNanos;
        }
        long remaining = remainingBackPressureStallNanos(stallStartTime);
        if (remaining < 0) {
            return idleTimeNanos;
        }
        return Math.min(idleTimeNanos, Math.max(remaining, MIN_RECHECK_NANOS));
    }

    public void recordProgress(int streamId) {
        stallStartTimes.remove(streamId);
    }

    public void remove(int streamId) {
        stallStartTimes.remove(streamId);
    }

    public void clear() {
        stallStartTimes.clear();
    }
}
