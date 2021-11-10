package io.ballerina.stdlib.http.api;

import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.DispatcherUtil;
import io.ballerina.stdlib.http.uri.parser.DataElement;
import io.ballerina.stdlib.http.uri.parser.DataReturnAgent;
import io.netty.handler.codec.http.HttpHeaderNames;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.stdlib.http.api.HttpErrorType.GENERIC_LISTENER_ERROR;

/**
 * Http Interceptor Node Item for URI template tree.
 */
public class InterceptorResourceDataElement implements DataElement<InterceptorResource, HttpCarbonMessage> {

    private List<InterceptorResource> resource;
    private boolean isFirstTraverse = true;
    private boolean hasData = false;

    @Override
    public boolean hasData() {
        return hasData;
    }

    @Override
    public void setData(InterceptorResource newResource) {
        if (isFirstTraverse) {
            this.resource = new ArrayList<>();
            this.resource.add(newResource);
            isFirstTraverse = false;
            hasData = true;
            return;
        }
        List<String> newMethods = newResource.getMethods();
        if (newMethods == null) {
            for (InterceptorResource previousResource : this.resource) {
                if (previousResource.getMethods() == null) {
                    //if both resources do not have methods but same URI, then throw following error.
                    throw HttpUtil.createHttpError("Two resources have the same addressable URI, "
                            + previousResource.getName() + " and " +
                            newResource.getName(), GENERIC_LISTENER_ERROR);
                }
            }
            this.resource.add(newResource);
            hasData = true;
            return;
        }
        this.resource.add(newResource);
        hasData = true;
    }

    @Override
    public boolean getData(HttpCarbonMessage carbonMessage, DataReturnAgent<InterceptorResource> dataReturnAgent) {
        try {
            if (this.resource == null) {
                return false;
            }
            InterceptorResource httpResource = validateHTTPMethod(this.resource, carbonMessage);
            if (httpResource == null) {
                return isOptionsRequest(carbonMessage);
            }
            dataReturnAgent.setData(httpResource);
            return true;
        } catch (BallerinaConnectorException e) {
            dataReturnAgent.setError(e);
            return false;
        }
    }

    private boolean isOptionsRequest(HttpCarbonMessage inboundMessage) {
        //Return true to break the resource searching loop, only if the ALLOW header is set in message for
        //OPTIONS request.
        return inboundMessage.getHeader(HttpHeaderNames.ALLOW.toString()) != null;
    }

    private InterceptorResource validateHTTPMethod(List<InterceptorResource> resources,
                                                                        HttpCarbonMessage carbonMessage) {
        InterceptorResource httpResource = null;
        boolean isOptionsRequest = false;
        String httpMethod = carbonMessage.getHttpMethod();
        for (InterceptorResource resourceInfo : resources) {
            if (DispatcherUtil.isMatchingMethodExist(resourceInfo, httpMethod)) {
                httpResource = resourceInfo;
                break;
            }
        }
        if (httpResource == null) {
            httpResource = tryMatchingToDefaultVerb(resources);
        }
        if (httpResource == null) {
            isOptionsRequest = setAllowHeadersIfOPTIONS(resources, httpMethod, carbonMessage);
        }
        if (httpResource != null) {
            return httpResource;
        }
        if (!isOptionsRequest) {
            carbonMessage.setHttpStatusCode(405);
            throw new BallerinaConnectorException("Method not allowed");
        }
        return null;
    }

    private InterceptorResource tryMatchingToDefaultVerb(List<InterceptorResource> resources) {
        for (InterceptorResource resourceInfo : resources) {
            if (resourceInfo.getMethods() == null) {
                //this means, wildcard method mentioned in the dataElement, hence it has all the methods by default.
                return resourceInfo;
            }
        }
        return null;
    }

    private boolean setAllowHeadersIfOPTIONS(List<InterceptorResource> resources, String httpMethod,
                                                                                            HttpCarbonMessage cMsg) {
        if (httpMethod.equals(HttpConstants.HTTP_METHOD_OPTIONS)) {
            cMsg.setHeader(HttpHeaderNames.ALLOW.toString(), getAllowHeaderValues(resources, cMsg));
            return true;
        }
        return false;
    }

    private String getAllowHeaderValues(List<InterceptorResource> resources, HttpCarbonMessage cMsg) {
        List<String> methods = new ArrayList<>();
        List<InterceptorResource> resourceInfos = new ArrayList<>();
        for (InterceptorResource resourceInfo : resources) {
            if (resourceInfo.getMethods() != null) {
                methods.addAll(resourceInfo.getMethods());
            }
            resourceInfos.add(resourceInfo);
        }
        cMsg.setProperty(HttpConstants.PREFLIGHT_RESOURCES, resourceInfos);
        methods = DispatcherUtil.validateAllowMethods(methods);
        return DispatcherUtil.concatValues(methods, false);
    }
}
