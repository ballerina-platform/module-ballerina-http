package io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3;


import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.Http3OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpContent;
import io.netty.incubator.codec.http3.Http3DataFrame;
import io.netty.incubator.codec.http3.Http3Exception;
import io.netty.incubator.codec.http3.Http3HeadersFrame;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ReceivingEntityBody implements ListenerState {
    private static final Logger LOG = LoggerFactory.getLogger(ReceivingEntityBody.class);
    private final Http3MessageStateContext http3MessageStateContext;
    private final long streamId;

    public ReceivingEntityBody(Http3MessageStateContext http3MessageStateContext, long streamId) {
        this.http3MessageStateContext = http3MessageStateContext;
        this.streamId = streamId;
    }

    @Override
    public void readInboundRequestHeaders(ChannelHandlerContext ctx, Http3HeadersFrame headersFrame, long streamId) {
        LOG.warn("readInboundRequestHeaders is not a dependant action of this state");

    }

    @Override
    public void readInboundRequestBody(Http3SourceHandler http3SourceHandler, Http3DataFrame dataFrame, boolean isLast)
            throws Http3Exception {

        ByteBuf data = dataFrame.content();
        if (data != null) {
            HttpCarbonMessage sourceReqCMsg = http3SourceHandler.getStreamIdRequestMap().get(streamId).getInboundMsg();
            if (sourceReqCMsg != null) {
                if (isLast) {
                    sourceReqCMsg.addHttpContent(new DefaultLastHttpContent(data));
                    sourceReqCMsg.setLastHttpContentArrived();
                    http3MessageStateContext.setListenerState(new EntityBodyReceived(http3MessageStateContext));
                } else {
                    sourceReqCMsg.addHttpContent(new DefaultHttpContent(data));
                }
            } else {
                LOG.warn("Inconsistent state detected : data has been received before headers");
            }
        } else {
            http3MessageStateContext.setListenerState(new EntityBodyReceived(http3MessageStateContext));
        }
    }

    @Override
    public void writeOutboundResponseHeaders(Http3OutboundRespListener http3OutboundRespListener,
                                             HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                             long streamId) throws Http3Exception {
        LOG.warn("writeOutboundResponseHeaders is not a dependant action of this state");
    }


    @Override
    public void writeOutboundResponseBody(Http3OutboundRespListener http3OutboundRespListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                          long streamId) throws Http3Exception {
        LOG.warn("writeOutboundResponseBody is not a dependant action of this state");
    }


    @Override
    public void handleStreamTimeout(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                                    Http3OutboundRespListener http3OutboundRespListener, long streamId) {
        //Not yet Implemented
    }

    @Override
    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture) {
        //Not yet Implemented
    }
}
