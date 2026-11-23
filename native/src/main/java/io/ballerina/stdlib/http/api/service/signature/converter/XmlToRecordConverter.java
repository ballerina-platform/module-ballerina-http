/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.service.signature.converter;

import io.ballerina.lib.data.xmldata.xml.Native;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.TypeTags;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.types.XmlNodeType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BRefValue;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.runtime.api.values.BXml;
import io.ballerina.runtime.api.values.BXmlItem;
import io.ballerina.runtime.api.values.BXmlSequence;

import java.util.ArrayList;
import java.util.List;

/**
 * Binds an XML value to a record type, an array of record types, or a union of such types by delegating the
 * record conversion to the {@code ballerina/data.xmldata} package.
 * <p>
 * A record is bound from the root element of the XML value. An array of records is bound from the child elements of
 * the root element, where each child element is bound to one member of the array. For a union type, the member types
 * are tried in the order of their declaration and the first successful binding is returned.
 *
 * @since 2.19.0
 */
public final class XmlToRecordConverter {

    private static final BString ATTRIBUTE_PREFIX = StringUtils.fromString("attributePrefix");
    private static final BString TEXT_FIELD_NAME = StringUtils.fromString("textFieldName");
    private static final BString ALLOW_DATA_PROJECTION = StringUtils.fromString("allowDataProjection");
    private static final BString USE_SEMANTIC_EQUALITY = StringUtils.fromString("useSemanticEquality");
    private static final BString ENABLE_CONSTRAINT_VALIDATION = StringUtils.fromString("enableConstraintValidation");

    private XmlToRecordConverter() {
    }

    /**
     * Checks whether an XML payload can be bound to the given type using the record data binding. The type should be
     * a record, an array of records, or a union of such types, optionally including nil.
     *
     * @param type the target type
     * @return true if the XML payload can be bound to the type
     */
    public static boolean isBindableType(Type type) {
        Type impliedType = TypeUtils.getImpliedType(type);
        return switch (impliedType.getTag()) {
            case TypeTags.RECORD_TYPE_TAG -> true;
            case TypeTags.ARRAY_TAG -> TypeUtils.getImpliedType(((ArrayType) impliedType).getElementType())
                    .getTag() == TypeTags.RECORD_TYPE_TAG;
            case TypeTags.UNION_TAG -> isBindableUnion((UnionType) impliedType);
            default -> false;
        };
    }

    private static boolean isBindableUnion(UnionType unionType) {
        boolean hasBindableMember = false;
        for (Type memberType : unionType.getMemberTypes()) {
            if (TypeUtils.getImpliedType(memberType).getTag() == TypeTags.NULL_TAG) {
                continue;
            }
            if (!isBindableType(memberType)) {
                return false;
            }
            hasBindableMember = true;
        }
        return hasBindableMember;
    }

    /**
     * Binds the XML value to the given type.
     *
     * @param type           the target type, which should satisfy {@link #isBindableType(Type)}
     * @param xml            the XML value
     * @param laxDataBinding whether the data projection is allowed
     * @param readonly       whether the result should be made read-only
     * @return the bound value
     * @throws BError if the binding fails
     */
    public static Object convert(Type type, BXml xml, boolean laxDataBinding, boolean readonly) {
        Object result = convert(type, xml, createOptions(laxDataBinding));
        if (readonly && result instanceof BRefValue) {
            ((BRefValue) result).freezeDirect();
        }
        return result;
    }

    /**
     * Extern function of the client data binding.
     *
     * @param xml            the XML value
     * @param targetType     the target type
     * @param laxDataBinding whether the data projection is allowed
     * @return the bound value or an error
     */
    public static Object convertXmlToRecord(BXml xml, BTypedesc targetType, boolean laxDataBinding) {
        try {
            return convert(targetType.getDescribingType(), xml, laxDataBinding, false);
        } catch (BError error) {
            return error;
        }
    }

    /**
     * Extern function to check whether the target type supports the XML record data binding.
     *
     * @param targetType the target type
     * @return true if the XML payload can be bound to the type
     */
    public static boolean isXmlBindableType(BTypedesc targetType) {
        return isBindableType(targetType.getDescribingType());
    }

    private static Object convert(Type type, BXml xml, BMap<BString, Object> options) {
        Type mutableType = getMutableType(type);
        if (mutableType != type) {
            // A read-only type cannot be populated, hence the value is bound to the mutable type and frozen
            Object result = convert(mutableType, xml, options);
            if (result instanceof BRefValue refValue) {
                refValue.freezeDirect();
            }
            return result;
        }
        Type impliedType = TypeUtils.getImpliedType(type);
        return switch (impliedType.getTag()) {
            case TypeTags.RECORD_TYPE_TAG -> convertToRecord(impliedType, xml, options);
            case TypeTags.ARRAY_TAG -> convertToArray((ArrayType) impliedType, xml, options);
            case TypeTags.UNION_TAG -> convertToUnion((UnionType) impliedType, xml, options);
            default -> throw createError("incompatible type found: '" + type + "'");
        };
    }

    private static Object convertToRecord(Type recordType, BXml xml, BMap<BString, Object> options) {
        Object result = Native.parseAsType(xml, options, ValueCreator.createTypedescValue(recordType));
        if (result instanceof BError error) {
            throw error;
        }
        return result;
    }

    private static Object convertToArray(ArrayType arrayType, BXml xml, BMap<BString, Object> options) {
        Type elementType = TypeUtils.getImpliedType(arrayType.getElementType());
        List<BXml> children = getChildElements(getRootElement(xml));
        if (arrayType.getSize() >= 0 && arrayType.getSize() != children.size()) {
            throw createError("array size mismatch: expected " + arrayType.getSize() + " elements, found " +
                    children.size());
        }
        // A read-only array cannot be populated, hence the members are added to a mutable array which is frozen
        // afterwards.
        ArrayType mutableArrayType = arrayType.isReadOnly() ?
                TypeCreator.createArrayType(arrayType.getElementType(), arrayType.getSize()) : arrayType;
        BArray array = ValueCreator.createArrayValue(mutableArrayType);
        long index = 0;
        for (BXml child : children) {
            array.add(index++, convertToRecord(elementType, child, options));
        }
        if (arrayType.isReadOnly()) {
            array.freezeDirect();
        }
        return array;
    }

    private static Object convertToUnion(UnionType unionType, BXml xml, BMap<BString, Object> options) {
        List<Type> candidates = new ArrayList<>();
        for (Type memberType : unionType.getMemberTypes()) {
            if (TypeUtils.getImpliedType(memberType).getTag() != TypeTags.NULL_TAG) {
                candidates.add(memberType);
            }
        }
        if (candidates.size() == 1) {
            return convert(candidates.get(0), xml, options);
        }
        for (Type candidate : candidates) {
            try {
                return convert(candidate, xml, options);
            } catch (BError ignored) {
                // Try the next member type
            }
        }
        throw createError("cannot bind the xml payload to any member of the union type '" + unionType + "'");
    }

    private static Type getMutableType(Type type) {
        if (type instanceof IntersectionType intersectionType) {
            for (Type constituentType : intersectionType.getConstituentTypes()) {
                if (constituentType.getTag() != TypeTags.READONLY_TAG) {
                    return constituentType;
                }
            }
        }
        return type;
    }

    private static BXml getRootElement(BXml xml) {
        if (xml.getNodeType() == XmlNodeType.ELEMENT) {
            return xml;
        }
        if (xml.getNodeType() == XmlNodeType.SEQUENCE) {
            List<BXml> elements = new ArrayList<>();
            for (BXml item : ((BXmlSequence) xml).getChildrenList()) {
                if (item.getNodeType() == XmlNodeType.ELEMENT) {
                    elements.add(item);
                } else if (item.getNodeType() == XmlNodeType.TEXT && !isBlank(item)) {
                    break;
                }
            }
            if (elements.size() == 1) {
                return elements.get(0);
            }
        }
        throw createError("xml root element is missing");
    }

    private static List<BXml> getChildElements(BXml root) {
        List<BXml> children = new ArrayList<>();
        BXml childSeq = ((BXmlItem) root).getChildrenSeq();
        List<BXml> items = childSeq.getNodeType() == XmlNodeType.SEQUENCE ?
                ((BXmlSequence) childSeq).getChildrenList() : List.of(childSeq);
        for (BXml item : items) {
            switch (item.getNodeType()) {
                case ELEMENT -> children.add(item);
                case TEXT -> {
                    if (!isBlank(item)) {
                        throw createError("unexpected text content found inside the root element of the xml array");
                    }
                }
                default -> {
                    // Comments and processing instructions are ignored
                }
            }
        }
        return children;
    }

    private static boolean isBlank(BXml textItem) {
        return textItem.getTextValue().isBlank();
    }

    private static BError createError(String message) {
        return ErrorCreator.createError(StringUtils.fromString(message));
    }

    private static BMap<BString, Object> createOptions(boolean laxDataBinding) {
        BMap<BString, Object> options = ValueCreator.createMapValue(
                TypeCreator.createMapType(PredefinedTypes.TYPE_ANYDATA));
        options.put(ATTRIBUTE_PREFIX, StringUtils.fromString(""));
        options.put(TEXT_FIELD_NAME, StringUtils.fromString("#content"));
        options.put(ALLOW_DATA_PROJECTION, laxDataBinding);
        options.put(USE_SEMANTIC_EQUALITY, true);
        options.put(ENABLE_CONSTRAINT_VALIDATION, false);
        return options;
    }
}
