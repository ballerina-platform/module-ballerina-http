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
import io.ballerina.runtime.api.TypeTags;
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
import io.netty.handler.codec.http.HttpHeaders;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_HEADER;
import static io.ballerina.stdlib.http.api.HttpConstants.HTTP_HEADERS;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_BODY_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_HEADERS_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_STATUS_CODE_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.STATUS_CODE_RESPONSE_STATUS_FIELD;
import static io.ballerina.stdlib.http.api.HttpErrorType.CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_NOT_FOUND_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.HEADER_VALIDATION_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.MEDIA_TYPE_VALIDATION_CLIENT_ERROR;
import static io.ballerina.stdlib.http.api.HttpErrorType.STATUS_CODE_RESPONSE_BINDING_ERROR;
import static io.ballerina.stdlib.http.api.HttpUtil.createHttpError;
import static io.ballerina.stdlib.http.api.ValueCreatorUtils.createDefaultStatusCodeObject;
import static io.ballerina.stdlib.http.api.ValueCreatorUtils.createStatusCodeObject;

/**
 * Extern response processor to process the response and generate the response with the given target type.
 *
 * @since 2.11.0
 */
public final class ExternResponseProcessor {

    private static final String NO_HEADER_VALUE_ERROR_MSG = "no header value found for '%s'";
    private static final String HEADER_BINDING_FAILED_ERROR_MSG = "header binding failed for parameter: '%s'";
    private static final String HEADER_BINDING_FAILED = "header binding failed";
    private static final String UNSUPPORTED_HEADERS_TYPE = "unsupported headers type: %s";
    private static final String UNSUPPORTED_STATUS_CODE = "unsupported status code: %d";
    private static final String INCOMPATIBLE_TYPE_FOUND_FOR_RESPONSE = "incompatible type: %s found for the response" +
            " with status code: %d";
    private static final String MEDIA_TYPE_BINDING_FAILED = "media-type binding failed";
    private static final String APPLICATION_RES_ERROR_CREATION_FAILED = "http:ApplicationResponseError creation failed";
    private static final String STATUS_CODE_RES_CREATION_FAILED = "http:StatusCodeResponse creation failed";

    private static final String GET_STATUS_CODE_RESPONSE_BINDING_ERROR = "getStatusCodeResponseBindingError";
    private static final String GET_STATUS_CODE_RESPONSE_DATA_BINDING_ERROR = "getStatusCodeResponseDataBindingError";
    private static final String BUILD_STATUS_CODE_RESPONSE = "buildStatusCodeResponse";


    private static final Map<String, String> STATUS_CODE_OBJS = new HashMap<>();
    private static final String DEFAULT_STATUS = "DefaultStatus";
    private static final String DEFAULT = "default";
    private static final String HEADER = "HEADER";
    private static final String MEDIA_TYPE = "MEDIA_TYPE";
    private static final String GENERIC = "GENERIC";

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
        return getResponseWithType(response, targetType.getDescribingType(), requireValidation, env);
    }

    public static Object buildStatusCodeResponse(BTypedesc statusCodeResponseTypeDesc, BObject status, BMap headers,
                                                 Object body, Object mediaType) {
        if (statusCodeResponseTypeDesc.getDescribingType() instanceof RecordType statusCodeRecordType) {
            BMap<BString, Object> statusCodeRecord = ValueCreator.createRecordValue(statusCodeRecordType);
            statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_STATUS_FIELD), status);
            statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_HEADERS_FIELD), headers);
            if (statusCodeRecordType.getFields().containsKey(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD)) {
                statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD), mediaType);
            }
            if (statusCodeRecordType.getFields().containsKey(STATUS_CODE_RESPONSE_BODY_FIELD)) {
                statusCodeRecord.put(StringUtils.fromString(STATUS_CODE_RESPONSE_BODY_FIELD), body);
            }
            return statusCodeRecord;
        }
        return createHttpError(STATUS_CODE_RES_CREATION_FAILED, CLIENT_ERROR);
    }

    private static Object getResponseWithType(BObject response, Type targetType, boolean requireValidation,
                                              Environment env) {
        long responseStatusCode = getStatusCode(response);

        // Find the most specific status code record type
        Optional<Type> statusCodeResponseType = getSpecificStatusCodeResponseType(targetType,
                Long.toString(responseStatusCode));
        if (statusCodeResponseType.isEmpty()) {
            // Find the default status code record type
            statusCodeResponseType = getDefaultStatusCodeResponseType(targetType);
        }

        if (statusCodeResponseType.isPresent() &&
                TypeUtils.getImpliedType(statusCodeResponseType.get()) instanceof RecordType statusCodeRecordType) {
            try {
                return generateStatusCodeResponseType(response, requireValidation, env, statusCodeRecordType,
                        responseStatusCode);
            } catch (StatusCodeBindingException exp) {
                return getStatusCodeResponseDataBindingError(env, response, exp.getMessage(), exp.getBError(),
                        isDefaultStatusCodeResponseType(statusCodeRecordType), exp.getErrorType());
            }
        }
        String reasonPhrase = String.format(INCOMPATIBLE_TYPE_FOUND_FOR_RESPONSE, targetType.getName(),
                responseStatusCode);
        return getStatusCodeResponseBindingError(env, response, reasonPhrase);
    }

    private static long getStatusCode(BObject response) {
        return response.getIntValue(StringUtils.fromString(STATUS_CODE));
    }

    private static Object generateStatusCodeResponseType(BObject response, boolean requireValidation, Environment env,
                                                         RecordType statusCodeRecordType, long responseStatusCode)
            throws StatusCodeBindingException {
        String statusCodeObjName = STATUS_CODE_OBJS.get(Long.toString(responseStatusCode));
        if (Objects.isNull(statusCodeObjName)) {
            if (isDefaultStatusCodeResponseType(statusCodeRecordType)) {
                statusCodeObjName = DEFAULT_STATUS;
            } else {
                throw new StatusCodeBindingException(GENERIC, String.format(UNSUPPORTED_STATUS_CODE,
                        responseStatusCode));
            }
        }

        Object status = statusCodeObjName.equals(DEFAULT_STATUS) ? createDefaultStatusCodeObject(responseStatusCode) :
                createStatusCodeObject(statusCodeObjName);

        Object headers = getHeaders(response, requireValidation, statusCodeRecordType);
        if (headers instanceof BError) {
            return headers;
        }

        Object mediaType = null;
        if (statusCodeRecordType.getFields().containsKey(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD)) {
            mediaType = getMediaType(response, requireValidation, statusCodeRecordType);
        }

        Type payloadType = null;
        if (statusCodeRecordType.getFields().containsKey(STATUS_CODE_RESPONSE_BODY_FIELD)) {
            payloadType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_BODY_FIELD).getFieldType();
        }
        Object[] paramFeed = getParamFeedForStatusCodeBinding(requireValidation, statusCodeRecordType, payloadType,
                status, headers, mediaType);
        return getStatusCodeResponse(env, response, paramFeed);
    }

    private static Object[] getParamFeedForStatusCodeBinding(boolean requireValidation, RecordType statusCodeType,
                                                             Type payloadType, Object status, Object headers,
                                                             Object mediaType) {
        Object[] paramFeed = new Object[14];
        paramFeed[0] = Objects.isNull(payloadType) ? null : ValueCreator.createTypedescValue(payloadType);
        paramFeed[1] = true;
        paramFeed[2] = ValueCreator.createTypedescValue(statusCodeType);
        paramFeed[3] = true;
        paramFeed[4] = requireValidation;
        paramFeed[5] = true;
        paramFeed[6] = status;
        paramFeed[7] = true;
        paramFeed[8] = headers;
        paramFeed[9] = true;
        paramFeed[10] = mediaType;
        paramFeed[11] = true;
        paramFeed[12] = isDefaultStatusCodeResponseType(statusCodeType);
        paramFeed[13] = true;
        return paramFeed;
    }

    private static Object getHeaders(BObject response, boolean requireValidation, RecordType statusCodeRecordType) {
        Type headersType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_HEADERS_FIELD).getFieldType();
        return getHeadersMap(response, headersType, requireValidation);
    }

    private static Object getMediaType(BObject response, boolean requireValidation, RecordType statusCodeRecordType)
            throws StatusCodeBindingException {
        Type mediaTypeType = statusCodeRecordType.getFields().get(STATUS_CODE_RESPONSE_MEDIA_TYPE_FIELD).getFieldType();
        return getMediaType(response, mediaTypeType, requireValidation);
    }

    private static Object getMediaType(BObject response, Type mediaTypeType, boolean requireValidation)
            throws StatusCodeBindingException {
        String contentType = getContentType(response);
        if (Objects.isNull(contentType)) {
            return null;
        }
        try {
            Object convertedValue = ValueUtils.convert(StringUtils.fromString(contentType), mediaTypeType);
            return validateConstraints(requireValidation, convertedValue, mediaTypeType,
                    MEDIA_TYPE_VALIDATION_CLIENT_ERROR, MEDIA_TYPE_BINDING_FAILED, MEDIA_TYPE);
        } catch (BError conversionError) {
            throw new StatusCodeBindingException(MEDIA_TYPE, MEDIA_TYPE_BINDING_FAILED, conversionError);
        }
    }

    private static String getContentType(BObject response) {
        HttpHeaders httpHeaders = (HttpHeaders) response.getNativeData(HTTP_HEADERS);
        return httpHeaders.get("Content-Type");
    }

    private static Object getHeadersMap(BObject response, Type headersType, boolean requireValidation)
            throws StatusCodeBindingException {
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
            throw new StatusCodeBindingException(HEADER, String.format(UNSUPPORTED_HEADERS_TYPE,
                    headersImpliedType.getName()));
        }

        if (headerMap instanceof BError error) {
            throw new StatusCodeBindingException(HEADER, HEADER_BINDING_FAILED, error);
        }

        try {
            Object convertedHeaderMap = ValueUtils.convert(headerMap, headersType);
            return validateConstraints(requireValidation, convertedHeaderMap, headersType,
                    HEADER_VALIDATION_CLIENT_ERROR, HEADER_BINDING_FAILED, HEADER);
        } catch (BError conversionError) {
            throw new StatusCodeBindingException(HEADER, HEADER_BINDING_FAILED, conversionError);
        }
    }

    private static Optional<Type> getSpecificStatusCodeResponseType(Type targetType, String statusCode) {
        if (isStatusCodeResponseType(targetType)) {
            String statusCodeFromType = getStatusCode(targetType);
            if (statusCodeFromType.equals(statusCode)) {
                return Optional.of(targetType);
            }
        } else if (targetType instanceof UnionType unionType) {
            return unionType.getMemberTypes().stream()
                    .map(member -> getSpecificStatusCodeResponseType(member, statusCode))
                    .filter(Optional::isPresent)
                    .flatMap(Optional::stream)
                    .findFirst();
        } else if (targetType instanceof ReferenceType
                && (!targetType.equals(TypeUtils.getImpliedType(targetType)))) {
            return getSpecificStatusCodeResponseType(TypeUtils.getImpliedType(targetType), statusCode);
        }
        return Optional.empty();
    }

    private static Optional<Type> getDefaultStatusCodeResponseType(Type targetType) {
        return getSpecificStatusCodeResponseType(targetType, DEFAULT);
    }

    private static boolean isStatusCodeResponseType(Type targetType) {
        return targetType instanceof ReferenceType referenceType &&
                TypeUtils.getImpliedType(referenceType) instanceof RecordType recordType &&
                recordType.getFields().containsKey(STATUS_CODE_RESPONSE_STATUS_FIELD) &&
                recordType.getFields().get(STATUS_CODE_RESPONSE_STATUS_FIELD).getFieldType() instanceof ObjectType;
    }

    private static String getStatusCode(Type targetType) {
        ObjectType statusCodeType = (ObjectType) ((RecordType) TypeUtils.getImpliedType(targetType)).getFields().
                get(STATUS_CODE_RESPONSE_STATUS_FIELD).getFieldType();
        if (statusCodeType.getName().equals(DEFAULT_STATUS)) {
            return DEFAULT;
        }
        return statusCodeType.getFields().get(STATUS_CODE_RESPONSE_STATUS_CODE_FIELD).getFieldType().
                getEmptyValue().toString();
    }

    private static boolean isDefaultStatusCodeResponseType(RecordType statusCodeRecordType) {
        return getStatusCode(statusCodeRecordType).equals(DEFAULT);
    }

    private static Object createHeaderMap(HttpHeaders headers, Type elementType) throws StatusCodeBindingException {
        BMap<BString, Object> headerMap = ValueCreator.createMapValue();
        Set<String> headerNames = headers.names();
        for (String headerName : headerNames) {
            List<String> headerValues = getHeader(headers, headerName);
            try {
                Object convertedValue = convertHeaderValues(headerValues, elementType);
                headerMap.put(StringUtils.fromString(headerName), convertedValue);
            } catch (BError ex) {
                throw new StatusCodeBindingException(HEADER, HEADER_BINDING_FAILED, ex);
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

            BString headerFieldName = StringUtils.fromString(header.getKey());
            String headerName = ExternUtils.getName(headerFieldName, headersType, ANN_NAME_HEADER).getValue();
            List<String> headerValues = getHeader(httpHeaders, headerName);

            if (headerValues.isEmpty()) {
                // Only optional is allowed at the moment
                if (isOptionalHeaderField(headerField)) {
                    continue;
                }
                // Return Header Not Found Error
                BError cause = createHttpError(String.format(NO_HEADER_VALUE_ERROR_MSG, headerName),
                        HEADER_NOT_FOUND_CLIENT_ERROR);
                throw new StatusCodeBindingException(HEADER, HEADER_BINDING_FAILED, cause);
            }

            try {
                Object convertedValue = convertHeaderValues(headerValues, headerFieldType);
                headerMap.put(headerFieldName, convertedValue);
            } catch (BError ex) {
                throw new StatusCodeBindingException(HEADER, String.format(HEADER_BINDING_FAILED_ERROR_MSG,
                        headerName), ex);
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

    private static boolean isOptionalHeaderField(Field headerField) {
        return SymbolFlags.isFlagOn(headerField.getFlags(), SymbolFlags.OPTIONAL);
    }

    private static List<String> getHeader(HttpHeaders httpHeaders, String headerName) {
        return httpHeaders.getAllAsString(headerName);
    }

    private static Object validateConstraints(boolean requireValidation, Object convertedValue, Type type,
                                              HttpErrorType errorType, String errorMsg, String paramType)
            throws StatusCodeBindingException {
        if (requireValidation) {
            Object result = Constraints.validate(convertedValue, ValueCreator.createTypedescValue(type));
            if (result instanceof BError bError) {
                String message = errorMsg + ": " + HttpUtil.getPrintableErrorMsg(bError);
                BError cause = createHttpError(message, errorType, bError);
                throw new StatusCodeBindingException(paramType, message, cause);
            }
        }
        return convertedValue;
    }

    private static Object getStatusCodeResponseBindingError(Environment env, BObject response, String reasonPhrase) {
        Object[] paramFeed = new Object[2];
        paramFeed[0] = StringUtils.fromString(reasonPhrase);
        paramFeed[1] = true;
        Object result = env.getRuntime().call(response, GET_STATUS_CODE_RESPONSE_BINDING_ERROR, paramFeed);
        if (result instanceof BError error) {
            return createHttpError(APPLICATION_RES_ERROR_CREATION_FAILED, STATUS_CODE_RESPONSE_BINDING_ERROR, error);
        }
        return result;
    }

    private static Object getStatusCodeResponseDataBindingError(Environment env, BObject response, String reasonPhrase,
                                                                BError cause, boolean isDefaultStatusCodeResponse,
                                                                String errorType) {
        Object[] paramFeed = new Object[8];
        paramFeed[0] = StringUtils.fromString(reasonPhrase);
        paramFeed[1] = true;
        paramFeed[2] = isDefaultStatusCodeResponse;
        paramFeed[3] = true;
        paramFeed[4] = StringUtils.fromString(errorType);
        paramFeed[5] = true;
        paramFeed[6] = cause;
        paramFeed[7] = true;
        Object result = env.getRuntime().call(response, GET_STATUS_CODE_RESPONSE_DATA_BINDING_ERROR, paramFeed);
        if (result instanceof BError error) {
            return createHttpError(APPLICATION_RES_ERROR_CREATION_FAILED, STATUS_CODE_RESPONSE_BINDING_ERROR, error);
        }
        return result;
    }

    private static Object getStatusCodeResponse(Environment env, BObject response, Object[] paramFeed) {
         Object result = env.getRuntime().call(response, BUILD_STATUS_CODE_RESPONSE, paramFeed);
        if (result instanceof BError error) {
            return createHttpError(STATUS_CODE_RES_CREATION_FAILED, STATUS_CODE_RESPONSE_BINDING_ERROR, error);
        }
        return result;
    }
}
