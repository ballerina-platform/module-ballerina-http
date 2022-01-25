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

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BXml;
import io.ballerina.stdlib.http.api.service.signature.AllHeaderParams;
import io.ballerina.stdlib.http.api.service.signature.AllQueryParams;
import io.ballerina.stdlib.http.api.service.signature.HeaderParam;
import io.ballerina.stdlib.http.api.service.signature.NonRecurringParam;
import io.ballerina.stdlib.http.api.service.signature.ParamHandler;
import io.ballerina.stdlib.http.api.service.signature.Parameter;
import io.ballerina.stdlib.http.api.service.signature.PayloadParam;
import io.ballerina.stdlib.http.api.service.signature.QueryParam;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.URIUtil;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaders;
import org.ballerinalang.langlib.value.CloneReadOnly;
import org.ballerinalang.langlib.value.CloneWithType;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.DECIMAL_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.MAP_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
import static io.ballerina.stdlib.http.api.HttpConstants.DEFAULT_HOST;
import static io.ballerina.stdlib.http.api.HttpConstants.EXTRA_PATH_INDEX;
import static io.ballerina.stdlib.mime.util.MimeConstants.REQUEST_ENTITY_FIELD;

/**
 * {@code HttpDispatcher} is responsible for dispatching incoming http requests to the correct resource.
 *
 * @since 0.94
 */
public class HttpDispatcher {

    private static final MapType MAP_TYPE = TypeCreator.createMapType(PredefinedTypes.TYPE_JSON);
    private static final ArrayType INT_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_INT);
    private static final ArrayType FLOAT_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_FLOAT);
    private static final ArrayType BOOLEAN_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_BOOLEAN);
    private static final ArrayType DECIMAL_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_DECIMAL);
    private static final ArrayType MAP_ARR = TypeCreator.createArrayType(TypeCreator.createMapType(
            PredefinedTypes.TYPE_JSON));
    private static final MapType STRING_MAP = TypeCreator.createMapType(PredefinedTypes.TYPE_STRING);

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
                inboundReqMsg.setHttpStatusCode(404);
                String localAddress = inboundReqMsg.getProperty(HttpConstants.LOCAL_ADDRESS).toString();
                throw new BallerinaConnectorException("no service has registered for listener : " + localAddress);
            }

            String rawUri = (String) inboundReqMsg.getProperty(HttpConstants.TO);
            Map<String, Map<String, String>> matrixParams = new HashMap<>();
            String uriWithoutMatrixParams = URIUtil.extractMatrixParams(rawUri, matrixParams);

            URI validatedUri = getValidatedURI(uriWithoutMatrixParams);

            String basePath = servicesRegistry.findTheMostSpecificBasePath(validatedUri.getRawPath(),
                    servicesOnInterface, sortedServiceURIs);

            if (basePath == null) {
                inboundReqMsg.setHttpStatusCode(404);
                throw new BallerinaConnectorException("no matching service found for path : " +
                        validatedUri.getRawPath());
            }

            HttpService service = servicesOnInterface.get(basePath);
            if (!forInterceptors) {
                setInboundReqProperties(inboundReqMsg, validatedUri, basePath);
                inboundReqMsg.setProperty(HttpConstants.RAW_URI, rawUri);
                inboundReqMsg.setProperty(HttpConstants.TO, uriWithoutMatrixParams);
                inboundReqMsg.setProperty(HttpConstants.MATRIX_PARAMS, matrixParams);
            }
            return service;
        } catch (Exception e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
    }

    public static InterceptorService findInterceptorService(HTTPInterceptorServicesRegistry servicesRegistry,
                                                                HttpCarbonMessage inboundReqMsg) {
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
                inboundReqMsg.setHttpStatusCode(404);
                String localAddress = inboundReqMsg.getProperty(HttpConstants.LOCAL_ADDRESS).toString();
                throw new BallerinaConnectorException("no service has registered for listener : " + localAddress);
            }

            String rawUri = (String) inboundReqMsg.getProperty(HttpConstants.TO);
            inboundReqMsg.setProperty(HttpConstants.RAW_URI, rawUri);
            Map<String, Map<String, String>> matrixParams = new HashMap<>();
            String uriWithoutMatrixParams = URIUtil.extractMatrixParams(rawUri, matrixParams);

            inboundReqMsg.setProperty(HttpConstants.TO, uriWithoutMatrixParams);
            inboundReqMsg.setProperty(HttpConstants.MATRIX_PARAMS, matrixParams);

            URI validatedUri = getValidatedURI(uriWithoutMatrixParams);

            String basePath = servicesRegistry.findTheMostSpecificBasePath(validatedUri.getRawPath(),
                    servicesOnInterface, sortedServiceURIs);

            if (basePath == null) {
                inboundReqMsg.setHttpStatusCode(404);
                throw new BallerinaConnectorException("no matching service found for path : " +
                        validatedUri.getRawPath());
            }

            InterceptorService service = servicesOnInterface.get(basePath);
            setInboundReqProperties(inboundReqMsg, validatedUri, basePath);
            return service;
        } catch (Exception e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
    }

    private static void setInboundReqProperties(HttpCarbonMessage inboundReqMsg, URI requestUri, String basePath) {
        String subPath = URIUtil.getSubPath(requestUri.getRawPath(), basePath);
        inboundReqMsg.setProperty(HttpConstants.BASE_PATH, basePath);
        inboundReqMsg.setProperty(HttpConstants.SUB_PATH, subPath);
        inboundReqMsg.setProperty(HttpConstants.QUERY_STR, requestUri.getQuery());
        //store query params comes with request as it is
        inboundReqMsg.setProperty(HttpConstants.RAW_QUERY_STR, requestUri.getRawQuery());
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
     * @param inboundMessage incoming message.
     * @return matching resource.
     */
    public static HttpResource findResource(HTTPServicesRegistry servicesRegistry, HttpCarbonMessage inboundMessage) {
        String protocol = (String) inboundMessage.getProperty(HttpConstants.PROTOCOL);
        if (protocol == null) {
            throw new BallerinaConnectorException("protocol not defined in the incoming request");
        }

        try {
            // Find the Service TODO can be improved
            HttpService service = HttpDispatcher.findService(servicesRegistry, inboundMessage, false);
            if (service == null) {
                throw new BallerinaConnectorException("no Service found to handle the service request");
                // Finer details of the errors are thrown from the dispatcher itself, Ideally we shouldn't get here.
            }

            // Find the Resource
            return (HttpResource) ResourceDispatcher.findResource(service, inboundMessage);
        } catch (Exception e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
    }

    public static InterceptorResource findInterceptorResource(HTTPInterceptorServicesRegistry servicesRegistry,
                                                                  HttpCarbonMessage inboundMessage) {
        String protocol = (String) inboundMessage.getProperty(HttpConstants.PROTOCOL);
        if (protocol == null) {
            throw new BallerinaConnectorException("protocol not defined in the incoming request");
        }

        try {
            // Find the Service TODO can be improved
            InterceptorService service = HttpDispatcher.findInterceptorService(servicesRegistry, inboundMessage);
            if (service == null) {
                throw new BallerinaConnectorException("no Service found to handle the service request");
                // Finer details of the errors are thrown from the dispatcher itself, Ideally we shouldn't get here.
            }

            // Find the Resource
            return (InterceptorResource) ResourceDispatcher.findResource(service, inboundMessage);
        } catch (Exception e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
    }

    public static Object[] getSignatureParameters(Resource resource, HttpCarbonMessage httpCarbonMessage,
                                                  BMap<BString, Object> endpointConfig) {
        BObject inRequest = null;
        // Getting the same caller, request context and entity object to pass through interceptor services
        BObject requestCtx = (BObject) httpCarbonMessage.getProperty(HttpConstants.REQUEST_CONTEXT);
        BObject entityObj = (BObject) httpCarbonMessage.getProperty(HttpConstants.ENTITY_OBJ);
        BError error = (BError) httpCarbonMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_ERROR);
        BObject httpCaller = getCaller(resource, httpCarbonMessage, endpointConfig);
        ParamHandler paramHandler = resource.getParamHandler();
        int sigParamCount = resource.getBalResource().getParameterTypes().length;
        Object[] paramFeed = new Object[sigParamCount * 2];
        int pathParamCount = paramHandler.getPathParamTokenLength();
        boolean treatNilableAsOptional = resource.isTreatNilableAsOptional();
        // Path params are located initially in the signature before the other user provided signature params
        if (pathParamCount != 0) {
            // populate path params
            HttpResourceArguments resourceArgumentValues =
                    (HttpResourceArguments) httpCarbonMessage.getProperty(HttpConstants.RESOURCE_ARGS);
            updateWildcardToken(resource.getWildcardToken(), pathParamCount - 1, resourceArgumentValues.getMap());
            populatePathParams(resource, paramFeed, resourceArgumentValues, pathParamCount);
        }
        // Following was written assuming that they are validated
        for (Parameter param : paramHandler.getOtherParamList()) {
            String typeName = param.getTypeName();
            switch (typeName) {
                case HttpConstants.CALLER:
                    int index = ((NonRecurringParam) param).getIndex();
                    httpCaller.set(HttpConstants.CALLER_PRESENT_FIELD, true);
                    paramFeed[index++] = httpCaller;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.REQUEST_CONTEXT:
                    if (requestCtx == null) {
                        requestCtx = createRequestContext(httpCarbonMessage, endpointConfig);
                    }
                    if (resource instanceof InterceptorResource) {
                        requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE, true);
                    } else {
                        requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE, false);
                    }
                    int interceptorId = httpCarbonMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_INDEX) == null
                            ? 0 : (int) httpCarbonMessage.getProperty(HttpConstants.INTERCEPTOR_SERVICE_INDEX) - 1;
                    requestCtx.addNativeData(HttpConstants.INTERCEPTOR_SERVICE_INDEX, interceptorId);
                    requestCtx.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, false);
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
                    populateQueryParams(httpCarbonMessage, paramHandler, paramFeed, (AllQueryParams) param,
                            treatNilableAsOptional);
                    break;
                case HttpConstants.HEADER_PARAM:
                    populateHeaderParams(httpCarbonMessage, paramFeed, (AllHeaderParams) param, treatNilableAsOptional);
                    break;
                case HttpConstants.PAYLOAD_PARAM:
                    if (inRequest == null) {
                        inRequest = createRequest(httpCarbonMessage, entityObj);
                    }
                    populatePayloadParam(inRequest, httpCarbonMessage, paramFeed, (PayloadParam) param);
                    break;
                default:
                    break;
            }
        }
        return paramFeed;
    }

    private static void populateQueryParams(HttpCarbonMessage httpCarbonMessage, ParamHandler paramHandler,
                                    Object[] paramFeed, AllQueryParams queryParams, boolean treatNilableAsOptional) {
        BMap<BString, Object> urlQueryParams = paramHandler
                .getQueryParams(httpCarbonMessage.getProperty(HttpConstants.RAW_QUERY_STR));
        for (QueryParam queryParam : queryParams.getAllQueryParams()) {
            String token = queryParam.getToken();
            int index = queryParam.getIndex();
            boolean queryExist = urlQueryParams.containsKey(StringUtils.fromString(token));
            Object queryValue = urlQueryParams.get(StringUtils.fromString(token));
            if (queryValue == null) {
                if (queryParam.isNilable() && (treatNilableAsOptional || queryExist)) {
                    paramFeed[index++] = null;
                    paramFeed[index] = true;
                    continue;
                } else {
                    httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                    throw new BallerinaConnectorException("no query param value found for '" + token + "'");
                }
            }
            try {
                BArray queryValueArr = (BArray) queryValue;
                if (queryParam.getTypeTag() == ARRAY_TAG) {
                    int elementTypeTag = ((ArrayType) queryParam.getType()).getElementType().getTag();
                    paramFeed[index++] = castParamArray(elementTypeTag, queryValueArr.getStringArray());
                } else {
                    paramFeed[index++] = castParam(queryParam.getTypeTag(), (queryValueArr).getBString(0).getValue());
                }
                paramFeed[index] = true;
            } catch (Exception ex) {
                throw new BallerinaConnectorException("Error in casting query param : " + ex.getMessage());
            }
        }
    }

    private static void populateHeaderParams(HttpCarbonMessage httpCarbonMessage, Object[] paramFeed,
                                             AllHeaderParams headerParams, boolean treatNilableAsOptional) {
        HttpHeaders httpHeaders = httpCarbonMessage.getHeaders();
        for (HeaderParam headerParam : headerParams.getAllHeaderParams()) {
            String token = headerParam.getHeaderName();
            int index = headerParam.getIndex();
            List<String> headerValues = httpHeaders.getAll(token);
            if (headerValues.isEmpty()) {
                if (headerParam.isNilable() && treatNilableAsOptional) {
                    paramFeed[index++] = null;
                    paramFeed[index] = true;
                    continue;
                } else {
                    httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                    throw new BallerinaConnectorException("no header value found for '" + token + "'");
                }
            }
            if (headerValues.size() == 1 && headerValues.get(0).isEmpty()) {
                if (headerParam.isNilable()) {
                    paramFeed[index++] = null;
                    paramFeed[index] = true;
                    continue;
                } else {
                    httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                    throw new BallerinaConnectorException("no header value found for '" + token + "'");
                }
            }
            if (headerParam.getTypeTag() == ARRAY_TAG) {
                String[] headerArray = headerValues.toArray(new String[0]);
                paramFeed[index++] = StringUtils.fromStringArray(headerArray);
            } else {
                paramFeed[index++] = StringUtils.fromString(headerValues.get(0));
            }
            paramFeed[index] = true;
        }
    }

    private static Object castParam(int targetParamTypeTag, String argValue) {
        switch (targetParamTypeTag) {
            case INT_TAG:
                return Long.parseLong(argValue);
            case FLOAT_TAG:
                return Double.parseDouble(argValue);
            case BOOLEAN_TAG:
                return Boolean.parseBoolean(argValue);
            case DECIMAL_TAG:
                return ValueCreator.createDecimalValue(argValue);
            case MAP_TAG:
                Object json = JsonUtils.parse(argValue);
                return JsonUtils.convertJSONToMap(json, MAP_TYPE);
            default:
                return StringUtils.fromString(argValue);
        }
    }

    private static Object castParamArray(int targetElementTypeTag, String[] argValueArr) {
        if (targetElementTypeTag == INT_TAG) {
            return getBArray(argValueArr, INT_ARR, targetElementTypeTag);
        } else if (targetElementTypeTag == FLOAT_TAG) {
            return getBArray(argValueArr, FLOAT_ARR, targetElementTypeTag);
        } else if (targetElementTypeTag == BOOLEAN_TAG) {
            return getBArray(argValueArr, BOOLEAN_ARR, targetElementTypeTag);
        } else if (targetElementTypeTag == DECIMAL_TAG) {
            return getBArray(argValueArr, DECIMAL_ARR, targetElementTypeTag);
        } else if (targetElementTypeTag == MAP_TAG) {
            return getBArray(argValueArr, MAP_ARR, targetElementTypeTag);
        } else {
            return StringUtils.fromStringArray(argValueArr);
        }
    }

    private static BArray getBArray(String[] valueArray, ArrayType arrayType, int elementTypeTag) {
        BArray arrayValue = ValueCreator.createArrayValue(arrayType);
        int index = 0;
        for (String element : valueArray) {
            switch (elementTypeTag) {
                case INT_TAG:
                    arrayValue.add(index++, Long.parseLong(element));
                    break;
                case FLOAT_TAG:
                    arrayValue.add(index++, Double.parseDouble(element));
                    break;
                case BOOLEAN_TAG:
                    arrayValue.add(index++, Boolean.parseBoolean(element));
                    break;
                case DECIMAL_TAG:
                    arrayValue.add(index++, ValueCreator.createDecimalValue(element));
                    break;
                case MAP_TAG:
                    Object json = JsonUtils.parse(element);
                    arrayValue.add(index++, JsonUtils.convertJSONToMap(json, MAP_TYPE));
                    break;
                default:
                    throw new BallerinaConnectorException("Illegal state error: unexpected param type");
            }
        }
        return arrayValue;
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
        final BObject httpCaller = httpCarbonMessage.getProperty(HttpConstants.CALLER) == null ?
                ValueCreatorUtils.createCallerObject(httpCarbonMessage) :
                (BObject) httpCarbonMessage.getProperty(HttpConstants.CALLER);
        HttpUtil.enrichHttpCallerWithConnectionInfo(httpCaller, httpCarbonMessage, resource, endpointConfig);
        HttpUtil.enrichHttpCallerWithNativeData(httpCaller, httpCarbonMessage, endpointConfig);
        httpCarbonMessage.setProperty(HttpConstants.CALLER, httpCaller);
        return httpCaller;
    }

    static BObject createRequestContext(HttpCarbonMessage httpCarbonMessage, BMap<BString, Object> endpointConfig) {
        BObject requestContext = ValueCreatorUtils.createRequestContextObject();
        BArray interceptors = httpCarbonMessage.getProperty(HttpConstants.INTERCEPTORS) instanceof BArray ?
                              (BArray) httpCarbonMessage.getProperty(HttpConstants.INTERCEPTORS) : null;
        requestContext.addNativeData(HttpConstants.INTERCEPTORS, interceptors);
        requestContext.addNativeData(HttpConstants.TARGET_SERVICE, httpCarbonMessage.getProperty(
                                     HttpConstants.TARGET_SERVICE));
        requestContext.addNativeData(HttpConstants.REQUEST_CONTEXT_NEXT, false);
        httpCarbonMessage.setProperty(HttpConstants.REQUEST_CONTEXT, requestContext);
        return requestContext;
    }

    static BError createError() {
        return ErrorCreator.createError(StringUtils.fromString("new error"));
    }

    private static Object createHeadersObject(BObject inRequest) {
        BObject headers = ValueCreatorUtils.createHeadersObject();
        headers.set(HttpConstants.HEADER_REQUEST_FIELD, inRequest);
        return headers;
    }

    private static void populatePathParams(Resource resource, Object[] paramFeed,
                                           HttpResourceArguments resourceArgumentValues, int pathParamCount) {

        String[] pathParamTokens = Arrays.copyOfRange(resource.getBalResource().getParamNames(), 0, pathParamCount);
        int actualSignatureParamIndex = 0;
        for (String paramName : pathParamTokens) {
            String argumentValue = resourceArgumentValues.getMap().get(paramName).get(actualSignatureParamIndex);
            try {
                argumentValue = URLDecoder.decode(argumentValue, "UTF-8");
            } catch (UnsupportedEncodingException e) {
                // we can simply ignore and send the value to application and let the
                // application deal with the value.
            }
            int paramIndex = actualSignatureParamIndex * 2;
            Type pathParamType = resource.getBalResource().getParameterTypes()[actualSignatureParamIndex++];

            try {
                if (pathParamType.getTag() == ARRAY_TAG) {
                    int elementTypeTag = ((ArrayType) pathParamType).getElementType().getTag();
                    String[] segments = argumentValue.substring(1).split(HttpConstants.SINGLE_SLASH);
                    paramFeed[paramIndex++] = castParamArray(elementTypeTag, segments);
                } else {
                    paramFeed[paramIndex++] = castParam(pathParamType.getTag(), argumentValue);
                }
                paramFeed[paramIndex] = true;
            } catch (Exception ex) {
                throw new BallerinaConnectorException("Error in casting path param : " + ex.getMessage());
            }
        }
    }

    private static void updateWildcardToken(String wildcardToken, int wildCardIndex,
                                            Map<String, Map<Integer, String>> arguments) {
        if (wildcardToken == null) {
            return;
        }
        String wildcardPathSegment = arguments.get(HttpConstants.EXTRA_PATH_INFO).get(EXTRA_PATH_INDEX);
        if (arguments.containsKey(wildcardToken)) {
            Map<Integer, String> indexValueMap = arguments.get(wildcardToken);
            indexValueMap.put(wildCardIndex, wildcardPathSegment);
        } else {
            arguments.put(wildcardToken, Collections.singletonMap(wildCardIndex, wildcardPathSegment));
        }
    }

    private static void populatePayloadParam(BObject inRequest, HttpCarbonMessage httpCarbonMessage,
                                             Object[] paramFeed, PayloadParam payloadParam) {
        BObject inRequestEntity = (BObject) inRequest.get(REQUEST_ENTITY_FIELD);
        HttpUtil.populateEntityBody(inRequest, inRequestEntity, true, true);
        int index = payloadParam.getIndex();
        Type payloadType = payloadParam.getType();
        Object dataSource = EntityBodyHandler.getMessageDataSource(inRequestEntity);
        // Check if datasource is already available from interceptor service read
        // TODO : Validate the dataSource type with payload type and populate
        if (dataSource != null) {
            try {
                switch (payloadType.getTag()) {
                    case ARRAY_TAG:
                        if (((ArrayType) payloadType).getElementType().getTag() == TypeTags.BYTE_TAG) {
                            paramFeed[index++] = dataSource;
                        } else if (((ArrayType) payloadType).getElementType().getTag() == TypeTags.RECORD_TYPE_TAG) {
                            paramFeed[index++] = getRecordEntity(inRequestEntity, payloadType);
                        } else {
                            throw new BallerinaConnectorException("Incompatible Element type found inside an array " +
                                    ((ArrayType) payloadType).getElementType().getName());
                        }
                        break;
                    case TypeTags.RECORD_TYPE_TAG:
                        paramFeed[index++] = getRecordEntity(inRequestEntity, payloadType);
                        break;
                    default:
                        paramFeed[index++] = dataSource;
                }
            } catch (BError ex) {
                httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                throw new BallerinaConnectorException("data binding failed: " + ex.toString());
            }
            paramFeed[index] = true;
        } else {
            try {
                index = populateParamFeed(paramFeed, inRequestEntity, index, payloadType);
                paramFeed[index] = true;
                // Set the entity obj in case it is read by an interceptor
                httpCarbonMessage.setProperty(HttpConstants.ENTITY_OBJ, inRequestEntity);
            } catch (BError | IOException ex) {
                httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
                throw new BallerinaConnectorException("data binding failed: " + ex.toString());
            }
        }
    }

    private static int populateParamFeed(Object[] paramFeed, BObject inRequestEntity, int index, Type payloadType)
            throws IOException {
        switch (payloadType.getTag()) {
            case STRING_TAG:
                BString stringDataSource = EntityBodyHandler.constructStringDataSource(inRequestEntity);
                EntityBodyHandler.addMessageDataSource(inRequestEntity, stringDataSource);
                paramFeed[index++] = stringDataSource;
                break;
            case MAP_TAG:
                Type constrainedType = ((MapType) payloadType).getConstrainedType();
                if (constrainedType.getTag() != STRING_TAG) {
                    throw ErrorCreator.createError(StringUtils.fromString(
                            "invalid map constrained type. Expected: 'map<string>'"));
                }
                stringDataSource = EntityBodyHandler.constructStringDataSource(inRequestEntity);
                EntityBodyHandler.addMessageDataSource(inRequestEntity, stringDataSource);
                paramFeed[index++] = getFormParamMap(stringDataSource);
                break;
            case TypeTags.JSON_TAG:
                Object bjson = EntityBodyHandler.constructJsonDataSource(inRequestEntity);
                EntityBodyHandler.addJsonMessageDataSource(inRequestEntity, bjson);
                paramFeed[index++] = bjson;
                break;
            case TypeTags.XML_TAG:
                BXml bxml = EntityBodyHandler.constructXmlDataSource(inRequestEntity);
                EntityBodyHandler.addMessageDataSource(inRequestEntity, bxml);
                paramFeed[index++] = bxml;
                break;
            case ARRAY_TAG:
                Type elementType = ((ArrayType) payloadType).getElementType();
                if (elementType.getTag() == TypeTags.BYTE_TAG) {
                    BArray blobDataSource = EntityBodyHandler.constructBlobDataSource(inRequestEntity);
                    EntityBodyHandler.addMessageDataSource(inRequestEntity, blobDataSource);
                    paramFeed[index++] = blobDataSource;
                } else if (elementType.getTag() == TypeTags.RECORD_TYPE_TAG) {
                    paramFeed[index++] = getRecordEntity(inRequestEntity, payloadType);
                } else if (elementType.getTag() == TypeTags.INTERSECTION_TAG) {
                    // Assumes that only the byte[] and record[] are supported and intersected with readonly
                    paramFeed[index++] = getCloneReadOnlyValue(getRecordEntity(inRequestEntity, payloadType));
                } else {
                    throw new BallerinaConnectorException("Incompatible Element type found inside an array " +
                            elementType.getName());
                }
                break;
            case TypeTags.RECORD_TYPE_TAG:
                paramFeed[index++] = getRecordEntity(inRequestEntity, payloadType);
                break;
            case TypeTags.INTERSECTION_TAG:
                // Assumes that only intersected with readonly
                Type pureType = ((IntersectionType) payloadType).getEffectiveType();
                index = populateParamFeed(paramFeed, inRequestEntity, index, pureType);
                paramFeed[index - 1] = getCloneReadOnlyValue(paramFeed[index - 1]);
                break;
            default:
                //Do nothing
        }
        return index;
    }

    private static Object getRecordEntity(BObject inRequestEntity, Type entityBodyType) {
        Object bjson = EntityBodyHandler.getMessageDataSource(inRequestEntity) == null ? getBJsonValue(inRequestEntity)
                : EntityBodyHandler.getMessageDataSource(inRequestEntity);
        Object result = getRecord(entityBodyType, bjson);
        if (result instanceof BError) {
            throw (BError) result;
        }
        return result;
    }

    /**
     * Convert a json to the relevant record type.
     *
     * @param entityBodyType Represents entity body type
     * @param bjson          Represents the json value that needs to be converted
     * @return the relevant ballerina record or object
     */
    private static Object getRecord(Type entityBodyType, Object bjson) {
        try {
            return CloneWithType.convert(entityBodyType, bjson);
        } catch (NullPointerException ex) {
            throw new BallerinaConnectorException("cannot convert payload to record type: " +
                    entityBodyType.getName());
        }
    }

    private static Object getCloneReadOnlyValue(Object bValue) {
        return CloneReadOnly.cloneReadOnly(bValue);
    }

    private static Object getFormParamMap(Object stringDataSource) {
        try {
            String formData = ((BString) stringDataSource).getValue();
            BMap<BString, Object> formParamsMap = ValueCreator.createMapValue(STRING_MAP);
            if (formData.isEmpty()) {
                return formParamsMap;
            }
            Map<String, String> tempParamMap = new HashMap<>();
            String decodedValue = URLDecoder.decode(formData, StandardCharsets.UTF_8);

            if (!decodedValue.contains("=")) {
                throw new BallerinaConnectorException("Datasource does not contain form data");
            }
            String[] formParamValues = decodedValue.split("&");
            for (String formParam : formParamValues) {
                int index = formParam.indexOf('=');
                if (index == -1) {
                    if (!tempParamMap.containsKey(formParam)) {
                        tempParamMap.put(formParam, null);
                    }
                    continue;
                }
                String formParamName = formParam.substring(0, index).trim();
                String formParamValue = formParam.substring(index + 1).trim();
                tempParamMap.put(formParamName, formParamValue);
            }

            for (Map.Entry<String, String> entry : tempParamMap.entrySet()) {
                String entryValue = entry.getValue();
                if (entryValue != null) {
                    formParamsMap.put(StringUtils.fromString(entry.getKey()), StringUtils.fromString(entryValue));
                } else {
                    formParamsMap.put(StringUtils.fromString(entry.getKey()), null);
                }
            }
            return formParamsMap;
        } catch (Exception ex) {
            throw ErrorCreator.createError(
                    StringUtils.fromString("Could not convert payload to map<string>: " + ex.getMessage()));
        }
    }

    /**
     * Given an inbound request entity construct the ballerina json.
     *
     * @param inRequestEntity Represents inbound request entity
     * @return a ballerina json value
     */
    private static Object getBJsonValue(BObject inRequestEntity) {
        Object bjson = EntityBodyHandler.constructJsonDataSource(inRequestEntity);
        EntityBodyHandler.addJsonMessageDataSource(inRequestEntity, bjson);
        return bjson;
    }

    public static boolean shouldDiffer(Resource resource) {
        return (resource != null && resource.getParamHandler().isPayloadBindingRequired());
    }

    private HttpDispatcher() {
    }
}
