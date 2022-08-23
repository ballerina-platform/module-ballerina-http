package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contract.ImmediateStopFuture;
import io.ballerina.stdlib.http.transport.contract.ServerConnector;

public class HTTPImmediateStopFuture implements ImmediateStopFuture {

    ServerConnector httpServerConnector;

    public HTTPImmediateStopFuture(ServerConnector httpServerConnector) {
        this.httpServerConnector = httpServerConnector;
    }

    @Override
    public void Stop() {
        this.httpServerConnector.immediateStop();
    }
}
