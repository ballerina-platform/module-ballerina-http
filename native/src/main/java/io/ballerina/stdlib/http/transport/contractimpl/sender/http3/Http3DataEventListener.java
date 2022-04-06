package io.ballerina.stdlib.http.transport.contractimpl.sender.http3;

import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http2.Http2Headers;
import io.netty.incubator.codec.http3.Http3Headers;

public interface Http3DataEventListener {

    boolean onStreamInit(ChannelHandlerContext ctx, long streamId);


    boolean onHeadersRead(ChannelHandlerContext ctx, long streamId, Http3Headers headers, boolean endOfStream);


    boolean onDataRead(ChannelHandlerContext ctx, long streamId, ByteBuf data, boolean endOfStream);

    boolean onPushPromiseRead(ChannelHandlerContext ctx, long streamId, Http3Headers headers, boolean endOfStream);

    boolean onHeadersWrite(ChannelHandlerContext ctx, long streamId, Http3Headers headers, boolean endOfStream);

    boolean onDataWrite(ChannelHandlerContext ctx, long streamId, ByteBuf data, boolean endOfStream);


    void onStreamReset(long streamId);


    void onStreamClose(long streamId);


    void destroy();
}
