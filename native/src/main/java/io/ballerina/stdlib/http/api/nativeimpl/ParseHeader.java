/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.api.ValueCreatorUtils;
import io.ballerina.stdlib.mime.util.HeaderUtil;

import java.util.Map;

import static io.ballerina.stdlib.http.api.HttpConstants.HEADER_VALUE_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.HEADER_VALUE_PARAM_FIELD;
import static io.ballerina.stdlib.http.api.HttpConstants.HEADER_VALUE_RECORD;
import static io.ballerina.stdlib.http.api.HttpErrorType.GENERIC_CLIENT_ERROR;
import static io.ballerina.stdlib.mime.util.MimeConstants.FAILED_TO_PARSE;
import static io.ballerina.stdlib.mime.util.MimeConstants.SEMICOLON;

/**
 * Extern function to parse header value and get value with parameter map.
 *
 * @since 0.96.1
 */
public class ParseHeader {

    private static final RecordType HEADER_VALUE_TYPE = createHeaderValueType();
    private static final ArrayType ARRAY_TYPE = TypeCreator.createArrayType(HEADER_VALUE_TYPE);
    private static final String COMMA_OUT_OF_QUOTATIONS = "(,)(?=(?:[^\"]|\"[^\"]*\")*$)";

    public static Object parseHeader(BString headerValue) {
        try {
            String[] headerValues = headerValue.getValue().split(COMMA_OUT_OF_QUOTATIONS);
            BArray recordArray = ValueCreator.createArrayValue(ARRAY_TYPE);
            for (int i = 0; i < headerValues.length; i++) {
                String value = headerValues[i].trim();
                if (value.contains(SEMICOLON)) {
                    value = HeaderUtil.getHeaderValue(value);
                }
                BMap<BString, Object> record = ValueCreatorUtils.createHTTPRecordValue(HEADER_VALUE_RECORD);
                record.put(HEADER_VALUE_FIELD, StringUtils.fromString(value));
                record.put(HEADER_VALUE_PARAM_FIELD, HeaderUtil.getParamMap(headerValues[i]));
                recordArray.add(i, record);
            }
            return recordArray;
        } catch (Exception ex) {
            String errMsg = ex instanceof BError ? ex.toString() : ex.getMessage();
            return HttpUtil.createHttpError(FAILED_TO_PARSE + errMsg, GENERIC_CLIENT_ERROR);
        }
    }

    private ParseHeader() {
    }

    private static RecordType createHeaderValueType() {
        return TypeCreator.createRecordType(HEADER_VALUE_RECORD, ModuleUtils.getHttpPackage(), 0,
                Map.of(
                        "value", TypeCreator.createField(PredefinedTypes.TYPE_STRING, "value", 0),
                        "params",
                        TypeCreator.createField(TypeCreator.createMapType(PredefinedTypes.TYPE_STRING), "params", 0)
                ),
                PredefinedTypes.TYPE_NEVER, false, 0);
    }
}
