/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.nativeimpl.ModuleUtils;
import io.ballerina.stdlib.http.api.service.signature.AllHeaderParams;
import io.ballerina.stdlib.http.api.service.signature.AllPathParams;
import io.ballerina.stdlib.http.api.service.signature.AllQueryParams;
import io.ballerina.stdlib.http.api.service.signature.NonRecurringParam;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;
import io.ballerina.stdlib.http.api.service.signature.Parameter;
import io.ballerina.stdlib.http.api.service.signature.PayloadParam;
import io.ballerina.stdlib.http.api.service.signature.RemoteMethodParamHandler;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.URIUtil;
import io.netty.handler.codec.http.HttpHeaderNames;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

import static io.ballerina.stdlib.http.api.HttpConstants.AUTHORIZATION_HEADER;
import static io.ballerina.stdlib.http.api.HttpConstants.BEARER_AUTHORIZATION_HEADER;
import static io.ballerina.stdlib.http.api.HttpConstants.DEFAULT_HOST;
import static io.ballerina.stdlib.http.api.HttpConstants.JWT_DECODER_CLASS_NAME;
import static io.ballerina.stdlib.http.api.HttpConstants.JWT_DECODE_METHOD_NAME;
import static io.ballerina.stdlib.http.api.HttpConstants.JWT_INFORMATION;
import static io.ballerina.stdlib.http.api.HttpConstants.QUERY_STRING_SEPARATOR;
import static io.ballerina.stdlib.http.api.HttpConstants.REQUEST_CTX_MEMBERS;
import static io.ballerina.stdlib.http.api.HttpConstants.WHITESPACE;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_SERVICE_NOT_FOUND_ERROR;
import static io.ballerina.stdlib.http.api.HttpUtil.getParameterTypes;

/**
 * {@code HttpDispatcher} is responsible for dispatching incoming http requests to the correct resource.
 *
 * @since 0.94
 */
public class HttpDispatcher {

    private static final Logger logger = LoggerFactory.getLogger(HttpDispatcher.class);

    public static HttpService findService(HTTPServicesRegistry servicesRegistry, HttpCarbonMessage inboundReqMsg,
                                          boolean forInterceptors) {
        try {
            Map<String, HttpService> servicesOnInterface;
            List<String> sortedServiceURIs;
            String hostName = inboundReqMsg.getHeader(HttpHeaderNames.HOST.toString());

            if (hostName != null && servicesRegistry.getServicesMapHolder(hostName) != null) {
                servicesOnInterface = servicesRegistry.getServicesByHost(hostName);
                sortedServiceURIs = servicesRegistry.getSortedServiceURIsByHost(hostName);
            } else if (servicesRegistry.getServicesMapHolder(DEFAULT_HOST) != null) {
                servicesOnInterface = servicesRegistry.getServicesByHost(DEFAULT_HOST);
                sortedServiceURIs = servicesRegistry.getSortedServiceURIsByHost(DEFAULT_HOST);
            } else {
                String localAddress = inboundReqMsg.getProperty(HttpConstants.LOCAL_ADDRESS).toString();
                String message = "no service has registered for listener : " + localAddress;
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_SERVICE_NOT_FOUND_ERROR, message);
            }

            String rawUri = (String) inboundReqMsg.getProperty(HttpConstants.TO);
            Map<String, Map<String, String>> matrixParams = new HashMap<>();
            String uriWithoutMatrixParams = URIUtil.extractMatrixParams(rawUri, matrixParams, inboundReqMsg);

            String[] rawPathAndQuery = extractRawPathAndQuery(uriWithoutMatrixParams);

            String basePath = servicesRegistry.findTheMostSpecificBasePath(rawPathAndQuery[0],
                                                                           servicesOnInterface, sortedServiceURIs);

            if (basePath == null) {
                String message = "no matching service found for path: " + rawPathAndQuery[0];
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_SERVICE_NOT_FOUND_ERROR, message);
            }

            HttpService service = servicesOnInterface.get(basePath);
            if (!forInterceptors) {
                setInboundReqProperties(inboundReqMsg, rawPathAndQuery[0], basePath, rawPathAndQuery[1]);
                inboundReqMsg.setProperty(HttpConstants.RAW_URI, rawUri);
                inboundReqMsg.setProperty(HttpConstants.TO, uriWithoutMatrixParams);
                inboundReqMsg.setProperty(HttpConstants.MATRIX_PARAMS, matrixParams);
            }
            return service;
        } catch (Exception e) {
            if (!(e instanceof BError)) {
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_SERVICE_NOT_FOUND_ERROR, e.getMessage());
            }
            throw e;
        }
    }

    public static HttpService findSingleService(HTTPServicesRegistry servicesRegistry) {
        HttpService service = null;
        for (Object holder: servicesRegistry.getServicesMapByHost().values().toArray()) {
            HTTPServicesRegistry.ServicesMapHolder mapHolder = (HTTPServicesRegistry.ServicesMapHolder) holder;
            if (mapHolder.getServicesByBasePath().values().size() == 1 && service == null) {
                service = (HttpService) mapHolder.getServicesByBasePath().values().toArray()[0];
            } else {
                return null;
            }
        }
        return service;
    }

    // TODO : Refactor finding interceptor service logic and the usage of HTTPInterceptorServicesRegistry
    public static InterceptorService findInterceptorService(HTTPInterceptorServicesRegistry servicesRegistry,
                                                            HttpCarbonMessage inboundReqMsg,
                                                            boolean isResponsePath) {
        try {
            Map<String, InterceptorService> servicesOnInterface;
            List<String> sortedServiceURIs;
            String hostName = inboundReqMsg.getHeader(HttpHeaderNames.HOST.toString());

            if (hostName != null && servicesRegistry.getServicesMapHolder(hostName) != null) {
                servicesOnInterface = servicesRegistry.getServicesByHost(hostName);
                sortedServiceURIs = servicesRegistry.getSortedServiceURIsByHost(hostName);
            } else if (servicesRegistry.getServicesMapHolder(DEFAULT_HOST) != null) {
                servicesOnInterface = servicesRegistry.getServicesByHost(DEFAULT_HOST);
                sortedServiceURIs = servicesRegistry.getSortedServiceURIsByHost(DEFAULT_HOST);
            } else {
                String localAddress = inboundReqMsg.getProperty(HttpConstants.LOCAL_ADDRESS).toString();
                String message = "no service has registered for listener : " + localAddress;
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_SERVICE_NOT_FOUND_ERROR, message);
            }

            if (isResponsePath) {
                // There is only one service registered on the interceptor registry
                InterceptorService[] services = servicesOnInterface.values().toArray(new InterceptorService[0]);
                return services[0];
            }

            String rawUri = (String) inboundReqMsg.getProperty(HttpConstants.TO);
            inboundReqMsg.setProperty(HttpConstants.RAW_URI, rawUri);
            Map<String, Map<String, String>> matrixParams = new HashMap<>();
            String uriWithoutMatrixParams = URIUtil.extractMatrixParams(rawUri, matrixParams, inboundReqMsg);

            inboundReqMsg.setProperty(HttpConstants.TO, uriWithoutMatrixParams);
            inboundReqMsg.setProperty(HttpConstants.MATRIX_PARAMS, matrixParams);

            String[] rawPathAndQuery = extractRawPathAndQuery(uriWithoutMatrixParams);

            String basePath = servicesRegistry.findTheMostSpecificBasePath(rawPathAndQuery[0],
                                                                           servicesOnInterface, sortedServiceURIs);

            if (basePath == null) {
                String message = "no matching service found for path: " + rawPathAndQuery[0];
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_SERVICE_NOT_FOUND_ERROR, message);
            }

            InterceptorService service = servicesOnInterface.get(basePath);
            setInboundReqProperties(inboundReqMsg, rawPathAndQuery[0], basePath, rawPathAndQuery[1]);
            return service;
        } catch (Exception e) {
            if (!(e instanceof BError)) {
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_SERVICE_NOT_FOUND_ERROR, e.getMessage());
            }
            throw e;
        }
    }

    private static String[] extractRawPathAndQuery(String uriWithoutMatrixParams) {
        String[] rawPathAndQuery = new String[2];
        String[] splittedUri = uriWithoutMatrixParams.split(QUERY_STRING_SEPARATOR);
        rawPathAndQuery[0] = splittedUri[0];
        rawPathAndQuery[1] = splittedUri.length > 1 ? splittedUri[1] : null;
        return rawPathAndQuery;
    }

    private static void setInboundReqProperties(HttpCarbonMessage inboundReqMsg, String rawPath,
                                                String basePath, String rawQuery) {
        String subPath = URIUtil.getSubPath(rawPath, basePath);
        inboundReqMsg.setProperty(HttpConstants.BASE_PATH, basePath);
        inboundReqMsg.setProperty(HttpConstants.SUB_PATH, subPath);
        inboundReqMsg.setProperty(HttpConstants.QUERY_STR, rawQuery);
        //store query params comes with request as it is
        inboundReqMsg.setProperty(HttpConstants.RAW_QUERY_STR, rawQuery);
    }

    public static URI getValidatedURI(String uriStr) {
        URI requestUri;
        try {
            requestUri = URI.create(uriStr);
        } catch (IllegalArgumentException e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
        return requestUri;
    }

    /**
     * This method finds the matching resource for the incoming request.
     *
     * @param servicesRegistry HTTP service registry
     * @param inboundMessage   incoming message.
     * @return matching resource.
     */
    public static HttpResource findResource(HTTPServicesRegistry servicesRegistry, HttpCarbonMessage inboundMessage) {
        String protocol = (String) inboundMessage.getProperty(HttpConstants.PROTOCOL);
        if (protocol == null) {
            throw HttpUtil.createHttpError("protocol not defined in the incoming request",
                                           HttpErrorType.INTERNAL_REQ_DISPATCHING_ERROR);
        }

        // Find the Service TODO can be improved
        HttpService service = HttpDispatcher.findService(servicesRegistry, inboundMessage, false);
        if (service == null) {
            throw HttpUtil.createHttpError("no Service found to handle the service request",
                                           HttpErrorType.INTERNAL_REQ_DISPATCHING_ERROR);
            // Finer details of the errors are thrown from the dispatcher itself, Ideally we shouldn't get here.
        }

        // Find the Resource
        return (HttpResource) ResourceDispatcher.findResource(service, inboundMessage);
    }

    public static InterceptorResource findInterceptorResource(HTTPInterceptorServicesRegistry servicesRegistry,
                                                              HttpCarbonMessage inboundMessage) {
        String protocol = (String) inboundMessage.getProperty(HttpConstants.PROTOCOL);
        if (protocol == null) {
            throw HttpUtil.createHttpError("protocol not defined in the incoming request",
                                           HttpErrorType.INTERNAL_REQ_DISPATCHING_ERROR);
        }

        // Find the Service TODO can be improved
        InterceptorService service = HttpDispatcher.findInterceptorService(servicesRegistry, inboundMessage, false);
        if (service == null) {
            throw HttpUtil.createHttpError("no Service found to handle the service request",
                                           HttpErrorType.INTERNAL_REQ_DISPATCHING_ERROR);
            // Finer details of the errors are thrown from the dispatcher itself, Ideally we shouldn't get here.
        }

        // Find the Resource
        return (InterceptorResource) ResourceDispatcher.findResource(service, inboundMessage);
    }

    public static Object[] getRemoteSignatureParameters(InterceptorService service, BObject response, BObject caller,
                                                        HttpCarbonMessage httpCarbonMessage, Runtime runtime) {
        BObject inRequest = null;
        BObject requestCtx = getRequestCtx(httpCarbonMessage, runtime);
        BObject entityObj = (BObject) httpCarbonMessage.getProperty(HttpConstants.ENTITY_OBJ);
        populatePropertiesForResponsePath(httpCarbonMessage, requestCtx);
        BError error = (BError) httpCarbonMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR);
        RemoteMethodParamHandler paramHandler = service.getRemoteMethodParamHandler();
        int sigParamCount = paramHandler.getParamCount();
        Object[] paramFeed = new Object[sigParamCount * 2];
        for (Parameter param : paramHandler.getOtherParamList()) {
            String typeName = param.getTypeName();
            switch (typeName) {
                case HttpConstants.REQUEST_CONTEXT:
                    int index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = requestCtx;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.REQUEST:
                    if (inRequest == null) {
                        inRequest = createRequest(httpCarbonMessage, entityObj);
                    }
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = inRequest;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.STRUCT_GENERIC_ERROR:
                    if (error == null) {
                        error = createError();
                    }
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = error;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.RESPONSE:
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = response;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.CALLER:
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = caller;
                    paramFeed[index] = true;
                    break;
                default:
                    break;
            }
        }
        return paramFeed;
    }

    private static void populatePropertiesForResponsePath(HttpCarbonMessage httpCarbonMessage, BObject requestCtx) {
        requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE, true);
        int interceptorId = httpCarbonMessage.getProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX) == null
                ? 0 : (int) httpCarbonMessage.getProperty(HttpConstants.RESPONSE_INTERCEPTOR_INDEX) + 1;
        requestCtx.addNativeData(HttpConstants.RESPONSE_INTERCEPTOR_INDEX, interceptorId);
        requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE_TYPE,
                                 HttpConstants.RESPONSE_INTERCEPTOR);
        requestCtx.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, false);
    }

    public static Object[] getSignatureParameters(Resource resource, HttpCarbonMessage httpCarbonMessage,
                                                  BMap<BString, Object> endpointConfig, Runtime runtime) {
        BObject inRequest = null;
        // Getting the same caller, request context and entity object to pass through interceptor services
        BObject requestCtx = getRequestCtx(httpCarbonMessage, runtime);
        populatePropertiesForRequestPath(resource, httpCarbonMessage, requestCtx);
        BObject entityObj = (BObject) httpCarbonMessage.getProperty(HttpConstants.ENTITY_OBJ);
        BError error = (BError) httpCarbonMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR);
        BObject httpCaller = getCaller(resource, httpCarbonMessage, endpointConfig);
        ParamHandler paramHandler = resource.getParamHandler();
        Type[] parameterTypes = getParameterTypes(resource.getBalResource());
        int sigParamCount = parameterTypes.length;
        Object[] paramFeed = new Object[sigParamCount * 2];
        boolean treatNilableAsOptional = resource.isTreatNilableAsOptional();
        // Following was written assuming that they are validated
        for (Parameter param : paramHandler.getParamList()) {
            String typeName = param.getTypeName();
            switch (typeName) {
                case HttpConstants.PATH_PARAM:
                    ((AllPathParams) param).populateFeed(paramFeed, httpCarbonMessage, resource);
                    break;
                case HttpConstants.CALLER:
                    int index = ((NonRecurringParam) param).getIndex();
                    httpCaller.set(HttpConstants.CALLER_PRESENT_FIELD, true);
                    paramFeed[index++] = httpCaller;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.REQUEST_CONTEXT:
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = requestCtx;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.STRUCT_GENERIC_ERROR:
                    if (error == null) {
                        error = createError();
                    }
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = error;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.REQUEST:
                    if (inRequest == null) {
                        inRequest = createRequest(httpCarbonMessage, entityObj);
                    }
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = inRequest;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.HEADERS:
                    if (inRequest == null) {
                        inRequest = createRequest(httpCarbonMessage, entityObj);
                    }
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = createHeadersObject(inRequest);
                    paramFeed[index] = true;
                    break;
                case HttpConstants.QUERY_PARAM:
                    ((AllQueryParams) param).populateFeed(httpCarbonMessage, paramHandler, paramFeed,
                                                          treatNilableAsOptional);
                    break;
                case HttpConstants.HEADER_PARAM:
                    ((AllHeaderParams) param).populateFeed(httpCarbonMessage, paramFeed, treatNilableAsOptional);
                    break;
                case HttpConstants.PAYLOAD_PARAM:
                    if (inRequest == null) {
                        inRequest = createRequest(httpCarbonMessage, entityObj);
                    }
                    ((PayloadParam) param).populateFeed(inRequest, httpCarbonMessage, paramFeed);
                    break;
                default:
                    break;
            }
        }
        return paramFeed;
    }

    private static BObject getRequestCtx(HttpCarbonMessage httpCarbonMessage, Runtime runtime) {
        BObject requestCtx = (BObject) httpCarbonMessage.getProperty(HttpConstants.REQUEST_CONTEXT);
        return requestCtx != null ? requestCtx : createRequestContext(httpCarbonMessage, runtime);
    }

    private static void populatePropertiesForRequestPath(Resource resource, HttpCarbonMessage httpCarbonMessage,
                                                         BObject requestCtx) {
        if (resource instanceof InterceptorResource) {
            requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE, true);
        } else {
            requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE, false);
        }
        int interceptorId = httpCarbonMessage.getProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX) == null
                ? 0 : (int) httpCarbonMessage.getProperty(HttpConstants.REQUEST_INTERCEPTOR_INDEX) - 1;
        requestCtx.addNativeData(HttpConstants.REQUEST_INTERCEPTOR_INDEX, interceptorId);
        requestCtx.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, false);
        requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE_TYPE,
                                 HttpConstants.REQUEST_INTERCEPTOR);
    }

    private static BObject createRequest(HttpCarbonMessage httpCarbonMessage, BObject entityObj) {
        BObject inRequest = ValueCreatorUtils.createRequestObject();
        // Reuse the entity object in case it is consumed by an interceptor
        BObject inRequestEntity = entityObj == null ? ValueCreatorUtils.createEntityObject() : entityObj;
        HttpUtil.populateInboundRequest(inRequest, inRequestEntity, httpCarbonMessage);
        return inRequest;
    }

    static BObject getCaller(Resource resource, HttpCarbonMessage httpCarbonMessage,
                             BMap<BString, Object> endpointConfig) {
        String resourceAccessor = resource.getBalResource().getAccessor().toUpperCase(Locale.getDefault());
        final BObject httpCaller = Objects.isNull(httpCarbonMessage.getProperty(HttpConstants.CALLER)) ?
                ValueCreatorUtils.createCallerObject(httpCarbonMessage, resourceAccessor) :
                (BObject) httpCarbonMessage.getProperty(HttpConstants.CALLER);
        Object currentResourceAccessor = httpCaller.get(HttpConstants.RESOURCE_ACCESSOR);
        if (Objects.isNull(currentResourceAccessor) ||
                HttpUtil.isDefaultResource(((BString) currentResourceAccessor).getValue())) {
            httpCaller.set(HttpConstants.RESOURCE_ACCESSOR, StringUtils.fromString(resourceAccessor));
        }
        HttpUtil.enrichHttpCallerWithConnectionInfo(httpCaller, httpCarbonMessage, resource, endpointConfig);
        HttpUtil.enrichHttpCallerWithNativeData(httpCaller, httpCarbonMessage, endpointConfig);
        httpCarbonMessage.setProperty(HttpConstants.CALLER, httpCaller);
        return httpCaller;
    }

    static BObject createRequestContext(HttpCarbonMessage httpCarbonMessage, Runtime runtime) {
        BObject requestContext = ValueCreatorUtils.createRequestContextObject();
        String authHeader = httpCarbonMessage.getHeader(AUTHORIZATION_HEADER);
        if (Objects.nonNull(authHeader) && authHeader.startsWith(BEARER_AUTHORIZATION_HEADER)) {
            addJwtValuesToRequestContext(runtime, requestContext, authHeader);
        }
        BArray interceptors = httpCarbonMessage.getProperty(HttpConstants.INTERCEPTORS) instanceof BArray ?
                              (BArray) httpCarbonMessage.getProperty(HttpConstants.INTERCEPTORS) : null;
        requestContext.addNativeData(HttpConstants.INTERCEPTORS, interceptors);
        requestContext.addNativeData(HttpConstants.TARGET_SERVICE, httpCarbonMessage.getProperty(
                                     HttpConstants.TARGET_SERVICE));
        requestContext.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, false);
        httpCarbonMessage.setProperty(HttpConstants.REQUEST_CONTEXT, requestContext);
        return requestContext;
    }

    private static void addJwtValuesToRequestContext(Runtime runtime, BObject requestContext, String authHeader) {
        Object decodedJwt = invokeJwtDecode(runtime, authHeader);
        if (Objects.nonNull(decodedJwt)) {
            BMap requestCtxMembers = requestContext.getMapValue(REQUEST_CTX_MEMBERS);
            requestCtxMembers.put(JWT_INFORMATION, decodedJwt);
        }
    }

    private static Object invokeJwtDecode(Runtime runtime, String authHeader) {
        final Object[] jwtInformation = new Object[1];
        String[] splitValues = authHeader.split(WHITESPACE);
        if (splitValues.length != 2) {
            return null;
        }
        try {
            Object result = runtime.call(ValueCreator.createObjectValue(ModuleUtils.getHttpPackage(),
                    JWT_DECODER_CLASS_NAME), JWT_DECODE_METHOD_NAME, StringUtils.fromString(splitValues[1]));
            if (!(result instanceof Exception)) {
                jwtInformation[0] = result;
            }
        } catch (BError error) {
            // ignore error
        }
        return jwtInformation[0];
    }

    static BError createError() {
        return ErrorCreator.createError(StringUtils.fromString("new error"));
    }

    private static Object createHeadersObject(BObject inRequest) {
        BObject headers = ValueCreatorUtils.createHeadersObject();
        headers.set(HttpConstants.HEADER_REQUEST_FIELD, inRequest);
        return headers;
    }

    public static boolean shouldDiffer(Resource resource) {
        return (resource != null && resource.getParamHandler().isPayloadBindingRequired());
    }

    private HttpDispatcher() {
    }
}
