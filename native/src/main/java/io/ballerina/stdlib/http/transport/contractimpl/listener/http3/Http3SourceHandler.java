package io.ballerina.stdlib.http.transport.contractimpl.listener.http3;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.listener.Http3ServerChannelInitializer;
import io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3.ReceivingHeaders;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.incubator.codec.http3.Http3DataFrame;
import io.netty.incubator.codec.http3.Http3HeadersFrame;
import io.netty.incubator.codec.http3.Http3RequestStreamInboundHandler;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.Map;

public class Http3SourceHandler extends Http3RequestStreamInboundHandler {
    private final long streamId;
    private final String serverName;
    private boolean connectedState;
    private Http3ServerChannel http3ServerChannel = new Http3ServerChannel();
    private ServerConnectorFuture serverConnectorFuture;
    private Http3ServerChannelInitializer http3serverChannelInitializer;
    private ChannelHandlerContext ctx;
    private String interfaceId;
    private SocketAddress remoteAddress;
    private String remoteHost;


    public Http3SourceHandler(long streamId, ServerConnectorFuture serverConnectorFuture, String interfaceId, String serverName) {
        this.interfaceId = interfaceId;
        this.serverConnectorFuture = serverConnectorFuture;
        this.streamId = streamId;
        this.serverName = serverName;
    }


    @Override
    protected void channelRead(ChannelHandlerContext channelHandlerContext, Http3HeadersFrame http3HeadersFrame,
                               boolean isLast) throws Exception {
        Http3MessageStateContext http3MessageStateContext = new Http3MessageStateContext();
        http3MessageStateContext.setListenerState(new ReceivingHeaders(this, http3MessageStateContext,
                streamId));
        http3MessageStateContext.getListenerState().readInboundRequestHeaders(channelHandlerContext, http3HeadersFrame,
                streamId);
    }

    @Override
    protected void channelRead(ChannelHandlerContext channelHandlerContext, Http3DataFrame http3DataFrame,
                               boolean isLast) throws Exception {
        HttpCarbonMessage sourceReqCMsg = null;

        InboundMessageHolder inboundMessageHolder = http3ServerChannel.getInboundMessage(streamId);
        if (inboundMessageHolder != null) {
            sourceReqCMsg = inboundMessageHolder.getInboundMsg();
        }
        sourceReqCMsg.getHttp3MessageStateContext().getListenerState().readInboundRequestBody(this,
                http3DataFrame, isLast);
    }

    @Override
    public void channelActive(ChannelHandlerContext ctx) {
    }

    @Override
    public void handlerAdded(ChannelHandlerContext ctx) throws Exception {
        super.handlerAdded(ctx);
        this.ctx = ctx;
        this.remoteAddress = ctx.channel().remoteAddress();
        if (this.remoteAddress instanceof InetSocketAddress) {
            remoteHost = ((InetSocketAddress) this.remoteAddress).getAddress().toString();
            if (remoteHost.startsWith("/")) {
                remoteHost = remoteHost.substring(1);
            }
        }
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) {
        http3ServerChannel.destroy();
        ctx.fireChannelInactive();
    }

    public Map<Long, InboundMessageHolder> getStreamIdRequestMap() {
        return http3ServerChannel.getStreamIdRequestMap();
    }

    public ServerConnectorFuture getServerConnectorFuture() {
        return serverConnectorFuture;
    }

    public Http3ServerChannel getHttp3ServerChannel() {
        return http3ServerChannel;
    }

    public Http3ServerChannelInitializer getHttp3ServerChannelInitializer() {
        return http3serverChannelInitializer;
    }

    public ChannelHandlerContext getChannelHandlerContext() {
        return ctx;
    }

    public void setConnectedState(boolean connectedState) {
        this.connectedState = connectedState;
    }

    public SocketAddress getRemoteAddress() {
        return remoteAddress;
    }

    public String getInterfaceId() {
        return interfaceId;
    }

    public String getRemoteHost() {
        return remoteHost;
    }
    public String getServerName() {
        return serverName;
    }


}
