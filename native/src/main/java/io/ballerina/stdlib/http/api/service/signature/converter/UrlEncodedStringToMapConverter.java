/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.service.signature.converter;

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

import static io.ballerina.runtime.api.types.TypeTags.STRING_TAG;

/**
 * The converter binds the URL encoded string payload to a Map.
 *
 * @since SwanLake update 1
 */
public class UrlEncodedStringToMapConverter {

    private static final MapType STRING_MAP = TypeCreator.createMapType(PredefinedTypes.TYPE_STRING);

    public static Object convert(MapType type, BString dataSource, boolean readonly) {
        Type constrainedType = type.getConstrainedType();
        if (constrainedType.getTag() == STRING_TAG) {
            BMap<BString, Object> formParamMap = getFormParamMap(dataSource);
            if (readonly) {
                formParamMap.freezeDirect();
            }
            return formParamMap;
        }
        String message = "incompatible type found: '" + type.toString() + "'";
        throw HttpUtil.createHttpStatusCodeError(HttpErrorType.INTERNAL_PAYLOAD_BINDING_LISTENER_ERROR, message);
    }

    private static BMap<BString, Object> getFormParamMap(Object stringDataSource) {
        try {
            String formData = ((BString) stringDataSource).getValue();
            BMap<BString, Object> formParamsMap = ValueCreator.createMapValue(STRING_MAP);
            if (formData.isEmpty()) {
                return formParamsMap;
            }
            Map<String, String> tempParamMap = new HashMap<>();

            if (!formData.contains("=")) {
                throw new BallerinaConnectorException("Datasource does not contain form data");
            }
            String[] formParamValues = formData.split("&");
            for (String formParam : formParamValues) {
                int index = formParam.indexOf('=');
                if (index == -1) {
                    String decodedFormParam = URLDecoder.decode(formParam, StandardCharsets.UTF_8);
                    if (!tempParamMap.containsKey(decodedFormParam)) {
                        tempParamMap.put(decodedFormParam, null);
                    }
                    continue;
                }
                String decodedFormParamName = URLDecoder.decode(formParam.substring(0, index).trim(),
                        StandardCharsets.UTF_8);
                String decodedFormParamValue = URLDecoder.decode(formParam.substring(index + 1).trim(),
                        StandardCharsets.UTF_8);
                tempParamMap.put(decodedFormParamName, decodedFormParamValue);
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

    private UrlEncodedStringToMapConverter() {

    }
}
