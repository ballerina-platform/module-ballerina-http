package io.ballerina.stdlib.http.transport.contractimpl.sender.http2;

import io.netty.buffer.ByteBuf;
import io.netty.handler.codec.http.DefaultHttpContent;
import io.netty.handler.codec.http.HttpHeaders;

/**
 * {@code Http2ResetContent} represents a HTTP/2 reset content.
 */
public class Http2ResetContent extends DefaultHttpContent {

    private HttpHeaders errorHeaders;

    /**
     * Creates a new instance with the specified chunk content.
     *
     * @param content
     */
    public Http2ResetContent(ByteBuf content) {

        super(content);
    }

    public void setErrorHeaders(HttpHeaders errorHeaders) {
        this.errorHeaders = errorHeaders;
    }

    public HttpHeaders getErrorHeaders() {
        return errorHeaders;
    }
}
