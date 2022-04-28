package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.incubator.codec.http3.Http3ServerConnectionHandler;
import io.netty.incubator.codec.quic.QuicChannel;

public class Http3ServerChannelInitializer extends ChannelInitializer<QuicChannel> {


    private String interfaceId;
    private ServerConnectorFuture serverConnectorFuture;
    private String serverName;

    @Override
    protected void initChannel(QuicChannel ch) {

        ChannelPipeline serverPipeline = ch.pipeline();
        serverPipeline.addLast(new Http3ServerConnectionHandler(new Http3QuicStreamInitializer
                (interfaceId, serverConnectorFuture, serverName, this)));
    }


    void setInterfaceId(String interfaceId) {
        this.interfaceId = interfaceId;
    }

    void setServerConnectorFuture(ServerConnectorFuture serverConnectorFuture) {
        this.serverConnectorFuture = serverConnectorFuture;

    }

    void setServerName(String serverName) {
        this.serverName = serverName;
    }
}

