/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.values.BError;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.DispatcherUtil;
import io.ballerina.stdlib.http.uri.parser.DataElement;
import io.ballerina.stdlib.http.uri.parser.DataReturnAgent;
import io.netty.handler.codec.http.HttpHeaderNames;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import static io.ballerina.stdlib.http.api.HttpErrorType.GENERIC_LISTENER_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_REQUEST_NOT_ACCEPTABLE_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_RESOURCE_METHOD_NOT_ALLOWED_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_UNSUPPORTED_REQUEST_MEDIA_TYPE_ERROR;

/**
 * Http Node Item for URI template tree.
 */
public class ResourceDataElement implements DataElement<Resource, HttpCarbonMessage> {

    private List<Resource> resource;
    private boolean isFirstTraverse = true;
    private boolean hasData = false;

    @Override
    public boolean hasData() {
        return hasData;
    }

    @Override
    public void setData(Resource newResource) {
        if (isFirstTraverse) {
            this.resource = new ArrayList<>();
            this.resource.add(newResource);
            isFirstTraverse = false;
            hasData = true;
            return;
        }
        List<String> newMethods = newResource.getMethods();
        if (newMethods == null) {
            for (Resource previousResource : this.resource) {
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
        this.resource.forEach(r -> {
            for (String newMethod : newMethods) {
                if (DispatcherUtil.isMatchingMethodExist(r, newMethod)) {
                    if (r.getName().equals(HttpIntrospectionResource.getResourceId())) {
                        String message = "Resources cannot have the accessor and name as same as the auto generated " +
                                "Open API spec retrieval resource: '" + r.getName() + "'";
                        throw HttpUtil.createHttpError(message, GENERIC_LISTENER_ERROR);
                    }
                    if (r.getName().equals(HttpSwaggerUiResource.getResourceId())) {
                        String message = "Resources cannot have the accessor and name as same as the auto generated " +
                                "Swagger-UI retrieval resource: '" + r.getName() + "'";
                        throw HttpUtil.createHttpError(message, GENERIC_LISTENER_ERROR);
                    }
                    throw HttpUtil.createHttpError("Two resources have the same addressable URI, "
                                                           + r.getName() + " and " + newResource.getName(),
                                                   GENERIC_LISTENER_ERROR);
                }
            }
        });
        this.resource.add(newResource);
        hasData = true;
    }

    @Override
    public boolean getData(HttpCarbonMessage carbonMessage, DataReturnAgent<Resource> dataReturnAgent) {
        try {
            if (this.resource == null) {
                return false;
            }
            Resource httpResource = validateHTTPMethod(this.resource, carbonMessage);
            if (httpResource == null) {
                return isOptionsRequest(carbonMessage);
            }
            validateConsumes(httpResource, carbonMessage);
            validateProduces(httpResource, carbonMessage);
            dataReturnAgent.setData(httpResource);
            return true;
        } catch (BError e) {
            dataReturnAgent.setError(e);
            return false;
        }
    }

    private boolean isOptionsRequest(HttpCarbonMessage inboundMessage) {
        //Return true to break the resource searching loop, only if the ALLOW header is set in message for
        //OPTIONS request.
        return inboundMessage.getHeader(HttpHeaderNames.ALLOW.toString()) != null;
    }

    private Resource validateHTTPMethod(List<Resource> resources, HttpCarbonMessage carbonMessage) {
        Resource httpResource = null;
        boolean isOptionsRequest = false;
        String httpMethod = carbonMessage.getHttpMethod();
        for (Resource resourceInfo : resources) {
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
            throw HttpUtil.createHttpStatusCodeError(INTERNAL_RESOURCE_METHOD_NOT_ALLOWED_ERROR, "Method not allowed");
        }
        return null;
    }

    private Resource tryMatchingToDefaultVerb(List<Resource> resources) {
        for (Resource resourceInfo : resources) {
            if (resourceInfo.getMethods() == null) {
                //this means, wildcard method mentioned in the dataElement, hence it has all the methods by default.
                return resourceInfo;
            }
        }
        return null;
    }

    private boolean setAllowHeadersIfOPTIONS(List<Resource> resources, String httpMethod, HttpCarbonMessage cMsg) {
        if (httpMethod.equals(HttpConstants.HTTP_METHOD_OPTIONS)) {
            cMsg.setHeader(HttpHeaderNames.ALLOW.toString(), getAllowHeaderValues(resources, cMsg));
            return true;
        }
        return false;
    }

    private String getAllowHeaderValues(List<Resource> resources, HttpCarbonMessage cMsg) {
        List<String> methods = new ArrayList<>();
        List<Resource> resourceInfos = new ArrayList<>();
        for (Resource resourceInfo : resources) {
            if (resourceInfo.getMethods() != null) {
                methods.addAll(resourceInfo.getMethods());
            }
            resourceInfos.add(resourceInfo);
        }
        cMsg.setProperty(HttpConstants.PREFLIGHT_RESOURCES, resourceInfos);
        methods = DispatcherUtil.validateAllowMethods(methods);
        return DispatcherUtil.concatValues(methods, false);
    }

    private void validateConsumes(Resource resource, HttpCarbonMessage cMsg) {
        String contentMediaType = extractContentMediaType(cMsg.getHeader(HttpHeaderNames.CONTENT_TYPE.toString()));
        List<String> consumesList = resource.getConsumes();

        if (consumesList == null || consumesList.isEmpty()) {
            return;
        }
        //when Content-Type header is not set, treat it as "application/octet-stream"
        contentMediaType = (contentMediaType != null ? contentMediaType : HttpConstants.VALUE_ATTRIBUTE);
        for (String consumeType : consumesList) {
            if (contentMediaType.equalsIgnoreCase(consumeType.trim())) {
                return;
            }
        }
        String message = "content-type : " + contentMediaType + " is not supported";
        throw HttpUtil.createHttpStatusCodeError(INTERNAL_UNSUPPORTED_REQUEST_MEDIA_TYPE_ERROR, message);
    }

    private String extractContentMediaType(String header) {
        if (header == null) {
            return null;
        }
        if (header.contains(";")) {
            header = header.substring(0, header.indexOf(';')).trim();
        }
        return header;
    }

    private void validateProduces(Resource resource, HttpCarbonMessage cMsg) {
        List<String> acceptMediaTypes = extractAcceptMediaTypes(cMsg.getHeader(HttpHeaderNames.ACCEPT.toString()));
        List<String> producesList = resource.getProduces();

        if (producesList == null || producesList.isEmpty() || acceptMediaTypes == null) {
            return;
        }
        //If Accept header field is not present, then it is assumed that the client accepts all media types.
        if (acceptMediaTypes.contains("*/*")) {
            return;
        }
        if (acceptMediaTypes.stream().anyMatch(mediaType -> mediaType.contains("/*"))) {
            List<String> subTypeWildCardMediaTypes = acceptMediaTypes.stream()
                    .filter(mediaType -> mediaType.contains("/*"))
                    .map(mediaType -> mediaType.substring(0, mediaType.indexOf('/')))
                    .collect(Collectors.toList());
            for (String token : resource.getProducesSubTypes()) {
                if (subTypeWildCardMediaTypes.contains(token)) {
                    return;
                }
            }
        }
        List<String> noWildCardMediaTypes = acceptMediaTypes.stream()
                .filter(mediaType -> !mediaType.contains("/*")).collect(Collectors.toList());
        for (String produceType : producesList) {
            if (noWildCardMediaTypes.stream().anyMatch(produceType::equalsIgnoreCase)) {
                return;
            }
        }
        throw HttpUtil.createHttpStatusCodeError(INTERNAL_REQUEST_NOT_ACCEPTABLE_ERROR, "Request is not acceptable");
    }

    private List<String> extractAcceptMediaTypes(String header) {
        if (header == null) {
            return null;
        }
        List<String> acceptMediaTypes = new ArrayList<>();
        if (header.contains(",")) {
            //process headers like this: text/*;q=0.3, text/html;Level=1;q=0.7, */*
            acceptMediaTypes = Arrays.stream(header.split(","))
                    .map(mediaRange -> mediaRange.contains(";") ? mediaRange
                            .substring(0, mediaRange.indexOf(';')) : mediaRange)
                    .map(String::trim).distinct().collect(Collectors.toList());
        } else if (header.contains(";")) {
            //process headers like this: text/*;q=0.3
            acceptMediaTypes.add(header.substring(0, header.indexOf(';')).trim());
        } else {
            acceptMediaTypes.add(header.trim());
        }
        return acceptMediaTypes;
    }
}
