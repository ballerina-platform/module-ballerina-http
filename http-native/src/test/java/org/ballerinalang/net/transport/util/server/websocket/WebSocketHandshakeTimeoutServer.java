package org.ballerinalang.net.transport.util.server.websocket;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class WebSocketHandshakeTimeoutServer {
    private static final Logger LOG = LoggerFactory.getLogger(WebSocketRemoteServer.class);

    private final int port;
    private EventLoopGroup bossGroup;
    private EventLoopGroup workerGroup;

    public WebSocketHandshakeTimeoutServer(int port) {
        this.port = port;
    }

    public void run() throws InterruptedException {
        bossGroup = new NioEventLoopGroup();
        workerGroup = new NioEventLoopGroup();

        ServerBootstrap serverBootstrap = new ServerBootstrap();
        serverBootstrap.group(bossGroup, workerGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(new WebSocketIdleTimeoutRemoteServerInitializer());

        serverBootstrap.bind(port).sync();
        LOG.info("WebSocket remote server started listening on port " + port);
    }

    public void stop() {
        bossGroup.shutdownGracefully();
        workerGroup.shutdownGracefully();
        LOG.info("WebSocket remote server stopped listening  on port " + port);
    }
}

