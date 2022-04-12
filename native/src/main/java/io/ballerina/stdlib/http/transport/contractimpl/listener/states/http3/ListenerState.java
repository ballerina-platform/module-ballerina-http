package io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.Http3OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.incubator.codec.http3.Http3DataFrame;
import io.netty.incubator.codec.http3.Http3Exception;
import io.netty.incubator.codec.http3.Http3HeadersFrame;

public interface ListenerState {

    void readInboundRequestHeaders(ChannelHandlerContext ctx, Http3HeadersFrame headersFrame,long streamId) throws Http3Exception;
    void readInboundRequestBody(Http3SourceHandler http3SourceHandler, Http3DataFrame dataFrame,boolean isLast) throws Http3Exception;
    void writeOutboundResponseHeaders(Http3OutboundRespListener http3OutboundRespListener,
                                      HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                      long streamId) throws Http3Exception;


    void writeOutboundResponseBody(Http3OutboundRespListener http3OutboundRespListener,
                                   HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                   long streamId) throws Http3Exception;

    void handleStreamTimeout(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                             Http3OutboundRespListener http3OutboundRespListener, long streamId);

    void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture);

}
