/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.api.nativeimpl;

import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.PredefinedTypes;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.text.SimpleDateFormat;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;

/**
 * Utilities related to time formatting.
 */
public class ExternFormatter {
    private static final String RFC_1123_DATE_TIME = "RFC_1123_DATE_TIME";

    public static Object utcFromString(BString inputString, BString pattern) {
        try {
            Instant instant;
            if (RFC_1123_DATE_TIME.equals(pattern.getValue())) {
                instant = Instant.from(DateTimeFormatter.RFC_1123_DATE_TIME.parse(inputString.getValue()));
            } else {
                java.util.Date formatter = new SimpleDateFormat(pattern.getValue())
                        .parse(inputString.getValue());
                instant = formatter.toInstant();
            }
            long secondsFromEpoc = instant.getEpochSecond();
            BigDecimal lastSecondFraction = new BigDecimal(instant.getNano()).divide(
                    new BigDecimal(1000000000), MathContext.DECIMAL128).setScale(9, RoundingMode.HALF_UP);
            BArray utcTuple = ValueCreator.createTupleValue(TypeCreator.createTupleType(
                    Arrays.asList(PredefinedTypes.TYPE_INT, PredefinedTypes.TYPE_DECIMAL)));
            utcTuple.add(0, secondsFromEpoc);
            utcTuple.add(1, ValueCreator.createDecimalValue(lastSecondFraction));
            utcTuple.freezeDirect();
            return utcTuple;
        } catch (Exception e) {
            return HttpUtil.createHttpError("failed parsing: " + e.getMessage(),
                                            HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }

    public static Object utcToString(BArray utc, BString pattern) {
        try {
            long secondsFromEpoc = 0;
            BigDecimal lastSecondFraction = new BigDecimal(0);
            if (utc.getLength() == 2) {
                secondsFromEpoc = utc.getInt(0);
                lastSecondFraction = new BigDecimal(utc.getValues()[1].toString()).multiply(new BigDecimal(1000000000));
            } else if (utc.getLength() == 1) {
                secondsFromEpoc = utc.getInt(0);
            }
            Instant instant = Instant.ofEpochSecond(secondsFromEpoc, lastSecondFraction.intValue());
            ZonedDateTime zonedDateTime = instant.atZone(ZoneId.of("Z"));
            DateTimeFormatter dateTimeFormatter;
            if (RFC_1123_DATE_TIME.equals(pattern.getValue())) {
                dateTimeFormatter = DateTimeFormatter.RFC_1123_DATE_TIME;
            } else {
                dateTimeFormatter = DateTimeFormatter.ofPattern(pattern.getValue());
            }
            return StringUtils.fromString(zonedDateTime.format(dateTimeFormatter));
        } catch (Exception e) {
            return HttpUtil.createHttpError("failed formatting: " + e.getMessage(),
                                            HttpErrorType.GENERIC_LISTENER_ERROR);
        }
    }

    private ExternFormatter() {}
}
