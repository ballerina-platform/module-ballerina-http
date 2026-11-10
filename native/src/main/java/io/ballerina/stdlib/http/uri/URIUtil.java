/*
*  Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package io.ballerina.stdlib.http.uri;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.http.api.HttpConstants;
import io.ballerina.stdlib.http.api.HttpErrorType;
import io.ballerina.stdlib.http.api.HttpUtil;
import io.ballerina.stdlib.http.transport.message.HttpCarbonMessage;

import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.BitSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Stream;

/**
 * Utilities related to URI processing.
 */
public final class URIUtil {

    public static final String URI_PATH_DELIMITER = "/";
    private static final BitSet DONT_ENCODE = new BitSet(256);

    static {
        for (int i = 'a'; i <= 'z'; i++) {
            DONT_ENCODE.set(i);
        }
        for (int i = 'A'; i <= 'Z'; i++) {
            DONT_ENCODE.set(i);
        }
        for (int i = '0'; i <= '9'; i++) {
            DONT_ENCODE.set(i);
        }

        DONT_ENCODE.set('-');
        DONT_ENCODE.set('.');
        DONT_ENCODE.set('_');
        DONT_ENCODE.set('~');

        DONT_ENCODE.set('!');
        DONT_ENCODE.set('$');
        DONT_ENCODE.set('&');
        DONT_ENCODE.set('\'');
        DONT_ENCODE.set('(');
        DONT_ENCODE.set(')');
        DONT_ENCODE.set('*');
        DONT_ENCODE.set('+');
        DONT_ENCODE.set(',');
        DONT_ENCODE.set(';');
        DONT_ENCODE.set('=');
        DONT_ENCODE.set(':');
        DONT_ENCODE.set('@');
    }

    private enum ComparisonMode { FULL_MATCH, CONTAINS, SUBPATH }

    private static int compareSegments(String encoded, String plain, ComparisonMode mode) {
        int srcIdx = 0, tgtIdx = 0, srcLen = encoded.length(), tgtLen = plain.length();
        while (srcIdx < srcLen && tgtIdx < tgtLen) {
            char srcChar = encoded.charAt(srcIdx);
            char tgtChar = plain.charAt(tgtIdx);
            if (srcChar == tgtChar) {
                srcIdx++; tgtIdx++;
            } else if (srcChar == '%') {
                if (srcIdx + 2 >= srcLen) {
                    return -1;
                }
                try {
                    int decoded = Integer.parseInt(encoded.substring(srcIdx + 1, srcIdx + 3), 16);
                    if (decoded != tgtChar) {
                        return -1;
                    }
                } catch (NumberFormatException e) {
                    return -1;
                }
                srcIdx += 3; tgtIdx++;
            } else {
                if (mode == ComparisonMode.CONTAINS) {
                    srcIdx++;
                } else {
                    return -1;
                }
            }
        }
        if (mode == ComparisonMode.FULL_MATCH) {
            return (srcIdx == srcLen && tgtIdx == tgtLen) ? 1 : -1;
        } else if (mode == ComparisonMode.CONTAINS) {
            return (srcIdx == srcLen) ? 1 : -1;
        } else {
            return tgtIdx == tgtLen ? srcIdx : -1;
        }
    }

    public static boolean isPathSegmentEqual(String encodedSegment, String plainSegment) {
        return compareSegments(encodedSegment, plainSegment, ComparisonMode.FULL_MATCH) == 1;
    }

    public static boolean containsPathSegment(String encodedPart, String plainPart) {
        return compareSegments(encodedPart, plainPart, ComparisonMode.CONTAINS) == 1;
    }

    public static String getSubPath(String path, String basePath) {
        int idx = compareSegments(path, basePath, ComparisonMode.SUBPATH);
        if (idx == -1) {
            return path;
        }
        if (idx < path.length()) {
            return path.substring(idx);
        }
        return URI_PATH_DELIMITER;
    }

    public static String encodePathSegment(String pathSegment) {
        StringBuilder encoded = new StringBuilder();
        byte[] bytes = pathSegment.getBytes(StandardCharsets.UTF_8);

        for (byte b : bytes) {
            int charValue = b & 0xFF;

            if (DONT_ENCODE.get(charValue) &&
                    charValue != '/' && charValue != '?' && charValue != '#' && charValue != '%') {
                encoded.append((char) charValue);
            } else {
                encoded.append('%');
                encoded.append(String.format("%02X", charValue));
            }
        }
        return encoded.toString();
    }

    public static List<String> getPathSegments(String path) {
        return Stream.of(path.split("/"))
                .filter(segment -> !segment.isEmpty())
                .toList();
    }

    public static boolean isPathMatch(String encodedPath, String plainPath) {
        List<String> encodedSegments = getPathSegments(encodedPath);
        List<String> plainSegments = getPathSegments(plainPath);

        if (encodedSegments.size() < plainSegments.size()) {
            return false;
        }

        for (int i = 0; i < plainSegments.size(); i++) {
            if (!isPathSegmentEqual(encodedSegments.get(i), plainSegments.get(i))) {
                return false;
            }
        }
        return true;
    }

    /**
     * Percent-decodes the value exactly once, rejecting malformed escapes.
     *
     * @param value       the encoded value
     * @param plusAsSpace whether {@code +} becomes a space (query values)
     * @return the decoded value
     * @throws MalformedPercentEncodingException if the value has a malformed percent-escape. Escapes that decode
     *                                           to invalid UTF-8 are replaced with U+FFFD, not rejected.
     */
    public static String percentDecode(String value, boolean plusAsSpace) {
        if (value.indexOf('%') < 0 && (!plusAsSpace || value.indexOf('+') < 0)) {
            return value;
        }
        int length = value.length();
        ByteArrayOutputStream bytes = new ByteArrayOutputStream(length);
        int i = 0;
        while (i < length) {
            int codePoint = value.codePointAt(i);
            if (codePoint == '%') {
                bytes.write(decodeEscape(value, i));
                i += 3;
            } else if (codePoint == '+' && plusAsSpace) {
                bytes.write(' ');
                i++;
            } else {
                if (codePoint < 128) {
                    bytes.write(codePoint);
                } else {
                    byte[] encoded = new String(Character.toChars(codePoint)).getBytes(StandardCharsets.UTF_8);
                    bytes.write(encoded, 0, encoded.length);
                }
                i += Character.charCount(codePoint);
            }
        }
        return new String(bytes.toByteArray(), StandardCharsets.UTF_8);
    }

    private static int decodeEscape(String value, int percentIndex) {
        int high = percentIndex + 2 < value.length() ? hexValue(value.charAt(percentIndex + 1)) : -1;
        int low = percentIndex + 2 < value.length() ? hexValue(value.charAt(percentIndex + 2)) : -1;
        if (high < 0 || low < 0) {
            throw new MalformedPercentEncodingException();
        }
        return (high << 4) | low;
    }

    private static int hexValue(char ch) {
        return ch < 128 ? Character.digit(ch, 16) : -1;
    }

    /**
     * Populates the map with the decoded query parameters.
     *
     * @param queryParamString the raw query string
     * @param queryParamsMap   the map to populate
     * @throws UnsupportedEncodingException never thrown; declared because other modules catch it
     */
    @SuppressWarnings("unchecked")
    public static void populateQueryParamMap(String queryParamString, BMap<BString, Object> queryParamsMap)
            throws UnsupportedEncodingException {
        Map<String, List<String>> tempParamMap = new HashMap<>();
        String[] queryParamVals = queryParamString.split("&");
        for (String queryParam : queryParamVals) {
            int index = queryParam.indexOf('=');
            if (index == -1) {
                if (!tempParamMap.containsKey(queryParam)) {
                    tempParamMap.put(queryParam, null);
                }
                continue;
            }
            String queryParamName = queryParam.substring(0, index).trim();
            String queryParamValue = queryParam.substring(index + 1).trim();
            List<String> values = new ArrayList<>();
            Set<String> uniqueValues = new HashSet<>();
            for (String val : queryParamValue.split(",")) {
                String decodedValue = percentDecode(val, true);
                if (uniqueValues.add(decodedValue)) {
                    values.add(decodedValue);
                }
            }

            if (tempParamMap.containsKey(queryParamName) && tempParamMap.get(queryParamName) != null) {
                tempParamMap.get(queryParamName).addAll(values);
            } else {
                tempParamMap.put(queryParamName, values);
            }
        }

        for (Map.Entry<String, List<String>> entry : tempParamMap.entrySet()) {
            List<String> entryValue = entry.getValue();
            if (entryValue != null) {
                queryParamsMap.put(StringUtils.fromString(entry.getKey()),
                        StringUtils.fromStringArray(entryValue.toArray(new String[0])));
            } else {
                queryParamsMap.put(StringUtils.fromString(entry.getKey()), null);
            }
        }
    }

    @SuppressWarnings("unchecked")
    public static BMap<BString, Object> getMatrixParamsMap(String path, HttpCarbonMessage carbonMessage) {
        BMap<BString, Object> matrixParamsBMap = ValueCreator.createMapValue();
        Map<String, Map<String, String>> pathToMatrixParamMap =
                (Map<String, Map<String, String>>) carbonMessage.getProperty(HttpConstants.MATRIX_PARAMS);
        Map<String, String> matrixParamsMap = pathToMatrixParamMap.get(path);
        if (matrixParamsMap != null) {
            for (Map.Entry<String, String> matrixParamEntry : matrixParamsMap.entrySet()) {
                matrixParamsBMap.put(StringUtils.fromString(matrixParamEntry.getKey()),
                                     StringUtils.fromString(matrixParamEntry.getValue()));
            }
        }
        return matrixParamsBMap;
    }


    public static String extractMatrixParams(String path, Map<String, Map<String, String>> matrixParams,
                                             HttpCarbonMessage inboundReqMsg) {
        if (path.startsWith("/")) {
            path = path.substring(1);
        }
        String[] pathSplits = path.split("\\?", 2);
        String[] pathSegments = pathSplits[0].split("/");
        String pathToMatrixParam = "";
        for (String pathSegment : pathSegments) {
            String[] splitPathSegment = pathSegment.split(";");
            if (splitPathSegment.length == 0) {
                // A segment made only of ';' has no segment name.
                String message = String.format("found a segment without a name in path '%s'", path);
                throw HttpUtil.createHttpStatusCodeError(HttpErrorType.INTERNAL_BAD_MATRIX_PARAMS_ERROR, message);
            }
            pathToMatrixParam = pathToMatrixParam.concat("/" + splitPathSegment[0]);
            Map<String, String> segmentMatrixParams = new HashMap<>();
            for (int i = 1; i < splitPathSegment.length; i++) {
                String[] splitMatrixParam = splitPathSegment[i].split("=");
                if (splitMatrixParam.length != 2) {
                    String message = String.format("found non-matrix parameter '%s' in path '%s'",
                            splitPathSegment[i], path);
                    throw HttpUtil.createHttpStatusCodeError(HttpErrorType.INTERNAL_BAD_MATRIX_PARAMS_ERROR, message);
                }
                segmentMatrixParams.put(splitMatrixParam[0], splitMatrixParam[1]);
            }
            matrixParams.put(pathToMatrixParam, segmentMatrixParams);
        }

        // An empty query ("/base?") is dropped, as before.
        if (pathSplits.length > 1 && !pathSplits[1].isEmpty()) {
            pathToMatrixParam = pathToMatrixParam.concat("?").concat(pathSplits[1]);
        }
        return pathToMatrixParam;
    }

    private URIUtil() {}
}
