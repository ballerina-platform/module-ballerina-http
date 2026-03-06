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

import io.ballerina.stdlib.http.api.logging.util.CountingOutputStream;
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
 *
 * @since 2.16.0
 */
public class HttpRollingFileHandler extends StreamHandler {

    private static final DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmssSSS");
    private final String filePath;
    private final RotationPolicy policy;
    private final long maxFileSize; // bytes;
    private final long maxAgeSeconds;
    private final int maxBackupFiles;
    private final ReentrantLock lock = new ReentrantLock();
    private volatile long fileOpenTime;
    private FileChannel lockChannel;
    private FileLock fileLock;
    private CountingOutputStream countingStream;

    /**
     * Creates a new HttpRollingFileHandler with an explicit encoding.
     *
     * @param filePath       the log file path
     * @param policy         rotation policy (SIZE_BASED, TIME_BASED, or BOTH)
     * @param maxFileSize    max file size in bytes for rotation
     * @param maxAgeSeconds  max age in seconds for rotation
     * @param maxBackupFiles max number of backup files to keep (0 to keep none)
     * @param append         whether to append to an existing file or overwrite
     * @param encoding       character encoding for the log file (defaults to UTF-8 if null or empty)
     */
    public HttpRollingFileHandler(String filePath, RotationPolicy policy, long maxFileSize, long maxAgeSeconds,
                                  int maxBackupFiles, boolean append, String encoding) throws IOException {
        super();
        this.filePath = filePath;
        this.policy = policy != null ? policy : BOTH;
        this.maxFileSize = maxFileSize;
        this.maxAgeSeconds = maxAgeSeconds;
        this.maxBackupFiles = maxBackupFiles;

        Charset charset = resolveEncoding(encoding);
        setEncoding(charset.name());
        setLevel(Level.ALL);
        openFile(append);
    }

    /**
     * Publishes a log record to the file.
     * Checks if rotation is needed before writing, and updates the current file size after writing.
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

    /**
     * Performs rotation of the log file.
     */
    private void rotate() throws IOException {
        // 1. Flush and close the current stream
        flush();
        countingStream.close();
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
        openFile(false);
    }

    /**
     * Opens the log file, acquires the file lock, and sets the OutputStream
     * on the parent StreamHandler.
     */
    private void openFile(boolean append) throws IOException {
        File file = new File(filePath);

        File parent = file.getParentFile();
        if (parent != null && !parent.exists()) {
            if (!parent.mkdirs()) {
                throw new IOException("Failed to create log directory: " + parent.getAbsolutePath());
            }
        }
        acquireFileLock();
        try {
            FileOutputStream fos = new FileOutputStream(file, append); // scoped inside try
            countingStream = new CountingOutputStream(fos, append ? file.length() : 0);
            setOutputStream(countingStream);
            fileOpenTime = System.currentTimeMillis();
        } catch (IOException e) {
            if (countingStream != null) {
                try {
                    countingStream.close();
                } catch (IOException ignored) { }
            }
            releaseFileLock();
            throw e;
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
        return countingStream != null && countingStream.getByteCount() >= maxFileSize;
    }

    private boolean isTimeThresholdReached() {
        return (System.currentTimeMillis() - fileOpenTime) / 1000 >= maxAgeSeconds;
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
            }
        } catch (IOException e) {
            reportError("Failed to release file lock", e, ErrorManager.CLOSE_FAILURE);
        }
    }

    private void cleanOldBackups(String baseName, String extension) {
        File dir = new File(filePath).getAbsoluteFile().getParentFile();
        if (dir == null) {
            return;
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
        File file = new File(path);
        String name = file.getName();
        int dotIndex = name.lastIndexOf('.');
        if (dotIndex <= 0) {  // no extension or hidden file like ".access"
            return path;
        }
        String parent = file.getParent();
        return (parent != null ? parent + File.separator : "") + name.substring(0, dotIndex);
    }

    private static String getFileExtension(String path) {
        String name = new File(path).getName();
        int dotIndex = name.lastIndexOf('.');
        return dotIndex > 0 ? name.substring(dotIndex) : "";
    }
}
