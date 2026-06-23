/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.proxyserver;

import io.netty.bootstrap.Bootstrap;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.Unpooled;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFutureListener;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.socksx.v4.DefaultSocks4CommandResponse;
import io.netty.handler.codec.socksx.v4.Socks4CommandRequest;
import io.netty.handler.codec.socksx.v4.Socks4CommandStatus;
import io.netty.handler.codec.socksx.v4.Socks4ServerDecoder;
import io.netty.handler.codec.socksx.v4.Socks4ServerEncoder;
import io.netty.handler.codec.socksx.v5.DefaultSocks5CommandResponse;
import io.netty.handler.codec.socksx.v5.DefaultSocks5InitialResponse;
import io.netty.handler.codec.socksx.v5.DefaultSocks5PasswordAuthResponse;
import io.netty.handler.codec.socksx.v5.Socks5AddressType;
import io.netty.handler.codec.socksx.v5.Socks5AuthMethod;
import io.netty.handler.codec.socksx.v5.Socks5CommandRequest;
import io.netty.handler.codec.socksx.v5.Socks5CommandRequestDecoder;
import io.netty.handler.codec.socksx.v5.Socks5CommandStatus;
import io.netty.handler.codec.socksx.v5.Socks5InitialRequest;
import io.netty.handler.codec.socksx.v5.Socks5InitialRequestDecoder;
import io.netty.handler.codec.socksx.v5.Socks5PasswordAuthRequest;
import io.netty.handler.codec.socksx.v5.Socks5PasswordAuthRequestDecoder;
import io.netty.handler.codec.socksx.v5.Socks5PasswordAuthStatus;
import io.netty.handler.codec.socksx.v5.Socks5ServerEncoder;
import io.netty.util.ReferenceCountUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A minimal embedded Netty SOCKS proxy server used for testing the SOCKS4/SOCKS5 client proxy support.
 *
 * <p>Unlike MockServer (which cannot speak SOCKS4), this server performs the SOCKS handshake using Netty's
 * server-side SOCKS codecs, optionally enforces authentication, and then transparently relays the TCP byte
 * stream between the connecting client and the requested destination. Because it relays raw bytes after the
 * handshake, it is agnostic to what is tunnelled, so the same server works for both plaintext HTTP and TLS
 * (HTTPS) backends.</p>
 */
public final class EmbeddedSocksServer {

    private static final Logger LOG = LoggerFactory.getLogger(EmbeddedSocksServer.class);

    /**
     * The SOCKS protocol version this server speaks.
     */
    public enum Version {
        SOCKS4,
        SOCKS5
    }

    private final int port;
    private final Version version;
    private final String expectedUsername;
    private final String expectedPassword;

    private EventLoopGroup bossGroup;
    private EventLoopGroup workerGroup;
    private Channel serverChannel;

    /**
     * Creates an embedded SOCKS server.
     *
     * @param port             the port to listen on
     * @param version          the SOCKS protocol version
     * @param expectedUsername the username to enforce (SOCKS5 user/pass or SOCKS4 userId); {@code null} for no auth
     * @param expectedPassword the password to enforce (SOCKS5 only); ignored for SOCKS4
     */
    public EmbeddedSocksServer(int port, Version version, String expectedUsername, String expectedPassword) {
        this.port = port;
        this.version = version;
        this.expectedUsername = expectedUsername;
        this.expectedPassword = expectedPassword;
    }

    public void start() throws InterruptedException {
        bossGroup = new NioEventLoopGroup(1);
        workerGroup = new NioEventLoopGroup();
        ServerBootstrap bootstrap = new ServerBootstrap();
        bootstrap.group(bossGroup, workerGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) {
                        if (version == Version.SOCKS5) {
                            ch.pipeline().addLast(Socks5ServerEncoder.DEFAULT);
                            ch.pipeline().addLast(new Socks5InitialRequestDecoder());
                            ch.pipeline().addLast(new Socks5InitialRequestHandler());
                        } else {
                            ch.pipeline().addLast(Socks4ServerEncoder.INSTANCE);
                            ch.pipeline().addLast(new Socks4ServerDecoder());
                            ch.pipeline().addLast(new Socks4CommandHandler());
                        }
                    }
                });
        serverChannel = bootstrap.bind(port).sync().channel();
        LOG.debug("Embedded {} server started on port {}", version, port);
    }

    public void stop() {
        if (serverChannel != null) {
            serverChannel.close();
        }
        if (bossGroup != null) {
            bossGroup.shutdownGracefully();
        }
        if (workerGroup != null) {
            workerGroup.shutdownGracefully();
        }
    }

    private boolean authRequired() {
        return expectedUsername != null;
    }

    // ----------------------------- SOCKS5 -----------------------------

    private final class Socks5InitialRequestHandler extends SimpleChannelInboundHandler<Socks5InitialRequest> {
        @Override
        protected void channelRead0(ChannelHandlerContext ctx, Socks5InitialRequest msg) {
            ctx.pipeline().remove(Socks5InitialRequestDecoder.class);
            if (authRequired()) {
                ctx.pipeline().addBefore(ctx.name(), null, new Socks5PasswordAuthRequestDecoder());
                ctx.pipeline().replace(this, null, new Socks5PasswordAuthHandler());
                ctx.writeAndFlush(new DefaultSocks5InitialResponse(Socks5AuthMethod.PASSWORD));
            } else {
                ctx.pipeline().addBefore(ctx.name(), null, new Socks5CommandRequestDecoder());
                ctx.pipeline().replace(this, null, new Socks5CommandHandler());
                ctx.writeAndFlush(new DefaultSocks5InitialResponse(Socks5AuthMethod.NO_AUTH));
            }
        }
    }

    private final class Socks5PasswordAuthHandler
            extends SimpleChannelInboundHandler<Socks5PasswordAuthRequest> {
        @Override
        protected void channelRead0(ChannelHandlerContext ctx, Socks5PasswordAuthRequest msg) {
            ctx.pipeline().remove(Socks5PasswordAuthRequestDecoder.class);
            boolean ok = expectedUsername.equals(msg.username()) && expectedPassword.equals(msg.password());
            if (ok) {
                ctx.pipeline().addBefore(ctx.name(), null, new Socks5CommandRequestDecoder());
                ctx.pipeline().replace(this, null, new Socks5CommandHandler());
                ctx.writeAndFlush(new DefaultSocks5PasswordAuthResponse(Socks5PasswordAuthStatus.SUCCESS));
            } else {
                ctx.writeAndFlush(new DefaultSocks5PasswordAuthResponse(Socks5PasswordAuthStatus.FAILURE))
                        .addListener(ChannelFutureListener.CLOSE);
            }
        }
    }

    private final class Socks5CommandHandler extends SimpleChannelInboundHandler<Socks5CommandRequest> {
        @Override
        protected void channelRead0(ChannelHandlerContext ctx, Socks5CommandRequest msg) {
            ctx.pipeline().remove(Socks5CommandRequestDecoder.class);
            connectAndRelay(ctx, msg.dstAddr(), msg.dstPort(),
                    () -> ctx.writeAndFlush(new DefaultSocks5CommandResponse(Socks5CommandStatus.SUCCESS,
                            Socks5AddressType.IPv4, "0.0.0.0", 0)).addListener(f -> {
                                ctx.pipeline().remove(Socks5ServerEncoder.class);
                                ctx.pipeline().remove(this);
                            }),
                    () -> ctx.writeAndFlush(new DefaultSocks5CommandResponse(Socks5CommandStatus.FAILURE,
                            Socks5AddressType.IPv4, "0.0.0.0", 0)).addListener(ChannelFutureListener.CLOSE));
        }
    }

    // ----------------------------- SOCKS4 -----------------------------

    private final class Socks4CommandHandler extends SimpleChannelInboundHandler<Socks4CommandRequest> {
        @Override
        protected void channelRead0(ChannelHandlerContext ctx, Socks4CommandRequest msg) {
            if (authRequired() && !expectedUsername.equals(msg.userId())) {
                ctx.writeAndFlush(new DefaultSocks4CommandResponse(Socks4CommandStatus.IDENTD_AUTH_FAILURE))
                        .addListener(ChannelFutureListener.CLOSE);
                return;
            }
            ctx.pipeline().remove(Socks4ServerDecoder.class);
            connectAndRelay(ctx, msg.dstAddr(), msg.dstPort(),
                    () -> ctx.writeAndFlush(new DefaultSocks4CommandResponse(Socks4CommandStatus.SUCCESS))
                            .addListener(f -> {
                                ctx.pipeline().remove(Socks4ServerEncoder.class);
                                ctx.pipeline().remove(this);
                            }),
                    () -> ctx.writeAndFlush(new DefaultSocks4CommandResponse(Socks4CommandStatus.REJECTED_OR_FAILED))
                            .addListener(ChannelFutureListener.CLOSE));
        }
    }

    // ----------------------------- Relay -----------------------------

    /**
     * Opens a TCP connection to the requested destination. On success, runs {@code onConnected} (which writes
     * the SOCKS success reply and strips the SOCKS codecs), then wires up bidirectional byte relaying between
     * the inbound (client) channel and the outbound (backend) channel.
     */
    private void connectAndRelay(ChannelHandlerContext ctx, String host, int dstPort,
                                 Runnable onConnected, Runnable onFailure) {
        Channel inbound = ctx.channel();
        Bootstrap b = new Bootstrap();
        b.group(inbound.eventLoop())
                .channel(NioSocketChannel.class)
                .handler(new ChannelInboundHandlerAdapter());
        b.connect(host, dstPort).addListener((ChannelFutureListener) future -> {
            if (future.isSuccess()) {
                Channel outbound = future.channel();
                onConnected.run();
                inbound.pipeline().addLast(new RelayHandler(outbound));
                outbound.pipeline().addLast(new RelayHandler(inbound));
            } else {
                LOG.debug("SOCKS proxy failed to connect to backend {}:{}", host, dstPort, future.cause());
                onFailure.run();
            }
        });
    }

    /**
     * Relays bytes read on one channel to the paired channel and propagates close.
     */
    private static final class RelayHandler extends ChannelInboundHandlerAdapter {
        private final Channel peer;

        RelayHandler(Channel peer) {
            this.peer = peer;
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (peer.isActive()) {
                peer.writeAndFlush(msg);
            } else {
                ReferenceCountUtil.release(msg);
            }
        }

        @Override
        public void channelInactive(ChannelHandlerContext ctx) {
            if (peer.isActive()) {
                peer.writeAndFlush(Unpooled.EMPTY_BUFFER).addListener(ChannelFutureListener.CLOSE);
            }
        }

        @Override
        public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
            ctx.close();
        }
    }
}
