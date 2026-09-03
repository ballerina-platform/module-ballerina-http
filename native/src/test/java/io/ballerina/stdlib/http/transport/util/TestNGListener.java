/*
 *  Copyright (c) 2017, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 *
 */

package io.ballerina.stdlib.http.transport.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.ITestResult;
import org.testng.TestListenerAdapter;
import org.testng.internal.thread.ThreadTimeoutException;

import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.TimeUnit;

/**
 * Test listener for HTTP transport test cases.
 */
public class TestNGListener extends TestListenerAdapter {

    @Override
    public void beforeConfiguration(ITestResult tr) {
        PrintStream printStream = new PrintStream(System.out);
        if (tr.getMethod().isBeforeClassConfiguration()) {
//            printStream.print("\n");
            String testClassName = tr.getTestClass().getRealClass().getSimpleName();
            String[] testClassWords = testClassName.split("(?<!^)(?=[A-Z])");
            String testClassNameFull = "";
            for (String wordOfName: testClassWords) {
                testClassNameFull = testClassNameFull + wordOfName + " ";
            }
            printStream.println("Start Running " + testClassNameFull.trim() + " ...");
        }
    }

    @Override
    public void onTestStart(ITestResult result) {
        String testCase = result.getName();
        LoggerFactory.getLogger(result.getTestClass().getRealClass()).info("Test running: " + testCase);
    }

    @Override
    public void onTestSuccess(ITestResult tr) {
        String testCase = tr.getName();
        LoggerFactory.getLogger(tr.getTestClass().getRealClass()).info("Test successful: " + testCase);
    }

    @Override
    public void onTestSkipped(ITestResult tr) {
        String testCase = tr.getName();
        LoggerFactory.getLogger(tr.getTestClass().getRealClass()).info("Test skipped: " + testCase);
    }

    @Override
    public void onTestFailure(ITestResult tr) {
        String testCase = tr.getName();
        Throwable e = tr.getThrowable();
        LoggerFactory.getLogger(tr.getTestClass().getRealClass()).error(
                "Test failed: " + testCase + "-> " + e.getMessage());
    }

    @Override
    public void onConfigurationFailure(ITestResult tr) {
        Logger log = LoggerFactory.getLogger(tr.getTestClass().getRealClass());
        Throwable e = tr.getThrowable();
        log.error("Configuration failed: " + tr.getName() + "-> " + (e == null ? "" : e.getMessage()));
        if (e instanceof ThreadTimeoutException) {
            // A setUp or tearDown that times out leaves no clue as to which thread it was waiting on.
            log.error(platformThreadDump());
            log.error(fullThreadDump());
        }
    }

    // Thread.getAllStackTraces() covers platform threads only, so a service blocked on a virtual thread would
    // not show up above. jcmd reports both.
    private static String fullThreadDump() {
        Path out = null;
        try {
            out = Files.createTempFile("thread-dump", ".txt");
            Files.delete(out);
            Process jcmd = new ProcessBuilder("jcmd", String.valueOf(ProcessHandle.current().pid()),
                                              "Thread.dump_to_file", "-format=plain", out.toString())
                    .redirectErrorStream(true).start();
            if (!jcmd.waitFor(60, TimeUnit.SECONDS)) {
                jcmd.destroyForcibly();
                return "jcmd thread dump timed out";
            }
            return "Full thread dump including virtual threads:\n" + Files.readString(out);
        } catch (Exception e) {
            return "Could not capture a full thread dump: " + e;
        } finally {
            deleteQuietly(out);
        }
    }

    private static void deleteQuietly(Path path) {
        if (path == null) {
            return;
        }
        try {
            Files.deleteIfExists(path);
        } catch (IOException e) {
            LoggerFactory.getLogger(TestNGListener.class).debug("Could not delete {}", path, e);
        }
    }

    private static String platformThreadDump() {
        StringBuilder dump = new StringBuilder("Platform thread dump at configuration failure:\n");
        Thread.getAllStackTraces().forEach((thread, frames) -> {
            dump.append('\n').append('"').append(thread.getName()).append("\" ").append(thread.getState());
            if (thread.isDaemon()) {
                dump.append(" daemon");
            }
            dump.append('\n');
            for (StackTraceElement frame : frames) {
                dump.append("\tat ").append(frame).append('\n');
            }
        });
        return dump.toString();
    }
}
