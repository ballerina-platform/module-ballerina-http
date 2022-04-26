package io.ballerina.stdlib.http.transport.contractimpl.listener.http3;

import io.netty.util.internal.PlatformDependent;

import java.util.Map;

public class Http3ServerChannel {

    private Map<Long, InboundMessageHolder> streamIdRequestMap = PlatformDependent.newConcurrentHashMap();

    void destroy() {
        streamIdRequestMap.clear();
    }

    public Map<Long, InboundMessageHolder> getStreamIdRequestMap() {
        return streamIdRequestMap;
    }

    InboundMessageHolder getInboundMessage(long streamId) {
        return streamIdRequestMap.get(streamId);
    }
}
