/*
 * Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;
import io.ballerina.stdlib.http.uri.URIUtil;
import io.ballerina.stdlib.mime.util.EntityBodyHandler;

import java.util.Objects;

import static io.ballerina.stdlib.http.api.HttpConstants.QUERY_PARAM_MAP;
import static io.ballerina.stdlib.http.api.HttpConstants.TRANSPORT_MESSAGE;
import static io.ballerina.stdlib.http.api.HttpUtil.checkRequestBodySizeHeadersAvailability;
import static io.ballerina.stdlib.mime.util.MimeConstants.REQUEST_ENTITY_FIELD;

/**
 * Utilities related to HTTP request.
 *
 * @since 1.1.0
 */
public class ExternRequest {

    private static final MapType mapType = TypeCreator.createMapType(
            TypeCreator.createArrayType(PredefinedTypes.TYPE_STRING));

    public static BObject createNewEntity(BObject requestObj) {
        return HttpUtil.createNewEntity(requestObj);
    }

    public static void setEntity(BObject requestObj, BObject entityObj) {
        HttpUtil.setEntity(requestObj, entityObj, true, true);
    }

    public static void setEntityAndUpdateContentTypeHeader(BObject requestObj, BObject entityObj) {
        HttpUtil.setEntity(requestObj, entityObj, true, false);
    }

    @SuppressWarnings("unchecked")
    public static BMap<BString, Object> getQueryParams(BObject requestObj) {
        try {
            Object queryParams = requestObj.getNativeData(QUERY_PARAM_MAP);
            if (queryParams != null) {
                return (BMap<BString, Object>) queryParams;
            }
            HttpCarbonMessage httpCarbonMessage = (HttpCarbonMessage) requestObj
                    .getNativeData(HttpConstants.TRANSPORT_MESSAGE);
            BMap<BString, Object> params = ValueCreator.createMapValue(mapType);
            Object rawQueryString = httpCarbonMessage.getProperty(HttpConstants.RAW_QUERY_STR);
            if (rawQueryString != null) {
                URIUtil.populateQueryParamMap((String) rawQueryString, params);
            }
            requestObj.addNativeData(QUERY_PARAM_MAP, params);
            return params;
        } catch (Exception e) {
            throw HttpUtil.createHttpError("error while retrieving query param from message: " + e.getMessage(),
                                           HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }

    public static void setQueryParams(BObject requestObj, BMap<BString, Object> queryParams) {
        try {
            HttpCarbonMessage httpCarbonMessage = (HttpCarbonMessage) requestObj
                    .getNativeData(HttpConstants.TRANSPORT_MESSAGE);
            
            // Build the query string from the map
            String queryString = buildQueryString(queryParams);
            
            // Set the query string in the carbon message
            httpCarbonMessage.setProperty(HttpConstants.RAW_QUERY_STR, queryString);
            
            // Update the cached query params map
            requestObj.addNativeData(QUERY_PARAM_MAP, queryParams);
        } catch (Exception e) {
            throw HttpUtil.createHttpError("error while setting query params: " + e.getMessage(),
                                           HttpErrorType.GENERIC_CLIENT_ERROR);
        }
    }

    @SuppressWarnings("unchecked")
    private static String buildQueryString(BMap<BString, Object> queryParams) {
        if (queryParams == null || queryParams.size() == 0) {
            return "";
        }

        StringBuilder queryString = new StringBuilder();
        for (BString key : queryParams.getKeys()) {
            Object value = queryParams.get(key);
            if (value instanceof io.ballerina.runtime.api.values.BArray) {
                io.ballerina.runtime.api.values.BArray arrayValue = 
                    (io.ballerina.runtime.api.values.BArray) value;
                for (int i = 0; i < arrayValue.size(); i++) {
                    if (queryString.length() > 0) {
                        queryString.append("&");
                    }
                    String encodedKey = URIUtil.encodePathSegment(key.getValue());
                    String valueStr = arrayValue.get(i).toString();
                    String encodedValue = URIUtil.encodePathSegment(valueStr);
                    queryString.append(encodedKey).append("=").append(encodedValue);
                }
            }
        }
        return queryString.toString();
    }

    public static BMap<BString, Object> getMatrixParams(BObject requestObj, BString path) {
        HttpCarbonMessage httpCarbonMessage = HttpUtil.getCarbonMsg(requestObj, null);
        return URIUtil.getMatrixParamsMap(path.getValue(), httpCarbonMessage);
    }

    public static Object getEntity(BObject requestObj) {
        return HttpUtil.getEntity(requestObj, true, true, true);
    }

    public static BObject getEntityWithoutBodyAndHeaders(BObject requestObj) {
        return HttpUtil.getEntity(requestObj, true, false, false);
    }

    public static BObject getEntityWithBodyAndWithoutHeaders(BObject requestObj) {
        return HttpUtil.getEntity(requestObj, true, true, false);
    }

    public static boolean checkEntityBodyAvailability(BObject requestObj) {
        BObject entityObj = (BObject) requestObj.get(REQUEST_ENTITY_FIELD);
        return lengthHeaderCheck(requestObj) || EntityBodyHandler.checkEntityBodyAvailability(entityObj);
    }

    public static boolean hasMsgDataSource(BObject requestObj) {
        BObject entityObj = (BObject) requestObj.get(REQUEST_ENTITY_FIELD);
        return Objects.nonNull(EntityBodyHandler.getMessageDataSource(entityObj));
    }

    private static boolean lengthHeaderCheck(BObject requestObj) {
        Object outboundMsg = requestObj.getNativeData(TRANSPORT_MESSAGE);
        if (outboundMsg == null) {
            return false;
        }
        return checkRequestBodySizeHeadersAvailability((HttpCarbonMessage) outboundMsg);
    }

    private ExternRequest() {}
}
