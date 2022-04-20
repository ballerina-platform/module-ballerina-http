package io.ballerina.stdlib.http.transport.contractimpl;

import io.ballerina.stdlib.http.transport.contract.HttpConnectorListener;
import io.ballerina.stdlib.http.transport.contract.config.ChunkConfig;
import io.ballerina.stdlib.http.transport.contract.config.KeepAliveConfig;
import io.ballerina.stdlib.http.transport.contractimpl.common.states.Http3MessageStateContext;
import io.ballerina.stdlib.http.transport.contractimpl.listener.Http3ServerChannelInitializer;
import io.ballerina.stdlib.http.transport.contractimpl.listener.RequestDataHolder;
import io.ballerina.stdlib.http.transport.contractimpl.listener.http3.Http3ServerChannel;
import io.ballerina.stdlib.http.transport.contractimpl.listener.states.http3.SendingHeaders;
import io.ballerina.stdlib.http.transport.internal.HandlerExecutor;
import io.ballerina.stdlib.http.transport.internal.HttpTransportContextHolder;
import io.ballerina.stdlib.http.transport.message.BackPressureObservable;
import io.ballerina.stdlib.http.transport.message.DefaultBackPressureObservable;
import io.ballerina.stdlib.http.transport.message.Http2PushPromise;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.incubator.codec.http3.Http3Exception;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Calendar;
import java.util.concurrent.atomic.AtomicBoolean;

import static io.ballerina.stdlib.http.transport.contract.Constants.ENCODING_DEFLATE;
import static io.ballerina.stdlib.http.transport.contract.Constants.ENCODING_GZIP;

public class Http3OutboundRespListener implements HttpConnectorListener {

    private static final Logger LOG = LoggerFactory.getLogger(Http3OutboundRespListener.class);

    private final Http3ServerChannelInitializer http3ServerChannelInitializer;
    private final ChannelHandlerContext channelHandlerContext;
    private final HttpCarbonMessage httpRequestMsg;
    private final String remoteHost;
    private final Http3ServerChannel http3ServerChannel;
    private final long streamId;
//    private final HttpResponseFuture outboundRespStatusFuture;
    private  Http3MessageStateContext http3MessageStateContext;
    private ChannelHandlerContext sourceContext;
    private RequestDataHolder requestDataHolder;
    private HandlerExecutor handlerExecutor;
    private HttpCarbonMessage inboundRequestMsg;
    private ChunkConfig chunkConfig;
    private KeepAliveConfig keepAliveConfig;
    private String serverName;
    private HttpCarbonMessage outboundResponseMsg;
    private ResponseWriter defaultResponseWriter;
    private Calendar inboundRequestArrivalTime;
    private String remoteAddress = "-";

    public Http3OutboundRespListener(Http3ServerChannelInitializer http3ServerChannelInitializer,
                                     HttpCarbonMessage httpRequestMsg, ChannelHandlerContext channelHandlerContext,
                                     String remoteHost, long streamId, Http3ServerChannel http3ServerChannel) {
        this.http3ServerChannelInitializer = http3ServerChannelInitializer;
        this.channelHandlerContext = channelHandlerContext;
        this.streamId = streamId;
        this.httpRequestMsg = httpRequestMsg;
        this.handlerExecutor = HttpTransportContextHolder.getInstance().getHandlerExecutor();
        this.remoteHost = remoteHost;
        this.http3ServerChannel = http3ServerChannel;
        this.requestDataHolder = new RequestDataHolder(httpRequestMsg);
        this.inboundRequestMsg = httpRequestMsg;
        this.handlerExecutor = HttpTransportContextHolder.getInstance().getHandlerExecutor();
        http3MessageStateContext = httpRequestMsg.getHttp3MessageStateContext();
        inboundRequestArrivalTime = Calendar.getInstance();
//        outboundRespStatusFuture = inboundRequestMsg.getHttpOutboundRespStatusFuture();


    }

    @Override
    public void onMessage(HttpCarbonMessage outboundResponseMsg) {
        this.outboundResponseMsg = outboundResponseMsg;
        writeMessage(outboundResponseMsg, streamId, true);

    }

    @Override
    public void onError(Throwable throwable) {

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
        return remoteAddress;
    }


    private void writeMessage(HttpCarbonMessage outboundResponseMsg, long streamId, boolean backOffEnabled) {
        ResponseWriter writer = new ResponseWriter(streamId);

        setContentEncoding(outboundResponseMsg);
        outboundResponseMsg.getHttpContentAsync().setMessageListener(httpContent -> {
            checkStreamUnwritability(writer);
            channelHandlerContext.channel().eventLoop().execute(() -> {
                try {
                    writer.writeOutboundResponse(outboundResponseMsg, httpContent);
                } catch (Http3Exception e) {
                    e.printStackTrace();
                }
            });
        });
    }

    private void checkStreamUnwritability(ResponseWriter writer) {
        if (!writer.isStreamWritable()) {
            if (LOG.isDebugEnabled()) {
                LOG.debug("In thread {}. Stream is not writable.", Thread.currentThread().getName());
            }
            writer.getBackPressureObservable().notifyUnWritable();
        }
    }

    public long getStreamId() {
        return streamId;
    }

    public ChannelHandlerContext getChannelHandlerContext() {
        return channelHandlerContext;
    }

//    public HttpResponseFuture getOutboundRespStatusFuture() {
//        return outboundRespStatusFuture;
//
//    }

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

//    public HttpResponseFuture getOutboundRespStatusFuture() {
//        return outboundRespStatusFuture;
//    }


    /**
     * Responsible for writing HTTP/3 outbound response to the caller.
     */
    public class ResponseWriter {
        private long streamId;
        private AtomicBoolean streamWritable = new AtomicBoolean(true);
        private final BackPressureObservable backPressureObservable = new DefaultBackPressureObservable();

        ResponseWriter(long streamId) {
            this.streamId = streamId;
        }

        private void writeOutboundResponse(HttpCarbonMessage outboundResponseMsg, HttpContent httpContent)
                throws Http3Exception {
            if (http3MessageStateContext == null) {
                http3MessageStateContext = new Http3MessageStateContext();
                http3MessageStateContext.setListenerState(
                        new SendingHeaders(Http3OutboundRespListener.this,
                                http3MessageStateContext));
            }
            http3MessageStateContext.getListenerState().
                    writeOutboundResponseBody(Http3OutboundRespListener.this,
                            outboundResponseMsg, httpContent, streamId);
        } //done upto this


        boolean isStreamWritable() {
            return streamWritable.get();
        }

        public BackPressureObservable getBackPressureObservable() {
            return backPressureObservable;
        }
    }


    private void setContentEncoding(HttpCarbonMessage outboundResponseMsg) {
        String contentEncoding = outboundResponseMsg.getHeader(HttpHeaderNames.CONTENT_ENCODING.toString());
        //This means compression AUTO case; With NEVER(identity) and ALWAYS, content-encoding will always have a value.
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
