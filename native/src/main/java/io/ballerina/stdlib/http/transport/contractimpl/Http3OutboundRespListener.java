package io.ballerina.stdlib.http.transport.contractimpl;

import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.listener.Http3ServerChannelInitializer;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3ServerChannel;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.incubator.codec.http3.Http3Exception;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Calendar;

import static io.ballerina.stdlib.http.transport.contract.Constants.ENCODING_DEFLATE;
import static io.ballerina.stdlib.http.transport.contract.Constants.ENCODING_GZIP;

/**
 * Responsible for listening for outbound response messages and delivering them to the client.
 */

public class Http3OutboundRespListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(Http3OutboundRespListener.class);

    private final Http3ServerChannelInitializer http3ServerChannelInitializer;
    private final ChannelHandlerContext channelHandlerContext;
    private final Http3ServerChannel http3ServerChannel;
    private final long streamId;
    private final Http3MessageStateContext http3MessageStateContext;
    private final HttpCarbonMessage inboundRequestMsg;

    private final String serverName;
    private HttpCarbonMessage outboundResponseMsg;
    private final Calendar inboundRequestArrivalTime;

    public Http3OutboundRespListener(Http3ServerChannelInitializer http3ServerChannelInitializer,
                                     HttpCarbonMessage httpRequestMsg, ChannelHandlerContext channelHandlerContext,
                                     String serverName, String remoteHost, long streamId,
                                     Http3ServerChannel http3ServerChannel) {
        this.http3ServerChannelInitializer = http3ServerChannelInitializer;
        this.channelHandlerContext = channelHandlerContext;
        this.streamId = streamId;
        this.serverName = serverName;
        this.http3ServerChannel = http3ServerChannel;
        this.inboundRequestMsg = httpRequestMsg;
        http3MessageStateContext = httpRequestMsg.getHttp3MessageStateContext();
        inboundRequestArrivalTime = Calendar.getInstance();
    }

    @Override
    public void onMessage(HttpCarbonMessage outboundResponseMsg) {
        this.outboundResponseMsg = outboundResponseMsg;
        writeMessage(outboundResponseMsg, streamId);
    }

    @Override
    public void onError(Throwable throwable) {
        LOG.error("Couldn't send the outbound response", throwable);
    }

    public Calendar getInboundRequestArrivalTime() {
        return inboundRequestArrivalTime;
    }

    @Override
    public void onPushPromise(Http2PushPromise pushPromise) {
        HttpConnectorListener.super.onPushPromise(pushPromise);
    }

    @Override
    public void onPushResponse(int promiseId, HttpCarbonMessage httpMessage) {
        HttpConnectorListener.super.onPushResponse(promiseId, httpMessage);
    }

    public String getRemoteAddress() {
        String remoteAddress = "-";
        return remoteAddress;
    }


    private void writeMessage(HttpCarbonMessage outboundResponseMsg, long streamId) {
        ResponseWriter writer = new ResponseWriter(streamId);

        setContentEncoding(outboundResponseMsg);
        outboundResponseMsg.getHttpContentAsync().setMessageListener(httpContent -> {
            channelHandlerContext.channel().eventLoop().execute(() -> {
                try {
                    writer.writeOutboundResponse(outboundResponseMsg, httpContent);
                } catch (Http3Exception ex) {
                    LOG.error("Failed to send the outbound response : " + ex.getMessage(), ex);
                    inboundRequestMsg.getHttpOutboundRespStatusFuture().notifyHttpListener(ex);
                }
            });
        });
    }

    public long getStreamId() {
        return streamId;
    }

    public ChannelHandlerContext getChannelHandlerContext() {
        return channelHandlerContext;
    }


    public HttpCarbonMessage getInboundRequestMsg() {
        return inboundRequestMsg;
    }

    public Http3ServerChannel getHttp3ServerChannel() {
        return http3ServerChannel;
    }


    public HttpCarbonMessage getOutboundResponseMsg() {
        return outboundResponseMsg;
    }

    public Http3ServerChannelInitializer getServerChannelInitializer() {
        return http3ServerChannelInitializer;
    }

    public String getServerName() {
        return serverName;
    }

    /**
     * Responsible for writing HTTP/3 outbound response to the caller.
     */
    public class ResponseWriter {
        private long streamId;

        ResponseWriter(long streamId) {
            this.streamId = streamId;
        }

        private void writeOutboundResponse(HttpCarbonMessage outboundResponseMsg, HttpContent httpContent)
                throws Http3Exception {

            http3MessageStateContext.getListenerState().
                    writeOutboundResponseBody(Http3OutboundRespListener.this,
                            outboundResponseMsg, httpContent, streamId);
        }

    }


    private void setContentEncoding(HttpCarbonMessage outboundResponseMsg) {
        String contentEncoding = outboundResponseMsg.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString());
        if (contentEncoding == null) {
            String acceptEncoding = inboundRequestMsg.getHeader(HttpHeaderNames.ACCEPT_ENCODING.toString());
            if (acceptEncoding != null) {
                String targetContentEncoding = determineScheme(acceptEncoding);
                if (targetContentEncoding != null) {
                    outboundResponseMsg.setHeader(HttpHeaderNames.CONTENT_ENCODING.toString(), targetContentEncoding);
                }
            }
        }
    }

    private String determineScheme(String acceptEncoding) {
        float starQ = -1.0f;
        float gzipQ = -1.0f;
        float deflateQ = -1.0f;
        for (String encoding : acceptEncoding.split(",")) {
            float qValue = 1.0f;
            int equalsPos = encoding.indexOf('=');
            if (equalsPos != -1) {
                try {
                    qValue = Float.parseFloat(encoding.substring(equalsPos + 1));
                } catch (NumberFormatException e) {
                    // Ignore encoding
                    qValue = 0.0f;
                }
            }
            if (encoding.contains("*")) {
                starQ = qValue;
            } else if (encoding.contains(ENCODING_GZIP) && qValue > gzipQ) {
                gzipQ = qValue;
            } else if (encoding.contains(ENCODING_DEFLATE) && qValue > deflateQ) {
                deflateQ = qValue;
            } else {
//                LOG.debug("Server does not support the requested encoding scheme: {}", encoding);
            }
        }
        if (gzipQ > 0.0f || deflateQ > 0.0f) {
            if (gzipQ >= deflateQ) {
                return ENCODING_GZIP;
            } else {
                return ENCODING_DEFLATE;
            }
        }
        if (starQ > 0.0f) {
            if (gzipQ == -1.0f) {
                return ENCODING_GZIP;
            }
            if (deflateQ == -1.0f) {
                return ENCODING_DEFLATE;
            }
        }
        return null;
    }
}
