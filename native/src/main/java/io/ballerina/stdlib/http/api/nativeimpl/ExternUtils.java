// Copyright (c) 2023 WSO2 Org. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 Org. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.netty.handler.codec.http.HttpResponseStatus;

import java.util.Objects;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_HEADER;
import static io.ballerina.stdlib.http.api.HttpConstants.ANN_NAME_QUERY;
import static io.ballerina.stdlib.http.api.HttpConstants.COLON;

/**
 * Contains external utility functions.
 */
public final class ExternUtils {

    public static final String FIELD = "$field$.%s";

    private ExternUtils() {}

    /**
     * Provides the relevant reason phrase for a given status code.
     *
     * @param statusCode Status code value
     * @return Returns the reason phrase of the status code
     */
    public static BString getReasonFromStatusCode(Long statusCode) {
        String reasonPhrase;
        // 451 and 508 are not available in `HttpResponseStatus`.
        if (statusCode.intValue() == 451) {
            reasonPhrase = "Unavailable For Legal Reasons";
        } else if (statusCode.intValue() == 508) {
            reasonPhrase = "Loop Detected";
        } else {
            reasonPhrase = HttpResponseStatus.valueOf(statusCode.intValue()).reasonPhrase();
            if (reasonPhrase.contains("Unknown Status")) {
                reasonPhrase = HttpResponseStatus.valueOf(500).reasonPhrase();
            }
        }
        return StringUtils.fromString(reasonPhrase);
    }

    public static BString getHeaderName(BString originalName, BTypedesc headerTypeDesc) {
        return getName(originalName, headerTypeDesc.getDescribingType(), ANN_NAME_HEADER);
    }

    public static BString getQueryName(BString originalName, BTypedesc queryTypeDesc) {
        return getName(originalName, queryTypeDesc.getDescribingType(), ANN_NAME_QUERY);
    }

    public static BString getName(BString originalName, Type headerType, String annotationName) {
        headerType = TypeUtils.getReferredType(headerType);
        if (headerType.getTag() != TypeTags.RECORD_TYPE_TAG) {
            return originalName;
        }

        BMap<BString, Object> annotations = ((RecordType) headerType).getAnnotations();
        if (Objects.isNull(annotations) || annotations.isEmpty()) {
            return originalName;
        }

        Object fieldAnnotations = annotations.get(StringUtils.fromString(String.format(FIELD, originalName)));
        if (!(fieldAnnotations instanceof BMap fieldAnnotMap)) {
            return originalName;
        }

        return extractHttpAnnotation(fieldAnnotMap, annotationName)
                .flatMap(ExternUtils::extractFieldName)
                .orElse(originalName);
    }

    private static Optional<BMap> extractHttpAnnotation(BMap fieldAnnotMap, String annotationName) {
        for (Object annotRef: fieldAnnotMap.getKeys()) {
            String refRegex = ModuleUtils.getHttpPackageIdentifier() + COLON + annotationName;
            Pattern pattern = Pattern.compile(refRegex);
            Matcher matcher = pattern.matcher(annotRef.toString());
            if (matcher.find()) {
                return Optional.of((BMap) fieldAnnotMap.get(annotRef));
            }
        }
        return Optional.empty();
    }

    private static Optional<BString> extractFieldName(BMap value) {
        Object overrideValue = value.get(HttpConstants.ANN_FIELD_NAME);
        if (!(overrideValue instanceof BString overrideName)) {
            return Optional.empty();
        }
        return Optional.of(overrideName);
    }
}
