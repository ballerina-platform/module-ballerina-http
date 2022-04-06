package io.ballerina.stdlib.http.transport.contractimpl.listener;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.config.ChunkConfig;
import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.ssl.SSLConfig;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.group.ChannelGroup;
import io.netty.incubator.codec.http3.Http3ServerConnectionHandler;
import io.netty.incubator.codec.quic.QuicChannel;
import io.netty.incubator.codec.quic.QuicStreamChannel;
import io.netty.util.concurrent.EventExecutorGroup;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Http3ServerChannelInitializer extends ChannelInitializer<QuicChannel> {

    private static final Logger LOG = LoggerFactory.getLogger(Http3ServerChannelInitializer.class);


    private ChannelGroup allChannels;
    private SSLConfig sslConfig;
    private long socketIdleTimeout;
    private KeepAliveConfig keepAliveConfig;
    private ChunkConfig chunkConfig;
    private boolean httpAccessLogEnabled;
    private boolean httpTraceLogEnabled;
    private EventExecutorGroup pipeliningGroup;
    private String interfaceId;
    private ServerConnectorFuture serverConnectorFuture;

    @Override
    protected void initChannel(QuicChannel ch) {

        ChannelPipeline serverPipeline = ch.pipeline();
        serverPipeline.addLast(new Http3ServerConnectionHandler(new Http3QuicStreamInitializer(interfaceId,serverConnectorFuture,this)));


    }

     void setAllChannels(ChannelGroup allChannels) {
        this.allChannels = allChannels;
    }

     void setSslConfig(SSLConfig sslConfig) {
        this.sslConfig = sslConfig;
    }


     void setIdleTimeout(long socketIdleTimeout) {
        this.socketIdleTimeout = socketIdleTimeout;
    }
     long getSocketIdleTimeout() {
        return socketIdleTimeout;
    }


     void setHttp3TraceLogEnabled(boolean httpTraceLogEnabled) {
        this.httpTraceLogEnabled = httpTraceLogEnabled;
    }

     void setHttp3AccessLogEnabled(boolean isHttpAccessLogEnabled) {
        this.httpAccessLogEnabled = isHttpAccessLogEnabled;

    }

     void setChunkingConfig(ChunkConfig chunkConfig) {
        this.chunkConfig = chunkConfig;

    }

     void setKeepAliveConfig(KeepAliveConfig keepAliveConfig) {
        this.keepAliveConfig = keepAliveConfig;
    }

     void setPipeliningThreadGroup(EventExecutorGroup pipeliningGroup) {
        this.pipeliningGroup = pipeliningGroup;
    }

     void setInterfaceId(String interfaceId) {
         this.interfaceId = interfaceId;
     }

     void setServerConnectorFuture(ServerConnectorFuture serverConnectorFuture) {
         this.serverConnectorFuture = serverConnectorFuture;

     }

    public boolean isHttpAccessLogEnabled() {
        return httpAccessLogEnabled;
    }
}

