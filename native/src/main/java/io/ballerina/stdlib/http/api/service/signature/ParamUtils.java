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

import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.FiniteType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.stdlib.http.api.BallerinaConnectorException;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import static io.ballerina.runtime.api.types.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.types.TypeTags.BOOLEAN_TAG;
import static io.ballerina.runtime.api.types.TypeTags.DECIMAL_TAG;
import static io.ballerina.runtime.api.types.TypeTags.FINITE_TYPE_TAG;
import static io.ballerina.runtime.api.types.TypeTags.FLOAT_TAG;
import static io.ballerina.runtime.api.types.TypeTags.INTERSECTION_TAG;
import static io.ballerina.runtime.api.types.TypeTags.INT_TAG;
import static io.ballerina.runtime.api.types.TypeTags.MAP_TAG;
import static io.ballerina.runtime.api.types.TypeTags.NULL_TAG;
import static io.ballerina.runtime.api.types.TypeTags.READONLY_TAG;
import static io.ballerina.runtime.api.types.TypeTags.RECORD_TYPE_TAG;
import static io.ballerina.runtime.api.types.TypeTags.STRING_TAG;
import static io.ballerina.runtime.api.types.TypeTags.UNION_TAG;
import static io.ballerina.stdlib.http.api.HttpConstants.PATH_PARAM;
import static io.ballerina.stdlib.http.api.HttpConstants.QUERY_PARAM;

/**
 * {@code HttpDispatcher} is responsible for dispatching incoming http requests to the correct resource.
 *
 * @since 0.94
 */
public class ParamUtils {

    public static Object castParam(int targetParamTypeTag, String argValue) {
        try {
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
                case RECORD_TYPE_TAG:
                    return JsonUtils.parse(argValue);
                default:
                    return StringUtils.fromString(argValue);
            }
        } catch (Exception exp) {
            String errorMessage = "error occurred while converting '" + argValue + "' to the target type";
            if (exp instanceof BError) {
                throw ErrorCreator.createError(StringUtils.fromString(errorMessage), exp);
            }
            throw ErrorCreator.createError(StringUtils.fromString(errorMessage));
        }
    }

    public static BArray castParamArray(Type elementType, String[] argValueArr) {
        int targetElementTypeTag = elementType.getTag();
        switch (targetElementTypeTag) {
            case INT_TAG:
            case FLOAT_TAG:
            case BOOLEAN_TAG:
            case DECIMAL_TAG:
            case MAP_TAG:
            case RECORD_TYPE_TAG:
                try {
                    return getBArray(argValueArr, TypeCreator.createArrayType(elementType), elementType);
                } catch (Exception exp) {
                    String errorMessage = "error occurred while converting '" + argValueArr +
                            "' to the target array type";
                    if (exp instanceof BError) {
                        throw ErrorCreator.createError(StringUtils.fromString(errorMessage), exp);
                    }
                    throw ErrorCreator.createError(StringUtils.fromString(errorMessage));
                }
            default:
                return StringUtils.fromStringArray(argValueArr);
        }
    }

    public static BArray castParamArray(int elementTypeTag, String[] argValueArr) {
        List<Object> parsedValues = new ArrayList<>();
        for (String argValue : argValueArr) {
            parsedValues.add(castParam(elementTypeTag, argValue));
        }
        return ValueCreator.createArrayValue(parsedValues.toArray(),
                TypeCreator.createArrayType(PredefinedTypes.TYPE_JSON));
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

    public static boolean isArrayType(Type type) {
        Type referredType = TypeUtils.getReferredType(type);
        int referredTypeTag = referredType.getTag();
        if (referredTypeTag == ARRAY_TAG) {
            return true;
        } else if (referredTypeTag == UNION_TAG) {
            List<Type> memberTypes = ((UnionType) referredType).getMemberTypes();
            return memberTypes.stream().allMatch(
                    memberType -> isArrayType(memberType) || memberType.getTag() == NULL_TAG);
        } else if (referredTypeTag == INTERSECTION_TAG) {
            // Only consider the intersection type with readonly and array type.
            List<Type> constituentTypes = ((IntersectionType) referredType).getConstituentTypes();
            if (constituentTypes.size() == 2) {
                if (constituentTypes.get(0).getTag() == READONLY_TAG) {
                    return isArrayType(constituentTypes.get(1));
                } else if (constituentTypes.get(1).getTag() == READONLY_TAG) {
                    return isArrayType(constituentTypes.get(0));
                }
            }
        }
        return false;
    }

    public static RecordType getRecordType(Type type) {
        Type referredType = TypeUtils.getReferredType(type);
        int referredTypeTag = referredType.getTag();
        if (referredTypeTag == RECORD_TYPE_TAG) {
            return (RecordType) referredType;
        } else if (referredTypeTag == UNION_TAG) {
            // Only consider the union type with nil and record type.
            List<Type> memberTypes = ((UnionType) referredType).getMemberTypes();
            if (memberTypes.size() == 2) {
                if (memberTypes.get(0).getTag() == NULL_TAG) {
                    return getRecordType(memberTypes.get(1));
                } else if (memberTypes.get(1).getTag() == NULL_TAG) {
                    return getRecordType(memberTypes.get(0));
                }
            }
        } else if (referredTypeTag == INTERSECTION_TAG) {
            // Only consider the intersection type with readonly and record type.
            List<Type> constituentTypes = ((IntersectionType) referredType).getConstituentTypes();
            if (constituentTypes.size() == 2) {
                if (constituentTypes.get(0).getTag() == READONLY_TAG) {
                    return getRecordType(constituentTypes.get(1));
                } else if (constituentTypes.get(1).getTag() == READONLY_TAG) {
                    return getRecordType(constituentTypes.get(0));
                }
            }
        }
        return null;
    }

    public static boolean isFiniteType(Type type) {
        Type referredType = TypeUtils.getReferredType(type);
        int referredTypeTag = referredType.getTag();
        if (referredTypeTag == FINITE_TYPE_TAG) {
            return true;
        } else if (referredTypeTag == UNION_TAG) {
            List<Type> memberTypes = ((UnionType) referredType).getMemberTypes();
            return memberTypes.stream().allMatch(
                    memberType -> isFiniteType(memberType) || memberType.getTag() == NULL_TAG);
        } else if (referredTypeTag == INTERSECTION_TAG) {
            // Only consider the intersection type with readonly and finite type.
            List<Type> constituentTypes = ((IntersectionType) referredType).getConstituentTypes();
            if (constituentTypes.size() == 2) {
                if (constituentTypes.get(0).getTag() == READONLY_TAG) {
                    return isFiniteType(constituentTypes.get(1));
                } else if (constituentTypes.get(1).getTag() == READONLY_TAG) {
                    return isFiniteType(constituentTypes.get(0));
                }
            }
        } else if (referredTypeTag == ARRAY_TAG) {
            return isFiniteType(((ArrayType) referredType).getElementType());
        }
        return false;
    }

    public static int getEffectiveTypeTag(Type type, Type originalType, String paramType) {
        Type referredType = TypeUtils.getReferredType(type);
        int referredTypeTag = referredType.getTag();
        if (TypeTags.isIntegerTypeTag(referredTypeTag)) {
            return INT_TAG;
        } else if (TypeTags.isStringTypeTag(referredTypeTag)) {
            return STRING_TAG;
        }
        switch (referredTypeTag) {
            case FLOAT_TAG:
            case BOOLEAN_TAG:
            case DECIMAL_TAG:
                return referredTypeTag;
            case MAP_TAG:
            case RECORD_TYPE_TAG:
                if (paramType.equals(QUERY_PARAM)) {
                    return MAP_TAG;
                }
                break;
            case ARRAY_TAG:
                return getEffectiveTypeTagFromArrayType((ArrayType) referredType, originalType, paramType);
            case UNION_TAG:
                return getEffectiveTypeTagFromUnionType((UnionType) referredType, originalType, paramType);
            case FINITE_TYPE_TAG:
                return getEffectiveTypeTagFromFiniteType((FiniteType) referredType, originalType, paramType);
            case INTERSECTION_TAG:
                return getEffectiveTypeTagFromIntersectionType((IntersectionType) referredType, originalType,
                        paramType);
        }
        throw HttpUtil.createHttpError("invalid " + paramType + " parameter type '" + originalType + "'");
    }

    private static int getEffectiveTypeTagFromArrayType(ArrayType type, Type originalType, String paramType) {
        Type elementType = TypeUtils.getReferredType(type.getElementType());
        if (elementType.getTag() == ARRAY_TAG) {
            throw HttpUtil.createHttpError("invalid " + paramType + " parameter array type '" + originalType + "'");
        } else {
            return getEffectiveTypeTag(elementType, originalType, paramType);
        }
    }

    private static int getEffectiveTypeTagFromUnionType(UnionType type, Type originalType, String paramType) {
        List<Type> memberTypes = type.getMemberTypes();
        List<Integer> memberTypeTags = new ArrayList<>();
        for (Type memberType : memberTypes) {
            Type referredType = TypeUtils.getReferredType(memberType);
            if (referredType.getTag() == NULL_TAG && !paramType.equals(PATH_PARAM)) {
                continue;
            }
            memberTypeTags.add(getEffectiveTypeTag(referredType, originalType, paramType));
        }
        if (memberTypeTags.stream().allMatch(
                memberTypeTag -> memberTypeTag.equals(memberTypeTags.get(0)))) {
            return memberTypeTags.get(0);
        } else {
            throw HttpUtil.createHttpError("invalid " + paramType + " parameter union type '" + originalType + "'");
        }
    }

    private static int getEffectiveTypeTagFromFiniteType(FiniteType type, Type originalType, String paramType) {
        Set<Object> valueSpace = type.getValueSpace();
        List<Integer> valueSpaceMemberTypeTags = new ArrayList<>();
        for (Object value : valueSpace) {
            Type referredType = TypeUtils.getReferredType(TypeUtils.getType(value));
            if (referredType.getTag() == NULL_TAG && !paramType.equals(PATH_PARAM)) {
                continue;
            }
            valueSpaceMemberTypeTags.add(getEffectiveTypeTag(TypeUtils.getType(value), originalType, paramType));
        }
        if (valueSpaceMemberTypeTags.stream().allMatch(
                memberTypeTag -> memberTypeTag.equals(valueSpaceMemberTypeTags.get(0)))) {
            return valueSpaceMemberTypeTags.get(0);
        } else {
            throw HttpUtil.createHttpError("invalid " + paramType + " parameter finite type '" + originalType + "'");
        }
    }

    private static int getEffectiveTypeTagFromIntersectionType(IntersectionType type, Type originalType,
                                                               String paramType) {
        List<Type> constituentTypes = type.getConstituentTypes();
        // Only consider the intersection type with readonly.
        if (constituentTypes.size() == 2) {
            if (constituentTypes.get(0).getTag() == READONLY_TAG) {
                return getEffectiveTypeTag(constituentTypes.get(1), originalType, paramType);
            } else if (constituentTypes.get(1).getTag() == READONLY_TAG) {
                return getEffectiveTypeTag(constituentTypes.get(0), originalType, paramType);
            }
        }
        throw HttpUtil.createHttpError("invalid " + paramType + " parameter intersection type '"
                + originalType + "'");
    }

    private ParamUtils() {
    }
}
