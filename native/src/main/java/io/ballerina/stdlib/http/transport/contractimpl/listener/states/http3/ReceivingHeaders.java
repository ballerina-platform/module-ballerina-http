package io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.Http3OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.InboundMessageHolder;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.incubator.codec.http3.Http3DataFrame;
import io.netty.incubator.codec.http3.Http3Exception;
import io.netty.incubator.codec.http3.Http3HeadersFrame;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3StateUtil.notifyRequestListener;
import static io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3StateUtil.setupHttp3CarbonRequest;

public class ReceivingHeaders implements ListenerState {

    private static final Logger LOG = LoggerFactory.getLogger(ReceivingHeaders.class);
    private final Http3SourceHandler http3SourceHandler;
    private final Http3MessageStateContext http3MessageStateContext;
    private final long streamId;


    public ReceivingHeaders(Http3SourceHandler http3SourceHandler, Http3MessageStateContext http3MessageStateContext,
                            long streamId) {
        this.http3SourceHandler = http3SourceHandler;
        this.http3MessageStateContext = http3MessageStateContext;
        this.streamId = streamId;
    }

    @Override
    public void readInboundRequestHeaders(ChannelHandlerContext ctx, Http3HeadersFrame headersFrame, long streamId)
            throws Http3Exception {

        HttpCarbonMessage sourceReqCMsg = setupHttp3CarbonMsg(headersFrame, streamId);
        sourceReqCMsg.setHttp3MessageStateContext(http3MessageStateContext);
        initializeDataEventListeners(ctx, streamId, sourceReqCMsg);
        http3MessageStateContext.setListenerState(new ReceivingEntityBody(http3MessageStateContext, streamId));
    }

    private HttpCarbonMessage setupHttp3CarbonMsg(Http3HeadersFrame headers, long streamId) throws Http3Exception {
        return setupHttp3CarbonRequest(Util.createHttpRequestFromHttp3Headers(headers, streamId), http3SourceHandler,
                streamId);
    }

    @Override
    public void readInboundRequestBody(Http3SourceHandler http3SourceHandler, Http3DataFrame dataFrame, boolean isLast)
            throws Http3Exception {
        LOG.warn("readInboundRequestBody is not a dependant action of this state");
    }

    @Override
    public void writeOutboundResponseHeaders(Http3OutboundRespListener http3OutboundRespListener, HttpCarbonMessage
            outboundResponseMsg, HttpContent httpContent, long streamId) throws Http3Exception {
        LOG.warn("writeOutboundResponseHeaders is not a dependant action of this state");
    }

    @Override
    public void writeOutboundResponseBody(Http3OutboundRespListener http3OutboundRespListener, HttpCarbonMessage
            outboundResponseMsg, HttpContent httpContent, long streamId) throws Http3Exception {
        LOG.warn("writeOutboundResponseBody is not a dependant action of this state");
    }

    @Override
    public void handleStreamTimeout(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                                    Http3OutboundRespListener http3OutboundRespListener, long streamId) {
        //Not yet Implemented
    }

    private void initializeDataEventListeners(ChannelHandlerContext ctx, long streamId,
                                              HttpCarbonMessage sourceReqCMsg) {
        InboundMessageHolder inboundMsgHolder = new InboundMessageHolder(sourceReqCMsg);
        http3SourceHandler.getStreamIdRequestMap().put(streamId, inboundMsgHolder);
        notifyRequestListener(http3SourceHandler, inboundMsgHolder, streamId);
    }

    @Override
    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture) {
        //Not yet Implemented
    }
}
