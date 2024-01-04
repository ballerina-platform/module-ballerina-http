package io.ballerina.stdlib.http.transport.http2.goaway;

import io.ballerina.stdlib.http.transport.contract.Constants;
import io.ballerina.stdlib.http.transport.contract.HttpClientConnector;
import io.ballerina.stdlib.http.transport.contract.HttpResponseFuture;
import io.ballerina.stdlib.http.transport.contract.HttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.contract.config.SenderConfiguration;
import io.ballerina.stdlib.http.transport.contract.config.TransportsConfiguration;
import io.ballerina.stdlib.http.transport.contractimpl.DefaultHttpWsConnectorFactory;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.transport.message.HttpConnectorUtil;
import io.ballerina.stdlib.http.transport.util.DefaultHttpConnectorListener;
import io.ballerina.stdlib.http.transport.util.TestUtil;
import io.ballerina.stdlib.http.transport.util.client.http2.MessageGenerator;
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

import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.fail;

public class Http2TcpServerGoAwaySingleStreamScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpServerGoAwaySingleStreamScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;

    @BeforeClass
    public void setup() throws InterruptedException {
        startTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = GoAwayTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testGoAwayWhenReceivingHeadersForASingleStream() {
        HttpCarbonMessage httpCarbonMessage = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        try {
            CountDownLatch latch = new CountDownLatch(1);
            DefaultHttpConnectorListener msgListener = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture = h2ClientWithPriorKnowledge.send(httpCarbonMessage);
            responseFuture.setHttpConnectorListener(msgListener);
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture.sync();
            Throwable responseError = responseFuture.getStatus().getCause();
            if (responseError != null) {
                assertEquals(responseError.getMessage(), REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE);
            } else {
                fail("Expected error not received");
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
                        sendGoAwayForASingleStream(outputStream);
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

    private static void sendGoAwayForASingleStream(OutputStream outputStream) throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        LOGGER.info("Wrote settings frame");
        outputStream.write(new byte[]{0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x64, 0x64});
        Thread.sleep(100);
        LOGGER.info("Writing settings frame with ack");
        outputStream.write(new byte[]{0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00});
        Thread.sleep(100);
        LOGGER.info("Writing a go away frame to stream 3");
        outputStream.write(new byte[]{0x00, 0x00, 0x08, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0b});
        Thread.sleep(100);
    }
}
