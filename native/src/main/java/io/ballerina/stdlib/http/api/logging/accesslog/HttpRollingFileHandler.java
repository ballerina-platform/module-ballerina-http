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

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Comparator;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.locks.ReentrantLock;
import java.util.logging.ErrorManager;
import java.util.logging.Level;
import java.util.logging.LogRecord;
import java.util.logging.StreamHandler;

import static io.ballerina.stdlib.http.api.logging.util.RotationPolicy.BOTH;

/**
 * A custom rolling file handler for Ballerina HTTP access logs.
 * Extends java.util.logging.StreamHandler, which provides:
 *   - publish(), flush(), close() base implementations
 *   - Formatter integration
 *   - Encoding support
 */
public class HttpRollingFileHandler extends StreamHandler {

    private static final DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss");

    private final String filePath;
    private final RotationPolicy policy;
    private final long maxFileSize;           // bytes; 0 = unlimited
    private final long maxAgeSeconds;         // seconds; 0 = unlimited
    private final int maxBackupFiles;
    private final boolean append;

    /**
     * Single reentrant lock serializes all publish(), rotate(), and close()
     * operations. StreamHandler.publish() is not thread-safe on its own —
     * concurrent writings to the underlying OutputStream interleave and corrupt
     * log records. A simple lock is correct and sufficient here; a
     * ReadWriteLock would buy nothing since writes cannot proceed concurrently
     * on a single shared OutputStream.
     */
    private final ReentrantLock lock = new ReentrantLock();

    private volatile long fileOpenTime;
    private final AtomicLong currentFileSize = new AtomicLong(0);

    private FileChannel lockChannel;
    private FileLock fileLock;

    /**
     * Creates a new HttpRollingFileHandler with UTF-8 encoding.
     * Delegates to the encoding-aware constructor with null encoding (→ UTF-8).
     * No overridable method is called in this constructor body.
     */
    public HttpRollingFileHandler(String filePath,
                                  RotationPolicy policy,
                                  long maxFileSize,
                                  long maxAgeSeconds,
                                  int maxBackupFiles,
                                  boolean append) throws IOException {
        this(filePath, policy, maxFileSize, maxAgeSeconds, maxBackupFiles, append, null);
    }

    /**
     * Creates a new HttpRollingFileHandler with an explicit encoding.
     * Encoding is accepted as a plain parameter so no overridable
     * getEncoding() call is needed inside the constructor body —
     * suppresses SpotBugs MC_OVERRIDABLE_METHOD_CALL_IN_CONSTRUCTOR.
     *
     * @param encoding  charset name e.g. "UTF-8", "ISO-8859-1"; null → UTF-8
     */
    public HttpRollingFileHandler(String filePath,
                                  RotationPolicy policy,
                                  long maxFileSize,
                                  long maxAgeSeconds,
                                  int maxBackupFiles,
                                  boolean append,
                                  String encoding) throws IOException {
        super();

        this.filePath = filePath;
        this.policy = policy != null ? policy : BOTH;
        this.maxFileSize = maxFileSize;
        this.maxAgeSeconds = maxAgeSeconds;
        this.maxBackupFiles = maxBackupFiles;
        this.append = append;

        Charset charset = resolveEncoding(encoding);
        setEncoding(charset.name());

        setLevel(Level.ALL);
        openFile();
    }

    /**
     * Publishes a log record to the file.
     * Lock is acquired for the entire publish operation — rotation check,
     * rotate if needed, and write are all sequential under the same lock.
     * This prevents log record interleaving on the shared OutputStream
     * that StreamHandler writes to.
     */
    @Override
    public void publish(LogRecord record) {
        lock.lock();
        try {
            if (shouldRotate()) {
                rotate();
            }

            // Delegate actual formatting and writing to StreamHandler
            super.publish(record);
            flush();

            String formatted = getFormatter() != null ? getFormatter().format(record) : record.getMessage();
            // Update size counter after writing
            currentFileSize.addAndGet(formatted.getBytes(getEncoding()).length);
        } catch (IOException e) {
            reportError("Log rotation failed", e, ErrorManager.GENERIC_FAILURE);
        } finally {
            lock.unlock();
        }
    }

    /**
     * Closes the handler and releases all resources.
     */
    @Override
    public void close() {
        lock.lock();
        try {
            super.close();
            releaseFileLock();
        } finally {
            lock.unlock();
        }
    }

    private boolean shouldRotate() {
        return switch (policy) {
            case SIZE_BASED -> isSizeThresholdReached();
            case TIME_BASED -> isTimeThresholdReached();
            case BOTH -> isSizeThresholdReached() || isTimeThresholdReached();
        };
    }

    private boolean isSizeThresholdReached() {
        return maxFileSize > 0 && currentFileSize.get() >= maxFileSize;
    }

    private boolean isTimeThresholdReached() {
        if (maxAgeSeconds <= 0) {
            return false;
        }
        return (System.currentTimeMillis() - fileOpenTime) / 1000 >= maxAgeSeconds;
    }

    /**
     * Rotation sequence — must be called under lock:
     *   1. Flush and close current stream (via StreamHandler.close())
     *   2. Release file lock
     *   3. Rename the current file with timestamp suffix
     *   4. Delete the oldest backups beyond maxBackupFiles
     *   5. Open the new file and re-set the OutputStream on StreamHandler
     */
    private void rotate() throws IOException {
        // 1. Flush and close the current stream
        super.close();
        releaseFileLock();

        // 2. Rename it with timestamp
        String timestamp = LocalDateTime.now().format(TIMESTAMP_FORMAT);
        String baseName  = stripFileExtension(filePath);
        String extension = getFileExtension(filePath);
        String rotatedPath = baseName + "-" + timestamp + extension;

        File current = new File(filePath);
        if (current.exists()) {
            Files.move(current.toPath(), Paths.get(rotatedPath), StandardCopyOption.REPLACE_EXISTING);
        }

        // 3. Clean up old backups
        cleanOldBackups(baseName, extension);

        // 4. Open fresh file
        openFile();
    }

    /**
     * Opens the log file, acquires the file lock, and sets the OutputStream
     * on the parent StreamHandler. StreamHandler then wraps the stream with
     * an OutputStreamWriter using the configured encoding.
     */
    private void openFile() throws IOException {
        File file = new File(filePath);

        File parent = file.getParentFile();
        if (parent != null && !parent.exists()) {
            if (!parent.mkdirs()) {
                throw new IOException("Failed to create log directory: " + parent.getAbsolutePath());
            }
        }
        acquireFileLock();

        // Set the OutputStream on StreamHandler — it wraps this with an
        // OutputStreamWriter using the encoding set in the constructor
        FileOutputStream fos = new FileOutputStream(file, append);
        setOutputStream(fos);

        currentFileSize.set(file.length());
        fileOpenTime = System.currentTimeMillis();
    }

    private void acquireFileLock() throws IOException {
        File lockFile = new File(filePath + ".lck");
        FileOutputStream lockStream;
        try {
            lockStream = new FileOutputStream(lockFile);
        } catch (IOException e) {
            throw new IOException("Failed to open lock file: " + lockFile.getAbsolutePath(), e);
        }
        try {
            lockChannel = lockStream.getChannel();
            fileLock    = lockChannel.tryLock();
            if (fileLock == null) {
                lockChannel.close();
                lockChannel = null;
                throw new IOException("Log file locked by another process: " + filePath);
            }
        } catch (IOException e) {
            if (lockChannel != null) {
                try {
                    lockChannel.close();
                } catch (IOException ignored) { }
                lockChannel = null;
            }
            throw e;
        }
    }

    private void releaseFileLock() {
        try {
            if (fileLock != null) {
                fileLock.release();
                fileLock = null;
            }
            if (lockChannel != null) {
                lockChannel.close();
                lockChannel = null;
                File lockFile = new File(filePath + ".lck");
                if (lockFile.exists() && !lockFile.delete()) {
                    reportError("Failed to delete lock file: " + lockFile.getAbsolutePath(),
                            null, ErrorManager.CLOSE_FAILURE);
                }
            }
        } catch (IOException e) {
            reportError("Failed to release file lock", e, ErrorManager.CLOSE_FAILURE);
        }
    }

    private void cleanOldBackups(String baseName, String extension) {
        File dir = new File(filePath).getAbsoluteFile().getParentFile();
        if (dir == null) {
            dir = new File(".");
        }

        final String prefix = new File(baseName).getName() + "-";
        File[] backups = dir.listFiles(f -> f.isFile()
                                && f.getName().startsWith(prefix) && f.getName().endsWith(extension));
        if (backups == null || backups.length <= maxBackupFiles) {
            return;
        }

        Arrays.sort(backups, Comparator.comparingLong(File::lastModified));
        int toDelete = backups.length - maxBackupFiles;
        for (int i = 0; i < toDelete; i++) {
            if (!backups[i].delete()) {
                reportError("Failed to delete old backup: " + backups[i].getAbsolutePath(),
                        null, ErrorManager.GENERIC_FAILURE);
            }
        }
    }

    private static Charset resolveEncoding(String enc) {
        if (enc != null && !enc.isEmpty()) {
            return Charset.forName(enc);
        }
        return StandardCharsets.UTF_8;
    }

    private static String stripFileExtension(String path) {
        int dotIndex = path.lastIndexOf('.');
        return dotIndex != -1 ? path.substring(0, dotIndex) : path;
    }

    private static String getFileExtension(String path) {
        int dotIndex = path.lastIndexOf('.');
        return dotIndex != -1 ? path.substring(dotIndex) : ".log";
    }
}
