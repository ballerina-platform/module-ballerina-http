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
import io.netty.util.CharsetUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static io.ballerina.stdlib.http.transport.contract.Constants.REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE;
import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertEqualsNoOrder;
import static org.testng.Assert.fail;

public class Http2TcpServerGoAwayMultipleStreamScenarioTest {

    private static final Logger LOGGER = LoggerFactory.getLogger(Http2TcpServerGoAwayMultipleStreamScenarioTest.class);
    private HttpClientConnector h2ClientWithPriorKnowledge;

    @BeforeClass
    public void setup() throws InterruptedException {
        startTcpServer(TestUtil.HTTP_SERVER_PORT);
        h2ClientWithPriorKnowledge = GoAwayTestUtils.setupHttp2PriorKnowledgeClient();
    }

    @Test
    private void testGoAwayWhenReceivingHeadersInAMultipleStreamScenario() {
        HttpCarbonMessage httpCarbonMessage1 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage2 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage3 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        HttpCarbonMessage httpCarbonMessage4 = MessageGenerator.generateRequest(HttpMethod.POST, "Test Http2 Message");
        try {
            CountDownLatch latch = new CountDownLatch(4);
            DefaultHttpConnectorListener msgListener1 = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture1 = h2ClientWithPriorKnowledge.send(httpCarbonMessage1);
            responseFuture1.setHttpConnectorListener(msgListener1);
            DefaultHttpConnectorListener msgListener2 = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture2 = h2ClientWithPriorKnowledge.send(httpCarbonMessage2);
            responseFuture2.setHttpConnectorListener(msgListener2);
            DefaultHttpConnectorListener msgListener3 = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture3 = h2ClientWithPriorKnowledge.send(httpCarbonMessage3);
            responseFuture3.setHttpConnectorListener(msgListener3);
            DefaultHttpConnectorListener msgListener4 = new DefaultHttpConnectorListener(latch);
            HttpResponseFuture responseFuture4 = h2ClientWithPriorKnowledge.send(httpCarbonMessage4);
            responseFuture4.setHttpConnectorListener(msgListener4);
            latch.await(TestUtil.HTTP2_RESPONSE_TIME_OUT, TimeUnit.SECONDS);
            responseFuture1.sync();
            responseFuture2.sync();
            responseFuture3.sync();
            responseFuture4.sync();
            HttpCarbonMessage response1 = msgListener1.getHttpResponseMessage();
            HttpCarbonMessage response2 = msgListener2.getHttpResponseMessage();
            HttpCarbonMessage response3 = msgListener3.getHttpResponseMessage();
            HttpCarbonMessage response4 = msgListener4.getHttpResponseMessage();
            Object responseValOrError1 = response1 == null ? responseFuture1.getStatus().getCause().getMessage() :
                    response1.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseValOrError2 = response2 == null ? responseFuture2.getStatus().getCause().getMessage() :
                    response2.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseValOrError3 = response3 == null ? responseFuture3.getStatus().getCause().getMessage() :
                    response3.getHttpContent().content().toString(CharsetUtil.UTF_8);
            Object responseValOrError4 = response4 == null ? responseFuture4.getStatus().getCause().getMessage() :
                    response4.getHttpContent().content().toString(CharsetUtil.UTF_8);
            assertEqualsNoOrder(List.of(responseValOrError1, responseValOrError2, responseValOrError3,
                    responseValOrError4), List.of("hello worl3", "hello worl5", "hello worl7",
                    REMOTE_SERVER_CLOSED_BEFORE_INITIATING_INBOUND_RESPONSE));
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
                        sendGoAwayForASingleStreamInAMultipleStreamScenario(outputStream);
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

    private static void sendGoAwayForASingleStreamInAMultipleStreamScenario(OutputStream outputStream) throws IOException, InterruptedException {
        // Sending settings frame with HEADER_TABLE_SIZE=25700
        LOGGER.info("Wrote settings frame");
        outputStream.write(new byte[]{0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x64, 0x64});
        LOGGER.info("Writing settings frame with ack");
        outputStream.write(new byte[]{0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00});
        Thread.sleep(100);
        LOGGER.info("Writing headers frame to stream 3");
        outputStream.write(new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x03, (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa});
        Thread.sleep(100);
        LOGGER.info("Writing headers frame to stream 5");
        outputStream.write(new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x05, (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa});
        LOGGER.info("Writing data frame to stream 5");
        outputStream.write(new byte[]{0x00, 0x00, 0x0b, 0x00, 0x01, 0x00, 0x00, 0x00, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x35});
        LOGGER.info("Writing a go away frame with max frame number 7");
        outputStream.write(new byte[]{0x00, 0x00, 0x08, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00, 0x0b});
        Thread.sleep(100);
        LOGGER.info("Writing headers frame to stream 9");
        outputStream.write(new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x09, (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa});
        LOGGER.info("Writing data frame to stream 9");
        outputStream.write(new byte[]{0x00, 0x00, 0x0b, 0x00, 0x01, 0x00, 0x00, 0x00, 0x09, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x39});
        Thread.sleep(100);
        LOGGER.info("Writing headers frame to stream 7");
        outputStream.write(new byte[]{0x00, 0x00, 0x0a, 0x01, 0x04, 0x00, 0x00, 0x00, 0x07, (byte) 0x88, 0x5f, (byte) 0x87, 0x49, 0x7c, (byte) 0xa5, (byte) 0x8a, (byte) 0xe8, 0x19, (byte) 0xaa});
        LOGGER.info("Writing data frame to stream 7");
        outputStream.write(new byte[]{0x00, 0x00, 0x0b, 0x00, 0x01, 0x00, 0x00, 0x00, 0x07, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x37});
        Thread.sleep(100);
        LOGGER.info("Writing data frame to stream 3");
        outputStream.write(new byte[]{0x00, 0x00, 0x0b, 0x00, 0x01, 0x00, 0x00, 0x00, 0x03, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x77, 0x6f, 0x72, 0x6c, 0x33});
        Thread.sleep(100);
    }
}
