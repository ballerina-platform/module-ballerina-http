/*
 *  Copyright (c) 2022 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 LLC. licenses this file to you under the Apache License,
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

package io.ballerina.stdlib.http.testutils;

/**
 * Contains assert functions used by mime test cases.
 */
public final class Assert {

    private Assert() {}

    public static void assertEquals(Object actual, Object expected) {
        if (!areEqual(actual, expected)) {
            fail();
        }
    }

    public static void assertEquals(Object actual, Object expected, String message) {
        if (!areEqual(actual, expected)) {
            fail(message);
        }
    }

    public static void assertNotNull(Object object) {
        if (object == null) {
            fail();
        }
    }

    public static void assertTrue(boolean condition) {
        if (!condition) {
            fail();
        }
    }

    public static void assertTrue(boolean condition, String message) {
        if (!condition) {
            fail(message);
        }
    }

    public static void assertFalse(boolean condition) {
        if (condition) {
            fail();
        }
    }

    private static boolean areEqual(Object actual, Object expected) {
        if ((expected == null) && (actual == null)) {
            return true;
        }
        if (expected == null ^ actual == null) {
            return false;
        }
        if (expected.equals(actual) && actual.equals(expected)) {
            return true;
        }
        return false;
    }

    public static void fail() {
        throw new AssertionError();
    }

    public static void fail(String message) {
        throw new AssertionError(message);
    }
}
