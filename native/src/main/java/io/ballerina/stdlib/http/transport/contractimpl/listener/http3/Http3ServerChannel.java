package io.ballerina.stdlib.http.transport.contractimpl.listener.http3;

import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.InboundMessageHolder;
import io.ballerina.stdlib.http.transport.contractimpl.sender.http3.Http3DataEventListener;
import io.netty.util.internal.PlatformDependent;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Http3ServerChannel {


    // streamIdRequestMap contains the mapping of http carbon messages vs stream id to support multiplexing
    private Map<Long, InboundMessageHolder> streamIdRequestMap = PlatformDependent.newConcurrentHashMap();
    private Map<String, Http3DataEventListener> dataEventListeners;

    Http3ServerChannel() {
        dataEventListeners = new HashMap<>();
    }

    void destroy() {
        streamIdRequestMap.clear();
    }

    public Map<Long, InboundMessageHolder> getStreamIdRequestMap() {
        return streamIdRequestMap;
    }

    InboundMessageHolder getInboundMessage(long streamId) {
        return streamIdRequestMap.get(streamId);
    }

    /**
     * Adds a listener which listen for HTTP/2 data events.
     *
     * @param name              name of the listener
     * @param dataEventListener the data event listener
     */
    void addDataEventListener(String name, Http3DataEventListener dataEventListener) {
        dataEventListeners.put(name, dataEventListener);
    }

    /**
     * Gets the list of listeners which listen for HTTP/2 data events.
     *
     * @return list of data event listeners
     */
    public List<Http3DataEventListener> getDataEventListeners() {
        return new ArrayList<>(dataEventListeners.values());
    }

}
