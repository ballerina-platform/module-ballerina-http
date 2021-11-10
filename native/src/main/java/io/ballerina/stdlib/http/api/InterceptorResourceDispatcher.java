package io.ballerina.stdlib.http.api;

import io.ballerina.stdlib.http.api.nativeimpl.pipelining.PipeliningHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.DispatcherUtil;
import io.ballerina.stdlib.http.uri.URITemplateException;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.HttpHeaderNames;

/**
 * Interceptor resource level dispatchers handler for HTTP protocol.
 */
public class InterceptorResourceDispatcher {

    public static InterceptorResource findResource(InterceptorService service, HttpCarbonMessage inboundRequest) {

        String method = inboundRequest.getHttpMethod();
        String subPath = (String) inboundRequest.getProperty(HttpConstants.SUB_PATH);
        subPath = sanitizeSubPath(subPath);
        HttpResourceArguments resourceArgumentValues = new HttpResourceArguments();
        try {
            InterceptorResource resource = service.getUriTemplate().matches(subPath, resourceArgumentValues,
                                                                                                        inboundRequest);
            if (resource != null) {
                inboundRequest.setProperty(HttpConstants.RESOURCE_ARGS, resourceArgumentValues);
                return resource;
            } else {
                if (method.equals(HttpConstants.HTTP_METHOD_OPTIONS)) {
                    handleOptionsRequest(inboundRequest, service);
                } else {
                    inboundRequest.setHttpStatusCode(404);
                    throw new BallerinaConnectorException("no matching resource found for path : "
                            + inboundRequest.getProperty(HttpConstants.TO) + " , method : " + method);
                }
                return null;
            }
        } catch (URITemplateException e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
    }

    private static String sanitizeSubPath(String subPath) {
        if ("/".equals(subPath)) {
            return subPath;
        }
        if (!subPath.startsWith("/")) {
            subPath = HttpConstants.DEFAULT_BASE_PATH + subPath;
        }
        subPath = subPath.endsWith("/") ? subPath.substring(0, subPath.length() - 1) : subPath;
        return subPath;
    }

    private static void handleOptionsRequest(HttpCarbonMessage cMsg, InterceptorService service) {
        HttpCarbonMessage response = HttpUtil.createHttpCarbonMessage(false);
        if (cMsg.getHeader(HttpHeaderNames.ALLOW.toString()) != null) {
            response.setHeader(HttpHeaderNames.ALLOW.toString(), cMsg.getHeader(HttpHeaderNames.ALLOW.toString()));
        } else if (service.getBasePath().equals(cMsg.getProperty(HttpConstants.TO))
                && !service.getAllAllowedMethods().isEmpty()) {
            response.setHeader(HttpHeaderNames.ALLOW.toString(),
                    DispatcherUtil.concatValues(service.getAllAllowedMethods(), false));
        } else {
            cMsg.setHttpStatusCode(404);
            throw new BallerinaConnectorException("no matching resource found for path : "
                    + cMsg.getProperty(HttpConstants.TO) + " , method : " + "OPTIONS");
        }
        CorsHeaderGenerator.process(cMsg, response, false);
        response.setHttpStatusCode(204);
        response.addHttpContent(new DefaultLastHttpContent());
        PipeliningHandler.sendPipelinedResponse(cMsg, response);
        cMsg.waitAndReleaseAllEntities();
    }

    private InterceptorResourceDispatcher() {
    }
}
