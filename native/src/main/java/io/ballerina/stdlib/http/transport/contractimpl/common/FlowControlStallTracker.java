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
import java.util.function.Supplier;

import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isStreamBlockedByFlowControl;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.isWithinBackPressureStallLimit;
import static io.ballerina.stdlib.http.transport.contractimpl.common.Util.ticksInNanos;

/**
 * Decides, on behalf of the HTTP/2 stream timeout handlers, whether the silence on a stream is down to flow
 * control rather than an unresponsive peer.
 *
 * <p>Both the client and the server ask the same question of their own connection, so the bookkeeping lives
 * here rather than twice over in the two timeout handlers.
 *
 * <p>A stream that is blocked right now is not the peer's fault. Neither is a stream that was blocked as
 * recently as the previous check: the window has only just reopened and the peer has not yet had a full idle
 * period in which to act. Without that second case a stream is failed whenever the timer happens to land in
 * the moment between the window opening and the next frame moving, which is a race a slow peer hits
 * regularly.
 *
 * <p>The reprieve is capped by the {@code maxBackPressureStallTime} configurable. The inbound case would
 * recover on its own, since it is our own application that reopens the window, but the outbound case would
 * not: a peer that has stopped reading never reopens our window, and without a cap it could pin a stream and
 * the response queued behind it indefinitely. Any progress on the stream restarts the span through
 * {@link #recordProgress(int)}, so a transfer that is merely slow never approaches the cap.
 */
public class FlowControlStallTracker {

    private static final Logger LOG = LoggerFactory.getLogger(FlowControlStallTracker.class);

    private final Supplier<Http2Connection> connectionSupplier;
    // Streams whose recent timeout checks found them held up by flow control, and when that started.
    private final Map<Integer, Long> stallStartTimes = new ConcurrentHashMap<>();

    public FlowControlStallTracker(Supplier<Http2Connection> connectionSupplier) {
        this.connectionSupplier = connectionSupplier;
    }

    /**
     * Whether the countdown on this stream should be restarted instead of the stream being failed.
     *
     * @param streamId the stream whose idle period has just elapsed
     * @return true if the silence is explained by flow control and the cap has not been reached
     */
    public boolean isStalledByFlowControl(int streamId) {
        Long stallStartTime = stallStartTimes.get(streamId);
        if (stallStartTime != null && !isWithinBackPressureStallLimit(stallStartTime)) {
            // The start time is deliberately left standing: until something actually moves on this stream,
            // every further period should time out rather than earn a fresh allowance.
            LOG.debug("Stream {} has been held up by flow control past the permitted stall time without any "
                              + "progress, letting the idle timeout run", streamId);
            return false;
        }
        if (isStreamBlockedByFlowControl(connectionSupplier.get(), streamId)) {
            stallStartTimes.putIfAbsent(streamId, ticksInNanos());
            return true;
        }
        if (stallStartTime != null) {
            // The window has only just reopened; give the peer one full period to act before failing it.
            stallStartTimes.remove(streamId);
            return true;
        }
        return false;
    }

    /**
     * Records that the stream has moved since the last check, which restarts its permitted stall time.
     *
     * @param streamId the stream that has made progress
     */
    public void recordProgress(int streamId) {
        stallStartTimes.remove(streamId);
    }

    /**
     * Forgets a stream that is no longer being timed.
     *
     * @param streamId the stream to forget
     */
    public void remove(int streamId) {
        stallStartTimes.remove(streamId);
    }

    /**
     * Forgets every stream, for when the owning connection goes away.
     */
    public void clear() {
        stallStartTimes.clear();
    }
}
