package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

/**
 * Interface for HTTP Service classes.
 */
public interface HttpService {
    BMap<BString, Object> getCompressionConfig();

    String getChunkingConfig();

    String getMediaTypeSubtypePrefix();
}
