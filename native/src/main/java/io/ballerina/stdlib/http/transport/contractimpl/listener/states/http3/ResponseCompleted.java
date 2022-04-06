package io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.Http3OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.incubator.codec.http3.Http3DataFrame;
import io.netty.incubator.codec.http3.Http3Exception;
import io.netty.incubator.codec.http3.Http3HeadersFrame;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ResponseCompleted  implements ListenerState{

    private static final Logger LOG = LoggerFactory.getLogger(io.ballerina.stdlib.http.transport.contractimpl.listener.states.http2.ResponseCompleted.class);

    private final Http3MessageStateContext http3MessageStateContext;
    private final ChannelHandlerContext ctx;
    private final long streamId;

    public ResponseCompleted(Http3OutboundRespListener http3OutboundRespListener, Http3MessageStateContext http3MessageStateContext, long streamId) {

        this.http3MessageStateContext = http3MessageStateContext;
        this.ctx = http3OutboundRespListener.getChannelHandlerContext();
//        this.encoder = http3OutboundRespListener.getEncoder();
        this.streamId = streamId;
    }

    @Override
    public void readInboundRequestHeaders(ChannelHandlerContext ctx, Http3HeadersFrame headersFrame, long streamId) throws Http3Exception {

    }

    @Override
    public void readInboundRequestBody(Http3SourceHandler http3SourceHandler, Http3DataFrame dataFrame, boolean isLast) throws Http3Exception {
//        releaseDataFrame(http3SourceHandler, dataFrame);
//        sendRsytFrame(ctx, encoder, streamId);
    }

    @Override
    public void writeOutboundResponseHeaders(Http3OutboundRespListener http3OutboundRespListener, HttpCarbonMessage outboundResponseMsg, HttpContent httpContent, long streamId) throws Http3Exception {

    }

    @Override
    public void writeOutboundResponseBody(Http3OutboundRespListener http3OutboundRespListener, HttpCarbonMessage outboundResponseMsg, HttpContent httpContent, long streamId) throws Http3Exception {
        http3MessageStateContext.setListenerState(
                new SendingHeaders(http3OutboundRespListener, http3MessageStateContext));
        http3MessageStateContext.getListenerState()
                .writeOutboundResponseHeaders(http3OutboundRespListener, outboundResponseMsg, httpContent, streamId);
    }

    @Override
    public void handleStreamTimeout(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx, Http3OutboundRespListener http3OutboundRespListener, long streamId) {

    }

    @Override
    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture) {

    }
}
