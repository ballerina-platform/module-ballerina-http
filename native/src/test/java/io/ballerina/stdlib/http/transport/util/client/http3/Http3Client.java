package io.ballerina.stdlib.http.transport.util.client.http3;

import io.netty.bootstrap.Bootstrap;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioDatagramChannel;
import io.netty.handler.ssl.util.InsecureTrustManagerFactory;
import io.netty.incubator.codec.http3.DefaultHttp3HeadersFrame;
import io.netty.incubator.codec.http3.Http3;
import io.netty.incubator.codec.http3.Http3ClientConnectionHandler;
import io.netty.incubator.codec.http3.Http3DataFrame;
import io.netty.incubator.codec.http3.Http3HeadersFrame;
import io.netty.incubator.codec.http3.Http3RequestStreamFrame;
import io.netty.incubator.codec.http3.Http3RequestStreamInboundHandler;
import io.netty.incubator.codec.quic.QuicChannel;
import io.netty.incubator.codec.quic.QuicSslContext;
import io.netty.incubator.codec.quic.QuicSslContextBuilder;
import io.netty.incubator.codec.quic.QuicStreamChannel;
import io.netty.util.CharsetUtil;
import io.netty.util.NetUtil;
import io.netty.util.ReferenceCountUtil;

import java.net.InetSocketAddress;
import java.util.concurrent.TimeUnit;

/**
 * Netty Http3 client for HTTP 3 Basic test.
 *
 */
public final class Http3Client {

    static final int PORT = 9090;

    private Http3Client() { }

    public static void start(String... args) throws Exception {
        NioEventLoopGroup group = new NioEventLoopGroup(1);

        try {
            QuicSslContext context = QuicSslContextBuilder.forClient()
                    .trustManager(InsecureTrustManagerFactory.INSTANCE)
                    .applicationProtocols(Http3.supportedApplicationProtocols()).build();
            ChannelHandler codec = Http3.newQuicClientCodecBuilder()
                    .sslContext(context)
                    .maxIdleTimeout(50000, TimeUnit.MILLISECONDS)
                    .initialMaxData(10000000)
                    .initialMaxStreamDataBidirectionalLocal(1000000)
                    .build();

            Bootstrap bootstrap = new Bootstrap();
            Channel channel = bootstrap.group(group)
                    .channel(NioDatagramChannel.class)
                    .handler(codec)
                    .bind(0).sync().channel();

            QuicChannel quicChannel = QuicChannel.newBootstrap(channel)
                    .handler(new Http3ClientConnectionHandler())
                    .remoteAddress(new InetSocketAddress(NetUtil.LOCALHOST4, PORT))
                    .connect()
                    .get();

            QuicStreamChannel streamChannel = Http3.newRequestStream(quicChannel,
                    new Http3RequestStreamInboundHandler() {
                        @Override
                        protected void channelRead(ChannelHandlerContext ctx,
                                                   Http3HeadersFrame frame, boolean isLast) {
                            releaseFrameAndCloseIfLast(ctx, frame, isLast);
                        }

                        @Override
                        protected void channelRead(ChannelHandlerContext ctx,
                                                   Http3DataFrame frame, boolean isLast) {
                            releaseFrameAndCloseIfLast(ctx, frame, isLast);
                        }

                        private void releaseFrameAndCloseIfLast(ChannelHandlerContext ctx,
                                                                Http3RequestStreamFrame frame, boolean isLast) {
                            ReferenceCountUtil.release(frame);
                            if (isLast) {
                                ctx.close();
                            }
                        }
                    }).sync().getNow();


            Http3HeadersFrame headersFrame = new DefaultHttp3HeadersFrame();
            headersFrame.headers().method("get").path("/name/Dilhani")
                    .authority("127.0.0.1:" + PORT)
                    .scheme("https");


            streamChannel.writeAndFlush(headersFrame)
                    .addListener(QuicStreamChannel.SHUTDOWN_OUTPUT);

            streamChannel.closeFuture().sync();

            quicChannel.close().sync();
            channel.close().sync();
        } finally {
            group.shutdownGracefully();
        }
    }
}
