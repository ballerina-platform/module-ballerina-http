package io.ballerina.stdlib.http.transport.contractimpl.common.states;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.ServerConnectorFuture;
import io.ballerina.stdlib.http.transport.contract.exceptions.ServerConnectorException;
import io.ballerina.stdlib.http.transport.contractimpl.Http3OutboundRespListener;
import io.ballerina.stdlib.http.transport.contractimpl.common.Util;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3SourceHandler;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.InboundMessageHolder;
import io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3.Response100ContinueSent;
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
import java.net.URI;

import static io.ballerina.stdlib.http.transport.contract.Constants.*;
import static io.netty.handler.codec.http.HttpScheme.HTTP;
import static io.netty.handler.codec.http.HttpScheme.HTTPS;
import static io.netty.handler.codec.http.HttpUtil.isAsteriskForm;
import static io.netty.handler.codec.http.HttpUtil.isOriginForm;
import static io.netty.util.AsciiString.EMPTY_STRING;
import static io.netty.util.internal.StringUtil.isNullOrEmpty;
import static io.netty.util.internal.StringUtil.length;

public class Http3StateUtil {

    private static final Logger LOG = LoggerFactory.getLogger(Http3StateUtil.class);
    private static Http3HeadersFrame headersFrame = new DefaultHttp3HeadersFrame();
    private static final AsciiString EMPTY_REQUEST_PATH = AsciiString.cached("/");

    public static void notifyRequestListener(Http3SourceHandler http3SourceHandler,
                                             InboundMessageHolder inboundMessageHolder, long streamId) {
        HttpCarbonMessage httpRequestMsg = inboundMessageHolder.getInboundMsg();
        if (http3SourceHandler.getServerConnectorFuture() != null) {
            try {
                ServerConnectorFuture outboundRespFuture = httpRequestMsg.getHttpResponseFuture();
                Http3OutboundRespListener http3OutboundRespListener = new Http3OutboundRespListener(
                        http3SourceHandler.getHttp3ServerChannelInitializer(), httpRequestMsg,
                        http3SourceHandler.getChannelHandlerContext(),
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
//        HttpCarbonRequest sourceReqCMsg = new HttpCarbonRequest(httpRequest, new DefaultListener(ctx));
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
        sourceReqCMsg.setProperty(MUTUAL_SSL_HANDSHAKE_RESULT,
                ctx.channel().attr(Constants.MUTUAL_SSL_RESULT_ATTRIBUTE).get());
        sourceReqCMsg.setProperty(BASE_64_ENCODED_CERT,
                ctx.channel().attr(Constants.BASE_64_ENCODED_CERT_ATTRIBUTE).get());
        String uri = httpRequest.uri();
        sourceReqCMsg.setRequestUrl(uri);
        sourceReqCMsg.setProperty(TO, uri);
        return sourceReqCMsg;

    }

    public static Http3HeadersFrame createResponseHeaders() {
//        headersFrame.headers().status("200");
//        headersFrame.headers().add("server", "serverName");
        return headersFrame;
    }

    public static void writeResponse(ChannelHandlerContext ctx) {
//        byte[] msg = new byte[content.readableBytes()];
//        final byte[] CONTENT = "Received\r\n".getBytes(CharsetUtil.US_ASCII);
//        headersFrame.headers().addInt("content-length", msg.length);
//        ctx.write(headersFrame);
//        ctx.writeAndFlush(new DefaultHttp3DataFrame(
//                        Unpooled.wrappedBuffer(CONTENT)))
//                .addListener(QuicStreamChannel.SHUTDOWN_OUTPUT);
//        ReferenceCountUtil.release(headersFrame);

    }

    public static void beginResponseWrite(Http3MessageStateContext http3MessageStateContext,
                                          Http3OutboundRespListener http3OutboundRespListener,
                                          HttpCarbonMessage outboundResponseMsg, HttpContent httpContent,
                                          long streamId) throws Http3Exception {
        if (Util.getHttpResponseStatus(outboundResponseMsg).code() == HttpResponseStatus.CONTINUE.code()) {
            http3MessageStateContext.setListenerState(new Response100ContinueSent(http3MessageStateContext, streamId));
            http3MessageStateContext.getListenerState()
                    .writeOutboundResponseBody(http3OutboundRespListener, outboundResponseMsg, httpContent,
                            streamId);
        } else {
            // When the initial frames of the response is to be sent.
            http3MessageStateContext.setListenerState(
                    new SendingHeaders(http3OutboundRespListener, http3MessageStateContext));
            http3MessageStateContext.getListenerState()
                    .writeOutboundResponseHeaders(http3OutboundRespListener, outboundResponseMsg, httpContent,
                            streamId);
        }
    }

    public static void validatePromisedStreamState(long originalStreamId, long streamId,
                                                   HttpCarbonMessage inboundRequestMsg) throws Http3Exception {
        if (streamId == originalStreamId) { // Not a promised stream, no need to validate
            return;
        }
//        if (!isValidStreamId(streamId, conn)) {
        inboundRequestMsg.getHttpOutboundRespStatusFuture().
                notifyHttpListener(new ServerConnectorException(PROMISED_STREAM_REJECTED_ERROR));
//            throw new Http3Exception(Http3ErrorCode.REFUSED_STREAM, PROMISED_STREAM_REJECTED_ERROR);
//        }
    }


    //FROM NETTY
    public static Http3HeadersFrame toHttp3Headers(HttpMessage httpMessage, boolean validateHeaders) {
        HttpHeaders inHeaders = httpMessage.headers();
        final Http3Headers out = new DefaultHttp3Headers(validateHeaders, inHeaders.size());
        if (httpMessage instanceof HttpRequest) {
            HttpRequest request = (HttpRequest) httpMessage;
            URI requestTargetUri = URI.create(request.uri());
            out.path(toHttp3Path(requestTargetUri));
            out.method(request.method().asciiName());
            setHttp3Scheme(inHeaders, requestTargetUri, out);

            if (!isOriginForm(requestTargetUri) && !isAsteriskForm(requestTargetUri)) {
                // Attempt to take from HOST header before taking from the request-line
                String host = inHeaders.getAsString(HttpHeaderNames.HOST);
                setHttp3Authority((host == null || host.isEmpty()) ? requestTargetUri.getAuthority() : host, out);
            }
        } else if (httpMessage instanceof HttpResponse) {
            HttpResponse response = (HttpResponse) httpMessage;
            out.status(response.status().codeAsText());
        }

        // Add the HTTP headers which have not been consumed above
//        toHttp3Headers(inHeaders, out);
        final Http3HeadersFrame headers = new DefaultHttp3HeadersFrame(out);
        return headers;
    }

    private static AsciiString toHttp3Path(URI uri) {
        StringBuilder pathBuilder = new StringBuilder(length(uri.getRawPath()) +
                length(uri.getRawQuery()) + length(uri.getRawFragment()) + 2);
        if (!isNullOrEmpty(uri.getRawPath())) {
            pathBuilder.append(uri.getRawPath());
        }
        if (!isNullOrEmpty(uri.getRawQuery())) {
            pathBuilder.append('?');
            pathBuilder.append(uri.getRawQuery());
        }
        if (!isNullOrEmpty(uri.getRawFragment())) {
            pathBuilder.append('#');
            pathBuilder.append(uri.getRawFragment());
        }
        String path = pathBuilder.toString();
        return path.isEmpty() ? EMPTY_REQUEST_PATH : new AsciiString(path);
    }

    static void setHttp3Authority(String authority, Http3Headers out) {
        // The authority MUST NOT include the deprecated "userinfo" subcomponent
        if (authority != null) {
            if (authority.isEmpty()) {
                out.authority(EMPTY_STRING);
            } else {
                int start = authority.indexOf('@') + 1;
                int length = authority.length() - start;
                if (length == 0) {
                    throw new IllegalArgumentException("authority: " + authority);
                }
                out.authority(new AsciiString(authority, start, length));
            }
        }
    }

    private static void setHttp3Scheme(HttpHeaders in, URI uri, Http3Headers out) {
        String value = uri.getScheme();
        if (value != null) {
            out.scheme(new AsciiString(value));
            return;
        }

        // Consume the Scheme extension header if present
        CharSequence cValue = in.get(HttpConversionUtil.ExtensionHeaderNames.SCHEME.text());
        if (cValue != null) {
            out.scheme(AsciiString.of(cValue));
            return;
        }

        if (uri.getPort() == HTTPS.port()) {
            out.scheme(HTTPS.name());
        } else if (uri.getPort() == HTTP.port()) {
            out.scheme(HTTP.name());
        } else {
            throw new IllegalArgumentException(":scheme must be specified. " +
                    "see https://quicwg.org/base-drafts/draft-ietf-quic-http.html#section-4.1.1.1");
        }
    }

}
