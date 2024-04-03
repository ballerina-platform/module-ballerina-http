package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.Runtime;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.async.Callback;
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
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.ValueCreatorUtils;
import io.netty.handler.codec.http.HttpHeaders;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.CountDownLatch;

import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_HEADERS;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_BODY_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_HEADERS_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_STATUS_CODE_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_STATUS_FIELD;
import static io.ballerina.stdlib.http.api.HttpErrorType.CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.INTERNAL_HEADER_BINDING_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.PAYLOAD_BINDING_CLIENT_ERROR;

public final class ExternResponseProcessor {

    private static final String NO_HEADER_VALUE_ERROR_MSG = "no header value found for '%s'";
    private static final String HEADER_BINDING_FAILED_ERROR_MSG = "header binding failed for parameter: '%s'";
    private static final Map<String, String> STATUS_CODE_OBJS;

    static {
        Map<String, String> statusCodeObjectsMap = new HashMap<>();
        statusCodeObjectsMap.put("100", "StatusContinue");
        statusCodeObjectsMap.put("101", "StatusSwitchingProtocols");
        statusCodeObjectsMap.put("102", "StatusProcessing");
        statusCodeObjectsMap.put("103", "StatusEarlyHints");
        statusCodeObjectsMap.put("200", "StatusOK");
        statusCodeObjectsMap.put("201", "StatusCreated");
        statusCodeObjectsMap.put("202", "StatusAccepted");
        statusCodeObjectsMap.put("203", "StatusNonAuthoritativeInfo");
        statusCodeObjectsMap.put("204", "StatusNoContent");
        statusCodeObjectsMap.put("205", "StatusResetContent");
        statusCodeObjectsMap.put("206", "StatusPartialContent");
        statusCodeObjectsMap.put("207", "StatusMultiStatus");
        statusCodeObjectsMap.put("208", "StatusAlreadyReported");
        statusCodeObjectsMap.put("226", "StatusIMUsed");
        statusCodeObjectsMap.put("300", "StatusMultipleChoices");
        statusCodeObjectsMap.put("301", "StatusMovedPermanently");
        statusCodeObjectsMap.put("302", "StatusFound");
        statusCodeObjectsMap.put("303", "StatusSeeOther");
        statusCodeObjectsMap.put("304", "StatusNotModified");
        statusCodeObjectsMap.put("305", "StatusUseProxy");
        statusCodeObjectsMap.put("307", "StatusTemporaryRedirect");
        statusCodeObjectsMap.put("308", "StatusPermanentRedirect");
        statusCodeObjectsMap.put("400", "StatusBadRequest");
        statusCodeObjectsMap.put("401", "StatusUnauthorized");
        statusCodeObjectsMap.put("402", "StatusPaymentRequired");
        statusCodeObjectsMap.put("403", "StatusForbidden");
        statusCodeObjectsMap.put("404", "StatusNotFound");
        statusCodeObjectsMap.put("405", "StatusMethodNotAllowed");
        statusCodeObjectsMap.put("406", "StatusNotAcceptable");
        statusCodeObjectsMap.put("407", "StatusProxyAuthRequired");
        statusCodeObjectsMap.put("408", "StatusRequestTimeout");
        statusCodeObjectsMap.put("409", "StatusConflict");
        statusCodeObjectsMap.put("410", "StatusGone");
        statusCodeObjectsMap.put("411", "StatusLengthRequired");
        statusCodeObjectsMap.put("412", "StatusPreconditionFailed");
        statusCodeObjectsMap.put("413", "StatusRequestEntityTooLarge");
        statusCodeObjectsMap.put("414", "StatusRequestURITooLong");
        statusCodeObjectsMap.put("415", "StatusUnsupportedMediaType");
        statusCodeObjectsMap.put("416", "StatusRequestedRangeNotSatisfiable");
        statusCodeObjectsMap.put("417", "StatusExpectationFailed");
        statusCodeObjectsMap.put("421", "StatusMisdirectedRequest");
        statusCodeObjectsMap.put("422", "StatusUnprocessableEntity");
        statusCodeObjectsMap.put("423", "StatusLocked");
        statusCodeObjectsMap.put("424", "StatusFailedDependency");
        statusCodeObjectsMap.put("425", "StatusTooEarly");
        statusCodeObjectsMap.put("426", "StatusUpgradeRequired");
        statusCodeObjectsMap.put("428", "StatusPreconditionRequired");
        statusCodeObjectsMap.put("429", "StatusTooManyRequests");
        statusCodeObjectsMap.put("431", "StatusRequestHeaderFieldsTooLarge");
        statusCodeObjectsMap.put("451", "StatusUnavailableForLegalReasons");
        statusCodeObjectsMap.put("500", "StatusInternalServerError");
        statusCodeObjectsMap.put("501", "StatusNotImplemented");
        statusCodeObjectsMap.put("502", "StatusBadGateway");
        statusCodeObjectsMap.put("503", "StatusServiceUnavailable");
        statusCodeObjectsMap.put("504", "StatusGatewayTimeout");
        statusCodeObjectsMap.put("505", "StatusHTTPVersionNotSupported");
        statusCodeObjectsMap.put("506", "StatusVariantAlsoNegotiates");
        statusCodeObjectsMap.put("507", "StatusInsufficientStorage");
        statusCodeObjectsMap.put("508", "StatusLoopDetected");
        statusCodeObjectsMap.put("510", "StatusNotExtended");
        statusCodeObjectsMap.put("511", "StatusNetworkAuthenticationRequired");
        STATUS_CODE_OBJS = statusCodeObjectsMap;
    }

    private ExternResponseProcessor() {
    }

    public static Object processResponse(Environment env, BObject response, BTypedesc targetType,
                                         boolean requireValidation) {
        return getResponseWithType(response, targetType.getDescribingType(), requireValidation, env.getRuntime());
    }

    private static Object getResponseWithType(BObject response, Type targetType, boolean requireValidation,
                                              Runtime runtime) {
        long responseStatusCode = response.getIntValue(StringUtils.fromString("statusCode"));
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
            return e;
        }
    }

    private static Object generateStatusCodeResponseType(BObject response, boolean requireValidation, Runtime runtime,
                                                         RecordType statusCodeRecordType, long responseStatusCode) {
        BMap<BString, Object> statusCodeRecord = ValueCreator.createRecordValue(statusCodeRecordType);

        String statusCodeObjName = STATUS_CODE_OBJS.get(Long.toString(responseStatusCode));
        if (Objects.isNull(statusCodeObjName)) {
            throw HttpUtil.createHttpError("unsupported status code: " + responseStatusCode);
        }
        Object status = ValueCreatorUtils.createStatusCodeObject(statusCodeObjName);
        statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_STATUS_FIELD), status);

        Type mediaTypeType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD).getFieldType();
        Object mediaType = getMediaType(response, mediaTypeType, requireValidation);
        statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD), mediaType);

        Type headersType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_HEADERS_FIELD).getFieldType();
        Object headerMap = getHeadersMap(response, headersType, requireValidation);
        statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_HEADERS_FIELD), headerMap);

        if (statusCodeRecordType.getFields().containsKey(STATUS_CODE_RESPONSE_BODY_FIELD)) {
            Type bodyType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_BODY_FIELD).getFieldType();
            Object payload = getPayload(runtime, response, bodyType, requireValidation);
            if (payload instanceof BError) {
                return payload;
            }
            statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_BODY_FIELD), payload);
        }
        return statusCodeRecord;
    }

    private static Type getAnydataType(Type targetType) {
        List<Type> anydataTypes = extractAnydataTypes(targetType, new ArrayList<>());
        if (anydataTypes.isEmpty()) {
            throw HttpUtil.createHttpError("unsupported target type: " + targetType);
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
            return validateConstraints(requireValidation, convertedValue, mediaTypeType, "media-type binding failed");
        } catch (BError conversionError) {
            throw HttpUtil.createHttpError("media-type binding failed", CLIENT_ERROR, conversionError);
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
            throw HttpUtil.createHttpError("unsupported headers type: " + headersType);
        }
        return validateConstraints(requireValidation, headerMap, headersType, "header binding failed");
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
            List<Type> memberTypes = unionType.getMemberTypes();
            for (Type memberType : memberTypes) {
                Optional<Type> statusCodeResponseType = getStatusCodeResponseType(memberType, statusCode);
                if (statusCodeResponseType.isPresent()) {
                    return statusCodeResponseType;
                }
            }
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

    private static Object createHeaderMap(HttpHeaders httpHeaders, Type elementType) throws BError {
        BMap<BString, Object> headerMap = ValueCreator.createMapValue();
        Set<String> headerNames = httpHeaders.names();
        for (String headerName : headerNames) {
            List<String> headerValues = httpHeaders.getAll(headerName);
            try {
                Object convertedValue = convertHeaderValues(headerValues, elementType);
                headerMap.put(StringUtils.fromString(headerName), convertedValue);
            } catch (Exception ex) {
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_HEADER_BINDING_ERROR,
                        String.format(HEADER_BINDING_FAILED_ERROR_MSG, headerName), null, HttpUtil.createError(ex));
            }
        }
        return headerMap;
    }

    private static Object createHeaderRecord(HttpHeaders httpHeaders, RecordType headersType) throws BError {
        Map<String, Field> headers = headersType.getFields();
        BMap<BString, Object> headerMap = ValueCreator.createMapValue();
        for (Map.Entry<String, Field> header : headers.entrySet()) {
            Field headerField = header.getValue();
            Type headerFieldType = TypeUtils.getImpliedType(headerField.getFieldType());

            String headerName = header.getKey();
            List<String> headerValues = getHeader(httpHeaders, headerName);

            if (Objects.isNull(headerValues) || headerValues.isEmpty()) {
                if (isOptionalHeaderField(headerField) || headerFieldType.isNilable()) {
                    if (headerFieldType.isNilable()) {
                        headerMap.put(StringUtils.fromString(headerName), null);
                    }
                    continue;
                }
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_HEADER_BINDING_ERROR,
                        String.format(NO_HEADER_VALUE_ERROR_MSG, headerName));
            }

            try {
                Object convertedValue = convertHeaderValues(headerValues, headerFieldType);
                headerMap.put(StringUtils.fromString(headerName), convertedValue);
            } catch (Exception ex) {
                throw HttpUtil.createHttpStatusCodeError(INTERNAL_HEADER_BINDING_ERROR,
                        String.format(HEADER_BINDING_FAILED_ERROR_MSG, headerName), null, HttpUtil.createError(ex));
            }
        }
        return headerMap;
    }

    private static BArray parseHeaderValue(List<String> header) {
        List<Object> parsedValues;
        try {
            parsedValues = header.stream().map(JsonUtils::parse).toList();
        } catch (Exception e) {
            parsedValues = Collections.singletonList(header.stream().map(StringUtils::fromString));
        }
        return ValueCreator.createArrayValue(parsedValues.toArray(),
                TypeCreator.createArrayType(PredefinedTypes.TYPE_JSON));
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
        return httpHeaders.getAll(headerName);
    }

    private static Object validateConstraints(boolean requireValidation, Object convertedValue, Type type,
                                              String errorMsg) {
        if (requireValidation) {
            Object result = Constraints.validate(convertedValue, ValueCreator.createTypedescValue(type));
            if (result instanceof BError bError) {
                String message = errorMsg + ": " + HttpUtil.getPrintableErrorMsg(bError);
                throw HttpUtil.createHttpError(message, CLIENT_ERROR);
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
        runtime.invokeMethodAsyncSequentially(response, "performDataBinding", null,
                ModuleUtils.getNotifySuccessMetaData(), returnCallback, null, PredefinedTypes.TYPE_ANY,
                paramFeed);
        try {
            countDownLatch.await();
            return payload[0];
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            return HttpUtil.createHttpError("payload binding failed", CLIENT_ERROR, HttpUtil.createError(exception));
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
        runtime.invokeMethodAsyncSequentially(response, "getApplicationResponseError", null,
                ModuleUtils.getNotifySuccessMetaData(), returnCallback, null, PredefinedTypes.TYPE_ERROR);
        try {
            countDownLatch.await();
            return clientError[0];
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            return HttpUtil.createHttpError("http:ApplicationResponseError creation failed",
                    PAYLOAD_BINDING_CLIENT_ERROR, HttpUtil.createError(exception));
        }
    }
}
