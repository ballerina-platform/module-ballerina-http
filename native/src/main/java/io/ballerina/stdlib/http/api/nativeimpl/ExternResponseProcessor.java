/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.async.Callback;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Field;
import io.ballerina.runtime.api.types.MapType;
import io.ballerina.runtime.api.types.ObjectType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.ReferenceType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.runtime.api.utils.JsonUtils;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.utils.ValueUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.stdlib.constraint.Constraints;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.ValueCreatorUtils;
import io.netty.handler.codec.http.HttpHeaders;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.CountDownLatch;

import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_HEADERS;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_BODY_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_HEADERS_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_STATUS_CODE_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_STATUS_FIELD;
import static io.ballerina.stdlib.http.api.HttpErrorType.CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_BINDING_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_NOT_FOUND_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_VALIDATION_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.MEDIA_TYPE_BINDING_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.MEDIA_TYPE_VALIDATION_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.PAYLOAD_BINDING_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.STATUS_CODE_RECORD_BINDING_ERROR;
import static io.ballerina.stdlib.http.api.HttpUtil.createHttpError;

public final class ExternResponseProcessor {

    private static final String NO_HEADER_VALUE_ERROR_MSG = "no header value found for '%s'";
    private static final String HEADER_BINDING_FAILED_ERROR_MSG = "header binding failed for parameter: '%s'";
    private static final String HEADER_BINDING_FAILED = "header binding failed";
    private static final String UNSUPPORTED_HEADERS_TYPE = "unsupported headers type: %s";
    private static final String UNSUPPORTED_STATUS_CODE = "unsupported status code: %d";
    private static final String INCOMPATIBLE_TYPE_FOUND_FOR_RESPONSE = "incompatible %s found for response with %d";
    private static final String NO_ANYDATA_TYPE_FOUND_IN_THE_TARGET_TYPE = "no 'anydata' type found in the target type";
    private static final String PAYLOAD_BINDING_FAILED = "payload binding failed";
    private static final String MEDIA_TYPE_BINDING_FAILED = "media-type binding failed";
    private static final String APPLICATION_RES_ERROR_CREATION_FAILED = "http:ApplicationResponseError creation failed";

    private static final String PERFORM_DATA_BINDING = "performDataBinding";
    private static final String GET_APPLICATION_RESPONSE_ERROR = "getApplicationResponseError";


    private static final Map<String, String> STATUS_CODE_OBJS = new HashMap<>();

    static {
        STATUS_CODE_OBJS.put("100", "StatusContinue");
        STATUS_CODE_OBJS.put("101", "StatusSwitchingProtocols");
        STATUS_CODE_OBJS.put("102", "StatusProcessing");
        STATUS_CODE_OBJS.put("103", "StatusEarlyHints");
        STATUS_CODE_OBJS.put("200", "StatusOK");
        STATUS_CODE_OBJS.put("201", "StatusCreated");
        STATUS_CODE_OBJS.put("202", "StatusAccepted");
        STATUS_CODE_OBJS.put("203", "StatusNonAuthoritativeInformation");
        STATUS_CODE_OBJS.put("204", "StatusNoContent");
        STATUS_CODE_OBJS.put("205", "StatusResetContent");
        STATUS_CODE_OBJS.put("206", "StatusPartialContent");
        STATUS_CODE_OBJS.put("207", "StatusMultiStatus");
        STATUS_CODE_OBJS.put("208", "StatusAlreadyReported");
        STATUS_CODE_OBJS.put("226", "StatusIMUsed");
        STATUS_CODE_OBJS.put("300", "StatusMultipleChoices");
        STATUS_CODE_OBJS.put("301", "StatusMovedPermanently");
        STATUS_CODE_OBJS.put("302", "StatusFound");
        STATUS_CODE_OBJS.put("303", "StatusSeeOther");
        STATUS_CODE_OBJS.put("304", "StatusNotModified");
        STATUS_CODE_OBJS.put("305", "StatusUseProxy");
        STATUS_CODE_OBJS.put("307", "StatusTemporaryRedirect");
        STATUS_CODE_OBJS.put("308", "StatusPermanentRedirect");
        STATUS_CODE_OBJS.put("400", "StatusBadRequest");
        STATUS_CODE_OBJS.put("401", "StatusUnauthorized");
        STATUS_CODE_OBJS.put("402", "StatusPaymentRequired");
        STATUS_CODE_OBJS.put("403", "StatusForbidden");
        STATUS_CODE_OBJS.put("404", "StatusNotFound");
        STATUS_CODE_OBJS.put("405", "StatusMethodNotAllowed");
        STATUS_CODE_OBJS.put("406", "StatusNotAcceptable");
        STATUS_CODE_OBJS.put("407", "StatusProxyAuthenticationRequired");
        STATUS_CODE_OBJS.put("408", "StatusRequestTimeout");
        STATUS_CODE_OBJS.put("409", "StatusConflict");
        STATUS_CODE_OBJS.put("410", "StatusGone");
        STATUS_CODE_OBJS.put("411", "StatusLengthRequired");
        STATUS_CODE_OBJS.put("412", "StatusPreconditionFailed");
        STATUS_CODE_OBJS.put("413", "StatusPayloadTooLarge");
        STATUS_CODE_OBJS.put("414", "StatusUriTooLong");
        STATUS_CODE_OBJS.put("415", "StatusUnsupportedMediaType");
        STATUS_CODE_OBJS.put("416", "StatusRangeNotSatisfiable");
        STATUS_CODE_OBJS.put("417", "StatusExpectationFailed");
        STATUS_CODE_OBJS.put("421", "StatusMisdirectedRequest");
        STATUS_CODE_OBJS.put("422", "StatusUnprocessableEntity");
        STATUS_CODE_OBJS.put("423", "StatusLocked");
        STATUS_CODE_OBJS.put("424", "StatusFailedDependency");
        STATUS_CODE_OBJS.put("425", "StatusTooEarly");
        STATUS_CODE_OBJS.put("426", "StatusUpgradeRequired");
        STATUS_CODE_OBJS.put("428", "StatusPreconditionRequired");
        STATUS_CODE_OBJS.put("429", "StatusTooManyRequests");
        STATUS_CODE_OBJS.put("431", "StatusRequestHeaderFieldsTooLarge");
        STATUS_CODE_OBJS.put("451", "StatusUnavailableDueToLegalReasons");
        STATUS_CODE_OBJS.put("500", "StatusInternalServerError");
        STATUS_CODE_OBJS.put("501", "StatusNotImplemented");
        STATUS_CODE_OBJS.put("502", "StatusBadGateway");
        STATUS_CODE_OBJS.put("503", "StatusServiceUnavailable");
        STATUS_CODE_OBJS.put("504", "StatusGatewayTimeout");
        STATUS_CODE_OBJS.put("505", "StatusHttpVersionNotSupported");
        STATUS_CODE_OBJS.put("506", "StatusVariantAlsoNegotiates");
        STATUS_CODE_OBJS.put("507", "StatusInsufficientStorage");
        STATUS_CODE_OBJS.put("508", "StatusLoopDetected");
        STATUS_CODE_OBJS.put("510", "StatusNotExtended");
        STATUS_CODE_OBJS.put("511", "StatusNetworkAuthenticationRequired");
    }

    private ExternResponseProcessor() {
    }

    public static Object processResponse(Environment env, BObject response, BTypedesc targetType,
                                         boolean requireValidation) {
        return getResponseWithType(response, targetType.getDescribingType(), requireValidation, env.getRuntime());
    }

    private static Object getResponseWithType(BObject response, Type targetType, boolean requireValidation,
                                              Runtime runtime) {
        long responseStatusCode = getStatusCode(response);
        Optional<Type> statusCodeResponseType = getStatusCodeResponseType(targetType,
                Long.toString(responseStatusCode));
        if (statusCodeResponseType.isPresent() &&
                TypeUtils.getImpliedType(statusCodeResponseType.get()) instanceof RecordType statusCodeRecordType) {
            return generateStatusCodeResponseType(response, requireValidation, runtime, statusCodeRecordType,
                    responseStatusCode);
        } else if ((399 < responseStatusCode) && (responseStatusCode < 600)) {
            return hasHttpResponseType(targetType) ? response : getApplicationResponseError(runtime, response);
        } else {
            return generatePayload(response, targetType, requireValidation, runtime);
        }
    }

    private static Object generatePayload(BObject response, Type targetType, boolean requireValidation,
                                          Runtime runtime) {
        try {
            return getPayload(runtime, response, getAnydataType(targetType), requireValidation);
        } catch (BError e) {
            if (hasHttpResponseType(targetType)) {
                return response;
            }
            return createHttpError(String.format(INCOMPATIBLE_TYPE_FOUND_FOR_RESPONSE, targetType,
                    getStatusCode(response)), PAYLOAD_BINDING_CLIENT_ERROR, e);
        }
    }

    private static long getStatusCode(BObject response) {
        return response.getIntValue(StringUtils.fromString(STATUS_CODE));
    }

    private static Object generateStatusCodeResponseType(BObject response, boolean requireValidation, Runtime runtime,
                                                         RecordType statusCodeRecordType, long responseStatusCode) {
        BMap<BString, Object> statusCodeRecord = ValueCreator.createRecordValue(statusCodeRecordType);

        String statusCodeObjName = STATUS_CODE_OBJS.get(Long.toString(responseStatusCode));
        if (Objects.isNull(statusCodeObjName)) {
            return createHttpError(String.format(UNSUPPORTED_STATUS_CODE, responseStatusCode),
                    STATUS_CODE_RECORD_BINDING_ERROR);
        }

        populateStatusCodeObject(statusCodeObjName, statusCodeRecord);

        Object headerMap = getHeaders(response, requireValidation, statusCodeRecordType);
        if (headerMap instanceof BError) {
            return headerMap;
        }
        statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_HEADERS_FIELD), headerMap);

        if (statusCodeRecordType.getFields().containsKey(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD)) {
            Object mediaType = getMediaType(response, requireValidation, statusCodeRecordType);
            if (mediaType instanceof BError) {
                return mediaType;
            }
            statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD), mediaType);
        }

        if (statusCodeRecordType.getFields().containsKey(STATUS_CODE_RESPONSE_BODY_FIELD)) {
            Object payload = getBody(response, requireValidation, runtime, statusCodeRecordType);
            if (payload instanceof BError) {
                return payload;
            }
            statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_BODY_FIELD), payload);
        }
        return statusCodeRecord;
    }

    private static Object getBody(BObject response, boolean requireValidation, Runtime runtime,
                                  RecordType statusCodeRecordType) {
        Type bodyType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_BODY_FIELD).getFieldType();
        return getPayload(runtime, response, bodyType, requireValidation);
    }

    private static Object getHeaders(BObject response, boolean requireValidation, RecordType statusCodeRecordType) {
        Type headersType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_HEADERS_FIELD).getFieldType();
        return getHeadersMap(response, headersType, requireValidation);
    }

    private static Object getMediaType(BObject response, boolean requireValidation, RecordType statusCodeRecordType) {
        Type mediaTypeType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD).getFieldType();
        return getMediaType(response, mediaTypeType, requireValidation);
    }

    private static void populateStatusCodeObject(String statusCodeObjName, BMap<BString, Object> statusCodeRecord) {
        Object status = ValueCreatorUtils.createStatusCodeObject(statusCodeObjName);
        statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_STATUS_FIELD), status);
    }

    private static Type getAnydataType(Type targetType) {
        List<Type> anydataTypes = extractAnydataTypes(targetType, new ArrayList<>());
        if (anydataTypes.isEmpty()) {
            throw ErrorCreator.createError(StringUtils.fromString(NO_ANYDATA_TYPE_FOUND_IN_THE_TARGET_TYPE));
        } else if (anydataTypes.size() == 1) {
            return anydataTypes.get(0);
        } else {
            return TypeCreator.createUnionType(anydataTypes);
        }
    }

    private static List<Type> extractAnydataTypes(Type targetType, List<Type> anydataTypes) {
        if (targetType.isAnydata()) {
            anydataTypes.add(targetType);
            return anydataTypes;
        }

        switch (targetType.getTag()) {
            case TypeTags.UNION_TAG:
                List<Type> memberTypes = ((UnionType) targetType).getMemberTypes();
                for (Type memberType : memberTypes) {
                    extractAnydataTypes(memberType, anydataTypes);
                }
                return anydataTypes;
            case TypeTags.TYPE_REFERENCED_TYPE_TAG:
                return extractAnydataTypes(TypeUtils.getImpliedType(targetType), anydataTypes);
            default:
                return anydataTypes;
        }
    }

    private static Object getMediaType(BObject response, Type mediaTypeType, boolean requireValidation) {
        String contentType = getContentType(response);
        try {
            Object convertedValue = ValueUtils.convert(Objects.nonNull(contentType) ?
                    StringUtils.fromString(contentType) : null, mediaTypeType);
            return validateConstraints(requireValidation, convertedValue, mediaTypeType,
                    MEDIA_TYPE_VALIDATION_CLIENT_ERROR, MEDIA_TYPE_BINDING_FAILED);
        } catch (BError conversionError) {
            return createHttpError(MEDIA_TYPE_BINDING_FAILED, MEDIA_TYPE_BINDING_CLIENT_ERROR, conversionError);
        }
    }

    private static String getContentType(BObject response) {
        HttpHeaders httpHeaders = (HttpHeaders) response.getNativeData(HTTP_HEADERS);
        return httpHeaders.get("Content-Type");
    }

    private static Object getHeadersMap(BObject response, Type headersType, boolean requireValidation) {
        HttpHeaders httpHeaders = (HttpHeaders) response.getNativeData(HTTP_HEADERS);
        Type headersImpliedType = TypeUtils.getImpliedType(headersType);
        if (headersImpliedType.getTag() == TypeTags.TYPE_REFERENCED_TYPE_TAG) {
            headersImpliedType = TypeUtils.getReferredType(headersImpliedType);
        }

        Object headerMap;
        if (headersImpliedType.getTag() == TypeTags.MAP_TAG) {
            headerMap = createHeaderMap(httpHeaders,
                    TypeUtils.getImpliedType(((MapType) headersImpliedType).getConstrainedType()));
        } else if (headersImpliedType.getTag() == TypeTags.RECORD_TYPE_TAG) {
            headerMap = createHeaderRecord(httpHeaders, (RecordType) headersImpliedType);
        } else {
            return createHttpError(String.format(UNSUPPORTED_HEADERS_TYPE, headersType),
                    STATUS_CODE_RECORD_BINDING_ERROR);
        }

        if (headerMap instanceof BError) {
            return headerMap;
        }

        try {
            Object convertedHeaderMap = ValueUtils.convert(headerMap, headersType);
            return validateConstraints(requireValidation, convertedHeaderMap, headersType,
                    HEADER_VALIDATION_CLIENT_ERROR, HEADER_BINDING_FAILED);
        } catch (BError conversionError) {
            return createHttpError(HEADER_BINDING_FAILED, HEADER_BINDING_CLIENT_ERROR, conversionError);
        }
    }

    private static boolean hasHttpResponseType(Type targetType) {
        return switch (targetType.getTag()) {
            case TypeTags.OBJECT_TYPE_TAG -> true;
            case TypeTags.UNION_TAG -> ((UnionType) targetType).getMemberTypes().stream().anyMatch(
                    ExternResponseProcessor::hasHttpResponseType);
            case TypeTags.TYPE_REFERENCED_TYPE_TAG -> hasHttpResponseType(TypeUtils.getImpliedType(targetType));
            default -> false;
        };
    }

    private static Optional<Type> getStatusCodeResponseType(Type targetType, String statusCode) {
        if (isStatusCodeResponseType(targetType)) {
            if (getStatusCode(targetType).equals(statusCode)) {
                return Optional.of(targetType);
            }
        } else if (targetType instanceof UnionType unionType) {
            return unionType.getMemberTypes().stream()
                    .map(member -> getStatusCodeResponseType(member, statusCode))
                    .filter(Optional::isPresent)
                    .flatMap(Optional::stream)
                    .findFirst();
        } else if (targetType instanceof ReferenceType
                && (!targetType.equals(TypeUtils.getImpliedType(targetType)))) {
                return getStatusCodeResponseType(TypeUtils.getImpliedType(targetType), statusCode);
        }
        return Optional.empty();
    }

    private static boolean isStatusCodeResponseType(Type targetType) {
        return targetType instanceof ReferenceType referenceType &&
                TypeUtils.getImpliedType(referenceType) instanceof RecordType recordType &&
                recordType.getFields().containsKey(STATUS_CODE_RESPONSE_STATUS_FIELD) &&
                recordType.getFields().get(STATUS_CODE_RESPONSE_STATUS_FIELD).getFieldType() instanceof ObjectType;
    }

    private static String getStatusCode(Type targetType) {
        return ((ObjectType) ((RecordType) TypeUtils.getImpliedType(targetType)).getFields().
                get(STATUS_CODE_RESPONSE_STATUS_FIELD).getFieldType()).getFields().
                get(STATUS_CODE_RESPONSE_STATUS_CODE_FIELD).getFieldType().getEmptyValue().toString();
    }

    private static Object createHeaderMap(HttpHeaders httpHeaders, Type elementType) {
        BMap<BString, Object> headerMap = ValueCreator.createMapValue();
        Set<String> headerNames = httpHeaders.names();
        for (String headerName : headerNames) {
            List<String> headerValues = getHeader(httpHeaders, headerName);
            try {
                Object convertedValue = convertHeaderValues(headerValues, elementType);
                headerMap.put(StringUtils.fromString(headerName), convertedValue);
            } catch (BError ex) {
                return createHttpError(String.format(HEADER_BINDING_FAILED_ERROR_MSG, headerName),
                        HEADER_BINDING_CLIENT_ERROR,  ex);
            }
        }
        return headerMap;
    }

    private static Object createHeaderRecord(HttpHeaders httpHeaders, RecordType headersType) {
        Map<String, Field> headers = headersType.getFields();
        BMap<BString, Object> headerMap = ValueCreator.createMapValue();
        for (Map.Entry<String, Field> header : headers.entrySet()) {
            Field headerField = header.getValue();
            Type headerFieldType = TypeUtils.getImpliedType(headerField.getFieldType());

            String headerName = header.getKey();
            List<String> headerValues = getHeader(httpHeaders, headerName);

            if (headerValues.isEmpty()) {
                // Only optional is allowed at the moment
                if (isOptionalHeaderField(headerField)) {
                    continue;
                }
                // Return Header Not Found Error
                return createHttpError(String.format(NO_HEADER_VALUE_ERROR_MSG, headerName),
                        HEADER_NOT_FOUND_CLIENT_ERROR);
            }

            try {
                Object convertedValue = convertHeaderValues(headerValues, headerFieldType);
                headerMap.put(StringUtils.fromString(headerName), convertedValue);
            } catch (BError ex) {
                return createHttpError(String.format(HEADER_BINDING_FAILED_ERROR_MSG, headerName),
                        HEADER_BINDING_CLIENT_ERROR, ex);
            }
        }
        return headerMap;
    }

    private static BArray parseHeaderValue(List<String> header) {
        Object[] parsedValues;
        try {
            parsedValues = header.stream().map(JsonUtils::parse).toList().toArray();
        } catch (Exception e) {
            parsedValues = header.stream().map(StringUtils::fromString).toList().toArray();
        }
        return ValueCreator.createArrayValue(parsedValues, TypeCreator.createArrayType(PredefinedTypes.TYPE_JSON));
    }

    static class HeaderTypeInfo {
        private boolean hasString = false;
        private boolean hasStringArray = false;
        private boolean hasArray = false;
    }

    private static HeaderTypeInfo getHeaderTypeInfo(Type headerType, HeaderTypeInfo headerTypeInfo,
                                                    boolean fromArray) {
        switch (headerType.getTag()) {
            case TypeTags.STRING_TAG:
                if (fromArray) {
                    headerTypeInfo.hasStringArray = true;
                } else {
                    headerTypeInfo.hasString = true;
                }
                return headerTypeInfo;
            case TypeTags.ARRAY_TAG:
                headerTypeInfo.hasArray = true;
                Type elementType = ((ArrayType) headerType).getElementType();
                return getHeaderTypeInfo(elementType, headerTypeInfo, true);
            case TypeTags.UNION_TAG:
                List<Type> memberTypes = ((UnionType) headerType).getMemberTypes();
                for (Type memberType : memberTypes) {
                    headerTypeInfo = getHeaderTypeInfo(memberType, headerTypeInfo, false);
                }
                return headerTypeInfo;
            case TypeTags.TYPE_REFERENCED_TYPE_TAG:
                return getHeaderTypeInfo(TypeUtils.getImpliedType(headerType), headerTypeInfo, false);
            default:
                return headerTypeInfo;
        }
    }

    private static Object convertHeaderValues(List<String> headerValues, Type headerType) {
        HeaderTypeInfo headerTypeInfo = getHeaderTypeInfo(headerType, new HeaderTypeInfo(), false);
        if (headerTypeInfo.hasString) {
            return StringUtils.fromString(headerValues.get(0));
        } else if (headerTypeInfo.hasStringArray) {
            return StringUtils.fromStringArray(headerValues.toArray(new String[0]));
        } else {
            BArray parsedValues = parseHeaderValue(headerValues);
            if (headerTypeInfo.hasArray) {
                try {
                    return ValueUtils.convert(parsedValues, headerType);
                } catch (BError e) {
                    return ValueUtils.convert(parsedValues.get(0), headerType);
                }
            } else {
                return ValueUtils.convert(parsedValues.get(0), headerType);
            }
        }
    }

    private static Object getPayload(Runtime runtime, BObject response, Type payloadType, boolean requireValidation) {
        return performBalDataBinding(runtime, response, payloadType, requireValidation);
    }

    private static boolean isOptionalHeaderField(Field headerField) {
        return SymbolFlags.isFlagOn(headerField.getFlags(), SymbolFlags.OPTIONAL);
    }

    private static List<String> getHeader(HttpHeaders httpHeaders, String headerName) {
        return httpHeaders.getAllAsString(headerName);
    }

    private static Object validateConstraints(boolean requireValidation, Object convertedValue, Type type,
                                              HttpErrorType errorType, String errorMsg) {
        if (requireValidation) {
            Object result = Constraints.validate(convertedValue, ValueCreator.createTypedescValue(type));
            if (result instanceof BError bError) {
                String message = errorMsg + ": " + HttpUtil.getPrintableErrorMsg(bError);
                return createHttpError(message, errorType);
            }
        }
        return convertedValue;
    }

    public static Object performBalDataBinding(Runtime runtime, BObject response, Type payloadType,
                                               boolean requireValidation) {
        final Object[] payload = new Object[1];
        CountDownLatch countDownLatch = new CountDownLatch(1);
        Callback returnCallback = new Callback() {
            @Override
            public void notifySuccess(Object result) {
                payload[0] = result;
                countDownLatch.countDown();
            }

            @Override
            public void notifyFailure(BError result) {
                payload[0] = result;
                countDownLatch.countDown();
            }
        };
        Object[] paramFeed = new Object[4];
        paramFeed[0] = ValueCreator.createTypedescValue(payloadType);
        paramFeed[1] = true;
        paramFeed[2] = requireValidation;
        paramFeed[3] = true;
        runtime.invokeMethodAsyncSequentially(response, PERFORM_DATA_BINDING, null,
                ModuleUtils.getNotifySuccessMetaData(), returnCallback, null, PredefinedTypes.TYPE_ANY,
                paramFeed);
        try {
            countDownLatch.await();
            return payload[0];
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            return createHttpError(PAYLOAD_BINDING_FAILED, CLIENT_ERROR, HttpUtil.createError(exception));
        }
    }

    public static Object getApplicationResponseError(Runtime runtime, BObject response) {
        final Object[] clientError = new Object[1];
        CountDownLatch countDownLatch = new CountDownLatch(1);
        Callback returnCallback = new Callback() {
            @Override
            public void notifySuccess(Object result) {
                clientError[0] = result;
                countDownLatch.countDown();
            }

            @Override
            public void notifyFailure(BError result) {
                clientError[0] = result;
                countDownLatch.countDown();
            }
        };
        runtime.invokeMethodAsyncSequentially(response, GET_APPLICATION_RESPONSE_ERROR, null,
                ModuleUtils.getNotifySuccessMetaData(), returnCallback, null, PredefinedTypes.TYPE_ERROR);
        try {
            countDownLatch.await();
            return clientError[0];
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            return createHttpError(APPLICATION_RES_ERROR_CREATION_FAILED,
                    PAYLOAD_BINDING_CLIENT_ERROR, HttpUtil.createError(exception));
        }
    }
}
