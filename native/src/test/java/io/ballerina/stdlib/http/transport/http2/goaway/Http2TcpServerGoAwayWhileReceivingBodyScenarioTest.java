package io.ballerina.stdlib.http.transport.http2.goaway;

import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
import io.netty.handler.codec.http.HttpContent;
import io.netty.handler.codec.http.HttpMethod;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.fail;

public class Http2TcpServerGoAwayWhileReceivingBodyScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpServerGoAwayWhileReceivingBodyScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;

    @BeforeClass
    public void setup() throws InterruptedException {
        startTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = GoAwayTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testGoAwayWhenReceivingBodyForASingleStream() {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        try {
            CountDownLatch latch = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture = h2ClientWithPriorKnowledge.send(httpCarbonMessage);
            responseFuture.setHttpConnectorListener(msgListener);
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture.sync();
            HttpContent content = msgListener.getHttpResponseMessage().getHttpContent();
            if (content != null) {
                assertEquals(content.decoderResult().cause().getMessage(), REMOTE_SERVER_CLOSED_WHILE_READING_INBOUND_RESPONSE_BODY);
            } else {
                fail("Expected http content");
            }
        } catch (InterruptedException e) {
            LOGGER.error("Interrupted exception occurred");
        }
    }

    private void startTcpServer(int port) {
        new Thread(() -> {
            ServerSocket serverSocket;
            try {
                serverSocket = new ServerSocket(port);
                LOGGER.info("HTTP/2 TCP Server listening on port " + port);
                while (true) {
                    Socket clientSocket = serverSocket.accept();
                    LOGGER.info("Accepted connection from: " + clientSocket.getInetAddress());
                    try (OutputStream outputStream = clientSocket.getOutputStream()) {
                        sendGoAwayAfterSendingHeadersForASingleStream(outputStream);
                        break;
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }).start();
    }

    private static void sendGoAwayAfterSendingHeadersForASingleStream(OutputStream outputStream) throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        LOGGER.info("Wrote settings frame");
        outputStream.write(new byte[]{0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x64, 0x64});
        Thread.sleep(100);
        LOGGER.info("Writing settings frame with ack");
        outputStream.write(new byte[]{0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00});
        Thread.sleep(100);
        LOGGER.info("Writing headers frame with status 200");
        outputStream.write(new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x03, (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa});
        Thread.sleep(100);
        LOGGER.info("Writing a go away frame to stream 3");
        outputStream.write(new byte[]{0x00, 0x00, 0x08, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0b});
        Thread.sleep(100);
    }
}
