package io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.Http3OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3StateUtil;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.incubator.codec.http3.Http3DataFrame;
import io.netty.incubator.codec.http3.Http3Exception;
import io.netty.incubator.codec.http3.Http3HeadersFrame;

public class EntityBodyReceived implements ListenerState {
    private final Http3MessageStateContext http3MessageStateContext;

    public EntityBodyReceived(Http3MessageStateContext http3MessageStateContext) {
        this.http3MessageStateContext = http3MessageStateContext;

    }

    @Override
    public void readInboundRequestHeaders(ChannelHandlerContext ctx, Http3HeadersFrame headersFrame, long streamId)  {

    }

    @Override
    public void readInboundRequestBody(Http3SourceHandler http3SourceHandler, Http3DataFrame dataFrame, boolean isLast){

    }

    @Override
    public void writeOutboundResponseHeaders(Http3OutboundRespListener http3OutboundRespListener,
                                             HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                             long streamId) throws Http3Exception {

    }

    @Override
    public void writeOutboundResponseBody(Http3OutboundRespListener http3OutboundRespListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                          long streamId) throws Http3Exception {
        if (http3MessageStateContext.isHeadersSent()) {
            // response header already sent. move the state to SendingEntityBody.
            http3MessageStateContext.setListenerState(
                    new SendingEntityBody(http3OutboundRespListener, http3MessageStateContext, streamId));
            http3MessageStateContext.getListenerState()
                    .writeOutboundResponseBody(http3OutboundRespListener, outboundResponseMsg, httpContent, streamId);
        } else {
            Http3StateUtil.beginResponseWrite(http3MessageStateContext, http3OutboundRespListener,
                    outboundResponseMsg, httpContent, streamId);
        }
    }//done upto this

    @Override
    public void handleStreamTimeout(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                                    Http3OutboundRespListener http3OutboundRespListener, long streamId) {

    }

    @Override
    public void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture) {

    }
}
