/*
*  Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.service.signature;

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;

import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.DECIMAL_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.MAP_TAG;

/**
 * {@code HttpDispatcher} is responsible for dispatching incoming http requests to the correct resource.
 *
 * @since 0.94
 */
public class ParamUtils {

    private static final MapType MAP_TYPE = TypeCreator.createMapType(PredefinedTypes.TYPE_JSON);
    private static final ArrayType INT_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_INT);
    private static final ArrayType FLOAT_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_FLOAT);
    private static final ArrayType BOOLEAN_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_BOOLEAN);
    private static final ArrayType DECIMAL_ARR = TypeCreator.createArrayType(PredefinedTypes.TYPE_DECIMAL);
    private static final ArrayType MAP_ARR = TypeCreator.createArrayType(MAP_TYPE);

    public static Object castParam(int targetParamTypeTag, String argValue) {
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

    public static BArray castParamArray(int targetElementTypeTag, String[] argValueArr) {
        switch (targetElementTypeTag) {
            case INT_TAG:
                return getBArray(argValueArr, INT_ARR, targetElementTypeTag);
            case FLOAT_TAG:
                return getBArray(argValueArr, FLOAT_ARR, targetElementTypeTag);
            case BOOLEAN_TAG:
                return getBArray(argValueArr, BOOLEAN_ARR, targetElementTypeTag);
            case DECIMAL_TAG:
                return getBArray(argValueArr, DECIMAL_ARR, targetElementTypeTag);
            case MAP_TAG:
                return getBArray(argValueArr, MAP_ARR, targetElementTypeTag);
            default:
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

    private ParamUtils() {
    }
}
