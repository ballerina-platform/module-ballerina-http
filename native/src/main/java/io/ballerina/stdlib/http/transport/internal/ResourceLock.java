package io.ballerina.stdlib.http.transport.internal;

import java.io.Serial;
import java.util.concurrent.locks.ReentrantLock;

/**
 * A lock that can be used with try-with-resources.
 */
public final class ResourceLock extends ReentrantLock implements AutoCloseable {
    @Serial
    private static final long serialVersionUID = 1L;

    public ResourceLock obtain() {
        lock();  // acquire the lock
        return this;  // return the lock instance
    }

    @Override
    public void close() {
        this.unlock();  // release the lock
    }
}
