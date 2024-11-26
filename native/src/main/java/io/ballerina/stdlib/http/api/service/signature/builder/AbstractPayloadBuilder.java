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

package io.ballerina.stdlib.http.api.service.signature.builder;

import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.types.TypedescType;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.stdlib.mime.util.HeaderUtil;

import java.util.List;
import java.util.Locale;

import static io.ballerina.runtime.api.types.TypeTags.ARRAY_TAG;
import static io.ballerina.runtime.api.types.TypeTags.BYTE_ARRAY_TAG;
import static io.ballerina.runtime.api.types.TypeTags.BYTE_TAG;
import static io.ballerina.runtime.api.types.TypeTags.MAP_TAG;
import static io.ballerina.runtime.api.types.TypeTags.NULL_TAG;
import static io.ballerina.runtime.api.types.TypeTags.STRING_TAG;
import static io.ballerina.runtime.api.types.TypeTags.XML_TAG;

/**
 * The abstract class to build and convert the payload based on the content-type header. If the content type is not
 * standard, the parameter type is used to infer the builder.
 *
 * @since SwanLake update 1
 */
public abstract class AbstractPayloadBuilder {

    private static final String JSON_PATTERN = "^(application|text)\\/(.*[.+-]|)json$";
    private static final String XML_PATTERN = "^(application|text)\\/(.*[.+-]|)xml$";
    private static final String TEXT_PATTERN = "^(text)\\/(.*[.+-]|)plain$";
    private static final String OCTET_STREAM_PATTERN = "^(application)\\/(.*[.+-]|)octet-stream$";
    private static final String URL_ENCODED_PATTERN = "^(application)\\/(.*[.+-]|)x-www-form-urlencoded$";

    /**
     * Get the built inbound payload after binding it to the respective type.
     *
     * @param inRequestEntity inbound request entity
     * @param readonly        readonly status of parameter
     * @return the payload
     */
    public abstract Object getValue(BObject inRequestEntity, boolean readonly);

    public static AbstractPayloadBuilder getBuilder(String contentType, Type payloadType, boolean laxDataBinding) {
        if (contentType == null || contentType.isEmpty()) {
            return getBuilderFromType(payloadType, laxDataBinding);
        }
        contentType = contentType.toLowerCase(Locale.getDefault()).trim();
        String baseType = HeaderUtil.getHeaderValue(contentType);
        if (baseType.matches(XML_PATTERN)) {
            return new XmlPayloadBuilder(payloadType);
        } else if (baseType.matches(TEXT_PATTERN)) {
            return new StringPayloadBuilder(payloadType);
        } else if (baseType.matches(URL_ENCODED_PATTERN)) {
            return new StringPayloadBuilder(payloadType);
        } else if (baseType.matches(OCTET_STREAM_PATTERN)) {
            return new BinaryPayloadBuilder(payloadType);
        } else if (baseType.matches(JSON_PATTERN)) {
            return new JsonPayloadBuilder(payloadType, laxDataBinding);
        } else {
            return getBuilderFromType(payloadType, laxDataBinding);
        }
    }

    private static AbstractPayloadBuilder getBuilderFromType(Type payloadType, boolean laxDataBinding) {
        switch (payloadType.getTag()) {
            case STRING_TAG:
                return new StringPayloadBuilder(payloadType);
            case XML_TAG:
                return new XmlPayloadBuilder(payloadType);
            case ARRAY_TAG:
                return new ArrayBuilder(payloadType, laxDataBinding);
            default:
                return new JsonPayloadBuilder(payloadType, laxDataBinding);
        }
    }

    public static boolean isSubtypeOfAllowedType(Type payloadType, int targetTypeTag) {
        if (payloadType.getTag() == targetTypeTag) {
            return true;
        } else if (payloadType.getTag() == TypeTags.UNION_TAG) {
            assert payloadType instanceof UnionType : payloadType.getClass();
            List<Type> memberTypes = ((UnionType) payloadType).getMemberTypes();
            return memberTypes.stream().anyMatch(memberType -> isSubtypeOfAllowedType(memberType, targetTypeTag));
        }
        return false;
    }

    // Target type can be `xml`, `string`, `map<string>`, `()`, `byte[]`
    public static boolean matchingType(BTypedesc sourceTypeDesc, BTypedesc targetTypeDesc) {
        Type sourceType = TypeUtils.getImpliedType(sourceTypeDesc.getDescribingType());
        Type targetType = getConstraintedType(TypeUtils.getImpliedType(targetTypeDesc.getDescribingType()));
        return matchingTypeInternal(sourceType, targetType);
    }

    private static Type getConstraintedType(Type targetType) {
        if (targetType.getTag() == TypeTags.TYPEDESC_TAG) {
            return ((TypedescType) targetType).getConstraint();
        }
        return targetType;
    }

    private static boolean matchingTypeInternal(Type sourceType, Type targetType) {
        int targetTypeTag = targetType.getTag();
        int sourceTypeTag = sourceType.getTag();

        if (sourceTypeTag == TypeTags.ANYDATA_TAG || isMapOfStringType(sourceType, targetTypeTag) ||
                isXmlType(sourceTypeTag, targetTypeTag) || isStringType(sourceTypeTag, targetTypeTag) ||
                isNilType(sourceTypeTag, targetTypeTag) || isByteArrayType(sourceType, targetTypeTag)) {
            return true;
        }

        if (sourceTypeTag == TypeTags.UNION_TAG) {
            List<Type> memberTypes = ((UnionType) sourceType).getMemberTypes();
            return memberTypes.stream().anyMatch(memberType -> matchingTypeInternal(memberType, targetType));
        }

        if (sourceTypeTag == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            return matchingTypeInternal(TypeUtils.getReferredType(sourceType), targetType);
        }

        return false;
    }

    private static boolean isNilType(int sourceTypeTag, int targetTypeTag) {
        return sourceTypeTag == NULL_TAG && targetTypeTag == NULL_TAG;
    }

    private static boolean isStringType(int sourceTypeTag, int targetTypeTag) {
        return TypeTags.isStringTypeTag(sourceTypeTag) && targetTypeTag == STRING_TAG;
    }

    private static boolean isXmlType(int sourceTypeTag, int targetTypeTag) {
        return TypeTags.isXMLTypeTag(sourceTypeTag) && targetTypeTag == XML_TAG;
    }

    private static boolean isMapOfStringType(Type sourceType, int targetTypeTag) {
        return targetTypeTag == TypeTags.MAP_TAG && sourceType.getTag() == MAP_TAG &&
                TypeTags.isStringTypeTag(((MapType) sourceType).getConstrainedType().getTag());
    }

    private static boolean isByteArrayType(Type sourceType, int targetTypeTag) {
        return (targetTypeTag == BYTE_ARRAY_TAG || targetTypeTag == ARRAY_TAG) &&
                (sourceType.getTag() == BYTE_ARRAY_TAG || (sourceType.getTag() == ARRAY_TAG &&
                        ((ArrayType) sourceType).getElementType().getTag() == BYTE_TAG));
    }

    public static boolean hasHttpResponseType(BTypedesc targetTypeDesc) {
        Type targetType = TypeUtils.getImpliedType(targetTypeDesc.getDescribingType());
        return hasHttpResponseTypeInternal(targetType);
    }

    private static boolean hasHttpResponseTypeInternal(Type targetType) {
        targetType = TypeUtils.getImpliedType(targetType);
        return switch (targetType.getTag()) {
            case TypeTags.OBJECT_TYPE_TAG -> true;
            case TypeTags.UNION_TAG -> ((UnionType) targetType).getMemberTypes().stream().anyMatch(
                    AbstractPayloadBuilder::hasHttpResponseTypeInternal);
            case TypeTags.TYPE_REFERENCED_TYPE_TAG ->
                    hasHttpResponseTypeInternal(TypeUtils.getReferredType(targetType));
            default -> false;
        };
    }
}
