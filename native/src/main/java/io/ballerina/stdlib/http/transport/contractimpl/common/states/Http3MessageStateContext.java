package io.ballerina.stdlib.http.transport.contractimpl.common.states;

import io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3.ListenerState;

/**
 * Context class to handle the current state of the HTTP/3 message.
 *
 */

public class Http3MessageStateContext {

    private ListenerState listenerState;
    private boolean headersSent;

    public void setListenerState(ListenerState state) {
        this.listenerState = state;
    }

    public void setHeadersSent(boolean headersSent) {
        this.headersSent = headersSent;
    }

    /**
     * Get the given listener state from the context.
     *
     * @return the current state which represents the flow of packets receiving
     */
    public ListenerState getListenerState() {
        return listenerState;
    }

    public boolean isHeadersSent() {
        return headersSent;
    }
}
