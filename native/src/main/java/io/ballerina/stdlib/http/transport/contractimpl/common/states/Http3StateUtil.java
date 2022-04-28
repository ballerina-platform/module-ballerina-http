package io.ballerina.stdlib.http.transport.contractimpl.common.states;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contractimpl.Http3OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.InboundMessageHolder;
import io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3.SendingHeaders;
import io.ballerina.stdlib.http.transport.message.Http3InboundContentListener;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpCarbonRequest;
import io.ballerina.stdlib.http.transport.message.PooledDataStreamerFactory;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.*;
import io.netty.incubator.codec.http3.*;
import io.netty.util.AsciiString;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetSocketAddress;
import java.util.List;
import java.util.Map;

import static io.ballerina.stdlib.http.transport.contract.Constants.*;

public class Http3StateUtil {

    private static final Logger LOG = LoggerFactory.getLogger(Http3StateUtil.class);
    private static final Http3HeadersFrame headersFrame = new DefaultHttp3HeadersFrame();
    private static final AsciiString EMPTY_REQUEST_PATH = AsciiString.cached("/");

    public static void notifyRequestListener(Http3SourceHandler http3SourceHandler,
                                             InboundMessageHolder inboundMessageHolder, long streamId) {
        HttpCarbonMessage httpRequestMsg = inboundMessageHolder.getInboundMsg();
        if (http3SourceHandler.getServerConnectorFuture() != null) {
            try {
                ServerConnectorFuture outboundRespFuture = httpRequestMsg.getHttpResponseFuture();
                Http3OutboundRespListener http3OutboundRespListener = new Http3OutboundRespListener(
                        http3SourceHandler.getHttp3ServerChannelInitializer(), httpRequestMsg,
                        http3SourceHandler.getChannelHandlerContext(), http3SourceHandler.getServerName(),
                        http3SourceHandler.getRemoteHost(), streamId,
                        http3SourceHandler.getHttp3ServerChannel());
                outboundRespFuture.setHttpConnectorListener(http3OutboundRespListener);
                http3SourceHandler.getServerConnectorFuture().notifyHttpListener(httpRequestMsg);
                inboundMessageHolder.setHttp3OutboundRespListener(http3OutboundRespListener);
            } catch (Exception e) {
                LOG.error("Error while notifying listeners", e);
            }
        } else {
            LOG.error("Cannot find registered listener to forward the message");
        }
    }

    /**
     * Creates a {@code HttpCarbonRequest} from HttpRequest.
     *
     * @param httpRequest        the HTTPRequest message
     * @param http3SourceHandler the HTTP/3 source handler
     * @param streamId           the stream id
     * @return the CarbonRequest Message created from given HttpRequest
     */
    public static HttpCarbonRequest setupHttp3CarbonRequest(HttpRequest httpRequest,
                                                            Http3SourceHandler http3SourceHandler, long streamId) {
        ChannelHandlerContext ctx = http3SourceHandler.getChannelHandlerContext();
        HttpCarbonRequest sourceReqCMsg = new HttpCarbonRequest(httpRequest, new Http3InboundContentListener(
                streamId, ctx, INBOUND_REQUEST));

        sourceReqCMsg.setProperty(POOLED_BYTE_BUFFER_FACTORY, new PooledDataStreamerFactory(ctx.alloc()));
        sourceReqCMsg.setProperty(CHNL_HNDLR_CTX, ctx);
        sourceReqCMsg.setProperty(Constants.SRC_HANDLER, http3SourceHandler);
        HttpVersion protocolVersion = httpRequest.protocolVersion();
        sourceReqCMsg.setHttpVersion(protocolVersion.majorVersion() + "." + protocolVersion.minorVersion());
        sourceReqCMsg.setHttpMethod(httpRequest.method().name());

        InetSocketAddress localAddress = null;
        //This check was added because in case of netty embedded channel, this could be of type 'EmbeddedSocketAddress'.
        if (ctx.channel().localAddress() instanceof InetSocketAddress) {
            localAddress = (InetSocketAddress) ctx.channel().localAddress();
        }
        sourceReqCMsg.setProperty(LOCAL_ADDRESS, localAddress);
        sourceReqCMsg.setProperty(Constants.REMOTE_ADDRESS, http3SourceHandler.getRemoteAddress());
        sourceReqCMsg.setProperty(LISTENER_PORT, localAddress != null ? localAddress.getPort() : null);
        sourceReqCMsg.setProperty(LISTENER_INTERFACE_ID, http3SourceHandler.getInterfaceId());
        sourceReqCMsg.setProperty(PROTOCOL, HTTPS_SCHEME);
        String uri = httpRequest.uri();
        sourceReqCMsg.setRequestUrl(uri);
        sourceReqCMsg.setProperty(TO, uri);
        return sourceReqCMsg;
    }

    public static void beginResponseWrite(Http3MessageStateContext http3MessageStateContext,
                                          Http3OutboundRespListener http3OutboundRespListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                          long streamId) throws Http3Exception {
        http3MessageStateContext.setListenerState(
                new SendingHeaders(http3OutboundRespListener, http3MessageStateContext));
        http3MessageStateContext.getListenerState()
                .writeOutboundResponseHeaders(http3OutboundRespListener, outboundResponseMsg, httpContent, streamId);
    }

    public static Http3HeadersFrame toHttp3Headers(HttpMessage httpMessage, boolean validateHeaders) {

        HttpHeaders incomingHeaders = httpMessage.headers();
        final Http3Headers outgoingHeaders = new DefaultHttp3Headers(validateHeaders, incomingHeaders.size());
        if (httpMessage instanceof HttpResponse) {
            HttpResponse response = (HttpResponse) httpMessage;
            outgoingHeaders.status(response.status().codeAsText());

            List<Map.Entry<String, String>> httpHeaders = httpMessage.headers().entries();
            for (Map.Entry<String, String> httpHeader : httpHeaders) {
                outgoingHeaders.add(httpHeader.getKey(), httpHeader.getValue());
            }
        }
        final Http3HeadersFrame headers = new DefaultHttp3HeadersFrame(outgoingHeaders);
        return headers;
    }

}
