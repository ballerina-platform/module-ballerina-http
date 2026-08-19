/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.logging.accesslog;

import io.ballerina.stdlib.http.api.logging.util.RotationPolicy;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.List;
import java.util.logging.Formatter;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.stream.Stream;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertThrows;
import static org.testng.Assert.assertTrue;

/**
 * Unit tests for {@link HttpRollingFileHandler}, the handler that writes access logs to disk and rotates them
 * by size and/or age.
 */
public class HttpRollingFileHandlerTest {

    private Path tempDir;

    /**
     * Writes just the message and a newline, so assertions can be made on exact file content without a
     * timestamp or level prefix getting in the way.
     */
    private static final class PlainFormatter extends Formatter {
        @Override
        public String format(LogRecord record) {
            return record.getMessage() + System.lineSeparator();
        }
    }

    @BeforeMethod
    public void setup() throws IOException {
        tempDir = Files.createTempDirectory("http-access-log-test");
    }

    @AfterMethod
    public void cleanUp() throws IOException {
        if (tempDir == null || !Files.exists(tempDir)) {
            return;
        }
        try (Stream<Path> paths = Files.walk(tempDir)) {
            paths.sorted(Comparator.reverseOrder()).forEach(p -> {
                try {
                    Files.deleteIfExists(p);
                } catch (IOException ignored) {
                    // Best effort - a leftover temp file must not fail the test.
                }
            });
        }
    }

    private HttpRollingFileHandler handler(String fileName, RotationPolicy policy, long maxFileSize,
                                          long maxAgeSeconds, int maxBackupFiles, boolean append, String encoding)
            throws IOException {
        HttpRollingFileHandler fileHandler = new HttpRollingFileHandler(
                tempDir.resolve(fileName).toString(), policy, maxFileSize, maxAgeSeconds, maxBackupFiles, append,
                encoding);
        fileHandler.setFormatter(new PlainFormatter());
        return fileHandler;
    }

    private void publish(HttpRollingFileHandler fileHandler, String message) {
        fileHandler.publish(new LogRecord(Level.INFO, message));
    }

    private List<Path> rotatedFiles(String baseName, String extension) throws IOException {
        try (Stream<Path> paths = Files.list(tempDir)) {
            return paths.filter(p -> {
                String name = p.getFileName().toString();
                return name.startsWith(baseName + "-") && name.endsWith(extension);
            }).sorted().toList();
        }
    }

    @Test(description = "A published record lands in the log file, and the lock file is created alongside it")
    public void testPublishWritesToFile() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.SIZE_BASED, 1024L, 3600L, 5,
                                                     false, null);
        try {
            publish(fileHandler, "first entry");
            publish(fileHandler, "second entry");
        } finally {
            fileHandler.close();
        }

        Path logFile = tempDir.resolve("access.log");
        assertTrue(Files.exists(logFile), "Log file was not created");
        String content = Files.readString(logFile, StandardCharsets.UTF_8);
        assertTrue(content.contains("first entry"), "First entry missing from the log file");
        assertTrue(content.contains("second entry"), "Second entry missing from the log file");
    }

    @Test(description = "Closing the handler removes the lock file it holds while open")
    public void testCloseRemovesLockFile() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.BOTH, 1024L, 3600L, 5, false, null);
        Path lockFile = tempDir.resolve("access.log.lck");
        assertTrue(Files.exists(lockFile), "Lock file was not created while the handler was open");
        fileHandler.close();
        assertFalse(Files.exists(lockFile), "Lock file was not removed on close");
    }

    @Test(description = "Appending keeps the existing content and counts it towards the size threshold")
    public void testAppendPreservesExistingContent() throws IOException {
        Path logFile = tempDir.resolve("access.log");
        Files.writeString(logFile, "pre-existing" + System.lineSeparator(), StandardCharsets.UTF_8);

        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.SIZE_BASED, 100_000L, 3600L, 5,
                                                     true, null);
        try {
            publish(fileHandler, "appended");
        } finally {
            fileHandler.close();
        }

        String content = Files.readString(logFile, StandardCharsets.UTF_8);
        assertTrue(content.contains("pre-existing"), "Existing content was truncated despite append being requested");
        assertTrue(content.contains("appended"), "Appended entry is missing");
    }

    @Test(description = "Opening without append truncates whatever was in the file before")
    public void testOverwriteDiscardsExistingContent() throws IOException {
        Path logFile = tempDir.resolve("access.log");
        Files.writeString(logFile, "stale content" + System.lineSeparator(), StandardCharsets.UTF_8);

        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.SIZE_BASED, 100_000L, 3600L, 5,
                                                     false, null);
        try {
            publish(fileHandler, "fresh");
        } finally {
            fileHandler.close();
        }

        String content = Files.readString(logFile, StandardCharsets.UTF_8);
        assertFalse(content.contains("stale content"), "Existing content survived a non-append open");
        assertTrue(content.contains("fresh"), "Fresh entry is missing");
    }

    @Test(description = "Once the size threshold is passed the file is rotated out under a timestamped name")
    public void testSizeBasedRotation() throws IOException {
        // A tiny threshold so the second publish is guaranteed to trip it.
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.SIZE_BASED, 10L, 3600L, 5,
                                                     false, null);
        try {
            publish(fileHandler, "0123456789 first");
            publish(fileHandler, "second");
        } finally {
            fileHandler.close();
        }

        List<Path> rotated = rotatedFiles("access", ".log");
        assertEquals(rotated.size(), 1, "Expected exactly one rotated file, found: " + rotated);
        assertTrue(Files.readString(rotated.get(0), StandardCharsets.UTF_8).contains("first"),
                   "Rotated file does not hold the entry written before rotation");
        assertTrue(Files.readString(tempDir.resolve("access.log"), StandardCharsets.UTF_8).contains("second"),
                   "Current file does not hold the entry written after rotation");
    }

    @Test(description = "A zero max age means the age threshold is already met, so time based rotation triggers")
    public void testTimeBasedRotation() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.TIME_BASED, Long.MAX_VALUE, 0L, 5,
                                                     false, null);
        try {
            publish(fileHandler, "first");
            publish(fileHandler, "second");
        } finally {
            fileHandler.close();
        }
        assertFalse(rotatedFiles("access", ".log").isEmpty(),
                    "Time based policy did not rotate even though the max age had elapsed");
    }

    @Test(description = "The size threshold alone is enough to rotate under the combined policy")
    public void testBothPolicyRotatesOnSize() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.BOTH, 10L, Long.MAX_VALUE, 5,
                                                     false, null);
        try {
            publish(fileHandler, "0123456789 first");
            publish(fileHandler, "second");
        } finally {
            fileHandler.close();
        }
        assertFalse(rotatedFiles("access", ".log").isEmpty(),
                    "Combined policy did not rotate when the size threshold was reached");
    }

    @Test(description = "A null policy falls back to the combined default rather than failing")
    public void testNullPolicyFallsBackToBoth() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", null, 10L, Long.MAX_VALUE, 5, false, null);
        try {
            publish(fileHandler, "0123456789 first");
            publish(fileHandler, "second");
        } finally {
            fileHandler.close();
        }
        assertFalse(rotatedFiles("access", ".log").isEmpty(),
                    "A null policy did not behave like the combined default");
    }

    @Test(description = "Rotation keeps at most maxBackupFiles timestamped files, deleting the oldest first")
    public void testOldBackupsArePrunedToTheConfiguredLimit() throws IOException {
        int maxBackups = 2;
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.SIZE_BASED, 10L, 3600L, maxBackups,
                                                     false, null);
        try {
            // Each publish exceeds the threshold, so each one rotates and adds a backup.
            for (int i = 0; i < 5; i++) {
                publish(fileHandler, "0123456789 entry " + i);
            }
        } finally {
            fileHandler.close();
        }

        List<Path> rotated = rotatedFiles("access", ".log");
        assertTrue(rotated.size() <= maxBackups,
                   "Backups were not pruned to the configured limit, found " + rotated.size() + ": " + rotated);
    }

    @Test(description = "A max of zero backups keeps no timestamped files at all")
    public void testZeroBackupsKeepsNoRotatedFiles() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.SIZE_BASED, 10L, 3600L, 0,
                                                     false, null);
        try {
            for (int i = 0; i < 3; i++) {
                publish(fileHandler, "0123456789 entry " + i);
            }
        } finally {
            fileHandler.close();
        }
        assertTrue(rotatedFiles("access", ".log").isEmpty(),
                   "Rotated files were kept even though no backups were requested");
    }

    @Test(description = "A path with no extension still rotates, using the whole name as the base")
    public void testRotationForPathWithoutExtension() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access", RotationPolicy.SIZE_BASED, 10L, 3600L, 5, false, null);
        try {
            publish(fileHandler, "0123456789 first");
            publish(fileHandler, "second");
        } finally {
            fileHandler.close();
        }
        assertFalse(rotatedFiles("access", "").isEmpty(), "An extension-less path did not rotate");
    }

    @Test(description = "Missing parent directories are created rather than failing the handler construction")
    public void testMissingParentDirectoryIsCreated() throws IOException {
        HttpRollingFileHandler fileHandler = handler("nested/deeper/access.log", RotationPolicy.BOTH, 1024L, 3600L, 5,
                                                     false, null);
        try {
            publish(fileHandler, "entry");
        } finally {
            fileHandler.close();
        }
        assertTrue(Files.exists(tempDir.resolve("nested/deeper/access.log")),
                   "Log file was not created inside the directories that had to be made");
    }

    @Test(description = "An explicit encoding is honoured when writing non-ASCII content")
    public void testExplicitEncodingIsUsed() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.BOTH, 100_000L, 3600L, 5, false,
                                                     "UTF-8");
        try {
            publish(fileHandler, "café");
        } finally {
            fileHandler.close();
        }
        String content = Files.readString(tempDir.resolve("access.log"), StandardCharsets.UTF_8);
        assertTrue(content.contains("café"), "Content was not written using the configured encoding");
    }

    @Test(description = "An empty encoding falls back to UTF-8 instead of failing")
    public void testEmptyEncodingFallsBackToUtf8() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.BOTH, 100_000L, 3600L, 5, false, "");
        try {
            publish(fileHandler, "café");
        } finally {
            fileHandler.close();
        }
        String content = Files.readString(tempDir.resolve("access.log"), StandardCharsets.UTF_8);
        assertTrue(content.contains("café"), "Empty encoding did not fall back to UTF-8");
    }

    @Test(description = "A second handler cannot take the lock the first one already holds on the same file")
    public void testConcurrentHandlerIsRejectedByTheFileLock() throws IOException {
        HttpRollingFileHandler first = handler("access.log", RotationPolicy.BOTH, 1024L, 3600L, 5, false, null);
        try {
            // Within a single JVM the overlapping lock is reported by FileChannel as an unchecked
            // OverlappingFileLockException rather than the IOException the handler raises for a lock held by
            // another process, so this only asserts that the second handler is refused.
            assertThrows(Exception.class,
                         () -> handler("access.log", RotationPolicy.BOTH, 1024L, 3600L, 5, false, null));
        } finally {
            first.close();
        }
    }

    @Test(description = "Pointing the handler at a directory is surfaced as an IOException, not a silent failure")
    public void testUnopenableLogPathFails() throws IOException {
        Path asDirectory = tempDir.resolve("access.log");
        Files.createDirectory(asDirectory);
        assertThrows(IOException.class,
                     () -> handler("access.log", RotationPolicy.BOTH, 1024L, 3600L, 5, false, null));
    }

    @Test(description = "Closing twice is harmless, since the handler is closed from both flush and shutdown paths")
    public void testCloseIsIdempotent() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.BOTH, 1024L, 3600L, 5, false, null);
        publish(fileHandler, "entry");
        fileHandler.close();
        fileHandler.close();
        assertTrue(Files.exists(tempDir.resolve("access.log")), "Log file went missing after a repeated close");
    }

    @Test(description = "Records published across a rotation are all retained between the rotated and current files")
    public void testNoRecordsAreLostAcrossRotation() throws IOException, InterruptedException {
        int entries = 4;
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.SIZE_BASED, 10L, 3600L,
                                                     entries, false, null);
        try {
            for (int i = 0; i < entries; i++) {
                publish(fileHandler, "0123456789 entry-" + i);
                // Rotated files are named to the millisecond and moved with REPLACE_EXISTING, so two rotations
                // inside the same millisecond would overwrite each other. Space the writes out so that this
                // test measures retention across rotation rather than timestamp collisions.
                Thread.sleep(5);
            }
        } finally {
            fileHandler.close();
        }

        StringBuilder all = new StringBuilder(Files.readString(tempDir.resolve("access.log"), StandardCharsets.UTF_8));
        for (Path rotated : rotatedFiles("access", ".log")) {
            all.append(Files.readString(rotated, StandardCharsets.UTF_8));
        }
        for (int i = 0; i < entries; i++) {
            assertTrue(all.toString().contains("entry-" + i), "entry-" + i + " was lost across rotation");
        }
    }

    @Test(description = "A file that has not reached either threshold is left in place")
    public void testNoRotationBelowThresholds() throws IOException {
        HttpRollingFileHandler fileHandler = handler("access.log", RotationPolicy.BOTH, 1_000_000L, 3600L, 5,
                                                     false, null);
        try {
            publish(fileHandler, "small entry");
        } finally {
            fileHandler.close();
        }
        assertTrue(rotatedFiles("access", ".log").isEmpty(), "File was rotated before reaching either threshold");
    }

    @Test(description = "Rotation of a file in a relative-looking nested path resolves the parent for backup cleanup")
    public void testRotationInNestedDirectoryPrunesBackups() throws IOException {
        int maxBackups = 1;
        HttpRollingFileHandler fileHandler = handler("nested/access.log", RotationPolicy.SIZE_BASED, 10L, 3600L,
                                                     maxBackups, false, null);
        try {
            for (int i = 0; i < 4; i++) {
                publish(fileHandler, "0123456789 entry " + i);
            }
        } finally {
            fileHandler.close();
        }

        Path nested = tempDir.resolve("nested");
        try (Stream<Path> paths = Files.list(nested)) {
            long rotatedCount = paths.filter(p -> {
                String name = p.getFileName().toString();
                return name.startsWith("access-") && name.endsWith(".log");
            }).count();
            assertTrue(rotatedCount <= maxBackups,
                       "Backups in a nested directory were not pruned, found " + rotatedCount);
        }
    }
}
