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
package org.ballerinalang.net.http;

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BXml;
import io.netty.handler.codec.http.HttpHeaderNames;
import org.ballerinalang.langlib.value.CloneWithType;
import org.ballerinalang.mime.util.EntityBodyHandler;
import org.ballerinalang.net.http.signature.AllQueryParams;
import org.ballerinalang.net.http.signature.NonRecurringParam;
import org.ballerinalang.net.http.signature.ParamHandler;
import org.ballerinalang.net.http.signature.Parameter;
import org.ballerinalang.net.http.signature.PayloadParam;
import org.ballerinalang.net.http.signature.QueryParam;
import org.ballerinalang.net.transport.message.HttpCarbonMessage;
import org.ballerinalang.net.uri.URIUtil;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URLDecoder;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.runtime.api.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.DECIMAL_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.STRING_TAG;
import static org.ballerinalang.mime.util.MimeConstants.REQUEST_ENTITY_FIELD;
import static org.ballerinalang.net.http.HttpConstants.DEFAULT_HOST;

/**
 * {@code HttpDispatcher} is responsible for dispatching incoming http requests to the correct resource.
 *
 * @since 0.94
 */
public class HttpDispatcher {

    private static final ArrayType INT_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_INT);
    private static final ArrayType FLOAT_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_FLOAT);
    private static final ArrayType BOOLEAN_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_BOOLEAN);
    private static final ArrayType DECIMAL_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_DECIMAL);

    public static HttpService findService(HTTPServicesRegistry servicesRegistry, HttpCarbonMessage inboundReqMsg) {
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

            HttpService service = servicesOnInterface.get(basePath);
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
            HttpService service = HttpDispatcher.findService(servicesRegistry, inboundMessage);
            if (service == null) {
                throw new BallerinaConnectorException("no Service found to handle the service request");
                // Finer details of the errors are thrown from the dispatcher itself, Ideally we shouldn't get here.
            }

            // Find the Resource
            return HttpResourceDispatcher.findResource(service, inboundMessage);
        } catch (Exception e) {
            throw new BallerinaConnectorException(e.getMessage());
        }
    }

    public static Object[] getSignatureParameters(HttpResource httpResource, HttpCarbonMessage httpCarbonMessage,
                                                  BMap<BString, Object> endpointConfig) {
        BObject inRequest = null;
        BObject httpCaller = createCaller(httpResource, httpCarbonMessage, endpointConfig);
        ParamHandler paramHandler = httpResource.getParamHandler();
        int sigParamCount = httpResource.getBalResource().getParameterTypes().length;
        Object[] paramFeed = new Object[sigParamCount * 2];
        int pathParamCount = paramHandler.getPathParamTokens().length;
        // Path params are located initially in the signature before the other user provided signature params
        if (pathParamCount != 0) {
            // populate path params
            HttpResourceArguments resourceArgumentValues =
                    (HttpResourceArguments) httpCarbonMessage.getProperty(HttpConstants.RESOURCE_ARGS);
            updateWildcardToken(httpResource.getWildcardToken(), resourceArgumentValues.getMap());
            populatePathParams(httpResource, paramFeed, resourceArgumentValues, pathParamCount);
        }
        // Following was written assuming that they are validated
        for (Parameter param : paramHandler.getOtherParamList()) {
            String typeName = param.getTypeName();
            switch (typeName) {
                case HttpConstants.CALLER:
                    int index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = httpCaller;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.REQUEST:
                    if (inRequest == null) {
                        inRequest = createRequest(httpCarbonMessage);
                    }
                    index = ((NonRecurringParam) param).getIndex();
                    paramFeed[index++] = inRequest;
                    paramFeed[index] = true;
                    break;
                case HttpConstants.QUERY_PARAM:
                    populateQueryParams(httpCarbonMessage, paramHandler, paramFeed, (AllQueryParams) param);
                    break;
                case HttpConstants.PAYLOAD_PARAM:
                    if (inRequest == null) {
                        inRequest = createRequest(httpCarbonMessage);
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
                                            Object[] paramFeed, AllQueryParams queryParams) {
        BMap<BString, Object> urlQueryParams = paramHandler
                .getQueryParams(httpCarbonMessage.getProperty(HttpConstants.RAW_QUERY_STR));
        for (QueryParam queryParam : queryParams.getAllQueryParams()) {
            String token = queryParam.getToken();
            int index = queryParam.getIndex();
            Object queryValue = urlQueryParams.get(StringUtils.fromString(token));
            if (queryValue == null) {
                if (queryParam.isNilable()) {
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
                default:
                    throw new BallerinaConnectorException("Illegal state error: unexpected param type");
            }
        }
        return arrayValue;
    }

    private static BObject createRequest(HttpCarbonMessage httpCarbonMessage) {
        BObject inRequest = ValueCreatorUtils.createRequestObject();
        BObject inRequestEntity = ValueCreatorUtils.createEntityObject();
        HttpUtil.populateInboundRequest(inRequest, inRequestEntity, httpCarbonMessage);
        return inRequest;
    }

    static BObject createCaller(HttpResource httpResource, HttpCarbonMessage httpCarbonMessage,
                                        BMap<BString, Object> endpointConfig) {
        BObject httpCaller = ValueCreatorUtils.createCallerObject();
        HttpUtil.enrichHttpCallerWithConnectionInfo(httpCaller, httpCarbonMessage, httpResource, endpointConfig);
        HttpUtil.enrichHttpCallerWithNativeData(httpCaller, httpCarbonMessage, endpointConfig);
        httpCarbonMessage.setProperty(HttpConstants.CALLER, httpCaller);
        return httpCaller;
    }

    private static void populatePathParams(HttpResource httpResource, Object[] paramFeed,
                                           HttpResourceArguments resourceArgumentValues, int pathParamCount) {

        String[] pathParamTokens = Arrays.copyOfRange(httpResource.getBalResource().getParamNames(), 0, pathParamCount);
        int actualSignatureParamIndex = 0;
        for (String paramName : pathParamTokens) {
            String argumentValue = resourceArgumentValues.getMap().get(paramName);
            try {
                argumentValue = URLDecoder.decode(argumentValue, "UTF-8");
            } catch (UnsupportedEncodingException e) {
                // we can simply ignore and send the value to application and let the
                // application deal with the value.
            }
            int paramIndex = actualSignatureParamIndex * 2;
            Type pathParamType = httpResource.getBalResource().getParameterTypes()[actualSignatureParamIndex++];

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

    private static void updateWildcardToken(String wildcardToken, Map<String, String> arguments) {
        if (wildcardToken == null) {
            return;
        }
        String wildcardPathSegment = arguments.get(HttpConstants.EXTRA_PATH_INFO);
        arguments.putIfAbsent(wildcardToken, wildcardPathSegment);
    }

    private static void populatePayloadParam(BObject inRequest, HttpCarbonMessage httpCarbonMessage,
                                             Object[] paramFeed, PayloadParam payloadParam) {
        BObject inRequestEntity = (BObject) inRequest.get(REQUEST_ENTITY_FIELD);
        HttpUtil.populateEntityBody(inRequest, inRequestEntity, true, true);
        int index = payloadParam.getIndex();
        Type payloadType = payloadParam.getType();
        try {
            switch (payloadType.getTag()) {
                case STRING_TAG:
                    BString stringDataSource = EntityBodyHandler.constructStringDataSource(inRequestEntity);
                    EntityBodyHandler.addMessageDataSource(inRequestEntity, stringDataSource);
                    paramFeed[index++] = stringDataSource;
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
                    if (((ArrayType) payloadType).getElementType().getTag() == TypeTags.BYTE_TAG) {
                        BArray blobDataSource = EntityBodyHandler.constructBlobDataSource(inRequestEntity);
                        EntityBodyHandler.addMessageDataSource(inRequestEntity, blobDataSource);
                        paramFeed[index++] = blobDataSource;
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
                        //Do nothing
            }
            paramFeed[index] = true;
        } catch (BError | IOException ex) {
            httpCarbonMessage.setHttpStatusCode(Integer.parseInt(HttpConstants.HTTP_BAD_REQUEST));
            throw new BallerinaConnectorException("data binding failed: " + ex.toString());
        }
    }

    private static Object getRecordEntity(BObject inRequestEntity, Type entityBodyType) {
        Object result = getRecord(entityBodyType, getBJsonValue(inRequestEntity));
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

    public static boolean shouldDiffer(HttpResource httpResource) {
        return (httpResource != null && httpResource.getParamHandler().isPayloadBindingRequired());
    }

    private HttpDispatcher() {
    }
}
