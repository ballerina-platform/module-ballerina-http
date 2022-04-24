package io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3;

import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.Http3OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http2.Http2Exception;
import io.netty.incubator.codec.http3.Http3DataFrame;
import io.netty.incubator.codec.http3.Http3Exception;
import io.netty.incubator.codec.http3.Http3HeadersFrame;

/**
 * Listener states of HTTP/3 source handler.
 */

public interface ListenerState {

    /**
     * Reads headers of inbound request.
     *
     * @param ctx          channel handler context
     * @param headersFrame inbound header frame
     * @throws Http3Exception if an error occurs while reading
     */

    void readInboundRequestHeaders(ChannelHandlerContext ctx, Http3HeadersFrame headersFrame, long streamId)
            throws Http3Exception;

    /**
     * Reads entity body of inbound request.
     *
     * @param http3SourceHandler HTTP3 source handler
     * @param dataFrame          inbound data frame
     * @throws Http3Exception if an error occurs while reading
     */
    void readInboundRequestBody(Http3SourceHandler http3SourceHandler, Http3DataFrame dataFrame, boolean isLast)
            throws Http3Exception;

    /**
     * Writes headers of outbound response.
     *
     * @param http3OutboundRespListener outbound response listener of response future
     * @param outboundResponseMsg       outbound response message
     * @param httpContent               the initial content of the entity body
     * @param streamId                  the current stream id
     * @throws Http3Exception if an error occurs while writing
     */
    void writeOutboundResponseHeaders(Http3OutboundRespListener http3OutboundRespListener,
                                      HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                      long streamId) throws Http3Exception;

    /**
     * Writes entity body of outbound response.
     *
     * @param http3OutboundRespListener outbound response listener of response future
     * @param outboundResponseMsg       outbound response message
     * @param httpContent               the content of the entity body
     * @param streamId                  the current stream id
     * @throws Http3Exception if an error occurs while writing
     */

    void writeOutboundResponseBody(Http3OutboundRespListener http3OutboundRespListener,
                                   HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                   long streamId) throws Http3Exception;


    //Not yet Implemented
    void handleStreamTimeout(ServerConnectorFuture serverConnectorFuture, ChannelHandlerContext ctx,
                             Http3OutboundRespListener http3OutboundRespListener, long streamId);

    //Not yet Implemented
    void handleAbruptChannelClosure(ServerConnectorFuture serverConnectorFuture);
}
