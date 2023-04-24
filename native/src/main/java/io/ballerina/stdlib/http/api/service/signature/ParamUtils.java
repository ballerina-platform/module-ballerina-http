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
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.FiniteType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;

import static io.ballerina.runtime.api.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.TypeTags.DECIMAL_TAG;
import static io.ballerina.runtime.api.TypeTags.FINITE_TYPE_TAG;
import static io.ballerina.runtime.api.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.TypeTags.MAP_TAG;
import static io.ballerina.runtime.api.TypeTags.RECORD_TYPE_TAG;
import static io.ballerina.runtime.api.TypeTags.UNION_TAG;

/**
 * {@code HttpDispatcher} is responsible for dispatching incoming http requests to the correct resource.
 *
 * @since 0.94
 */
public class ParamUtils {

    private static final MapType MAP_TYPE = TypeCreator.createMapType(PredefinedTypes.TYPE_JSON);

    public static Object parseParam(int targetParamTypeTag, String argValue) {
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
                return ValueUtils.convert(json, MAP_TYPE);
            default:
                return StringUtils.fromString(argValue);
        }
    }

    public static BArray parseParamArray(Type elementType, String[] argValueArr) {
        int targetElementTypeTag = elementType.getTag();
        switch (targetElementTypeTag) {
            case INT_TAG:
            case FLOAT_TAG:
            case BOOLEAN_TAG:
            case DECIMAL_TAG:
            case MAP_TAG:
            case RECORD_TYPE_TAG:
                return getBArray(argValueArr, TypeCreator.createArrayType(elementType), elementType);
            default:
                return StringUtils.fromStringArray(argValueArr);
        }
    }

    private static BArray getBArray(String[] valueArray, ArrayType arrayType, Type elementType) {
        BArray arrayValue = ValueCreator.createArrayValue(arrayType);
        int index = 0;
        int elementTypeTag = elementType.getTag();
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
                case RECORD_TYPE_TAG:
                    Object record = JsonUtils.parse(element);
                    arrayValue.add(index++, ValueUtils.convert(record, elementType));
                    break;
                default:
                    throw new BallerinaConnectorException("Illegal state error: unexpected param type");
            }
        }
        return arrayValue;
    }

    public static boolean isEnumParamType(Type paramType) {
        return TypeUtils.getReferredType(paramType).getTag() == UNION_TAG &&
                ((UnionType) paramType).getMemberTypes()
                        .stream().allMatch(type -> type.getTag() == TypeTags.FINITE_TYPE_TAG);
    }

    public static Object castEnumParam(UnionType paramType, BString queryValue, String token, String paramKind) {
        if (paramType.getMemberTypes().stream().anyMatch(memberType ->
                ((FiniteType) memberType).getValueSpace().contains(queryValue))) {
            return queryValue;
        }
        throw new FiniteTypeConversionError(paramKind + " param value '" + token + "' does not match the enum type");
    }

    public static boolean isFiniteParamType(Type paramType) {
        return TypeUtils.getReferredType(paramType).getTag() == FINITE_TYPE_TAG;
    }

    public static Object castFiniteParam(FiniteType paramType, String paramValue, String token, String paramKind) {
        return paramType.getValueSpace().stream().filter(
                value -> value.equals(parseParam(TypeUtils.getType(value).getTag(), paramValue))).findFirst()
                .orElseThrow(() -> new FiniteTypeConversionError(
                        paramKind + " param value '" + token + "' does not the match finite type"));
    }

    private ParamUtils() {
    }

    /**
     * This class represents the error occurred during the conversion to a finite type param.
     */
    public static class FiniteTypeConversionError extends RuntimeException {

        public FiniteTypeConversionError(String message) {
            super(message);
        }

        @Override
        public String toString() {
            return getMessage();
        }
    }
}
