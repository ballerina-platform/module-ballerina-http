package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.incubator.codec.quic.QuicStreamChannel;

/**
 * A class that responsible for build server side quic streams.
 */
public class Http3QuicStreamInitializer extends ChannelInitializer<QuicStreamChannel> {
    private final Http3ServerChannelInitializer http3ServerChannelInitializer;
    private final String interfaceId;
    private final ServerConnectorFuture serverConnectorFuture;
    private final String serverName;

    public Http3QuicStreamInitializer(String interfaceId, ServerConnectorFuture serverConnectorFuture,
                                      String serverName, Http3ServerChannelInitializer http3ServerChannelInitializer) {
        this.http3ServerChannelInitializer = http3ServerChannelInitializer;
        this.interfaceId = interfaceId;
        this.serverConnectorFuture = serverConnectorFuture;
        this.serverName = serverName;
    }

    @Override
    protected void initChannel(QuicStreamChannel ch) throws Exception {
        ChannelPipeline serverPipeline = ch.pipeline();
        configureHttpPipeline(serverPipeline, ch.streamId(), interfaceId, serverConnectorFuture);
    }

    private void configureHttpPipeline(ChannelPipeline serverPipeline, long streamId, String interfaceId,
                                       ServerConnectorFuture serverConnectorFuture) {
        serverPipeline.addLast(new Http3SourceHandler(streamId, serverConnectorFuture, interfaceId, serverName,
                http3ServerChannelInitializer));
    }


}
