/*
 * Copyright (c) 2016, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api;

import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.runtime.api.constants.RuntimeConstants.BALLERINA_BUILTIN_PKG_PREFIX;
import static io.ballerina.runtime.api.constants.RuntimeConstants.ORG_NAME_SEPARATOR;

/**
 * Constants for HTTP.
 *
 * @since 0.8.0
 */
public class HttpConstants {

    public static final String HTTPS_ENDPOINT_STARTED = "[ballerina/http] started HTTPS/WSS listener ";
    public static final String HTTP_ENDPOINT_STARTED = "[ballerina/http] started HTTP/WS listener ";
    public static final String HTTPS_ENDPOINT_STOPPED = "[ballerina/http] stopped HTTPS/WSS listener ";
    public static final String HTTP_ENDPOINT_STOPPED = "[ballerina/http] stopped HTTP/WS listener ";
    public static final String HTTP_RUNTIME_WARNING_PREFIX = "warning: [ballerina/http] ";
    public static final String HTTPS_RECOMMENDATION_ERROR = "HTTPS is recommended but using HTTP";
    public static final String DEPRECATED_PROXY_CONFIG_WARNING = "Usage of proxy setting inside http1Settings is " +
                                                                 "deprecated";

    public static final String BASE_PATH = "BASE_PATH";
    public static final String SUB_PATH = "SUB_PATH";
    public static final String EXTRA_PATH_INFO = "EXTRA_PATH_INFO";
    public static final Integer EXTRA_PATH_INDEX = 0;
    public static final String RAW_URI = "RAW_URI";
    public static final String RESOURCE_ARGS = "RESOURCE_ARGS";
    public static final String MATRIX_PARAMS = "MATRIX_PARAMS";
    public static final String QUERY_STR = "QUERY_STR";
    public static final String RAW_QUERY_STR = "RAW_QUERY_STR";

    public static final String DEFAULT_INTERFACE = "0.0.0.0:8080";
    public static final String DEFAULT_BASE_PATH = "/";
    public static final String DEFAULT_SUB_PATH = "/*";

    public static final String PROTOCOL_HTTP = "http";
    public static final String HTTP_MOCK_SERVER_ENDPOINT_NAME = "Tballerina/http:MockListener;";
    public static final String PROTOCOL_HTTPS = "https";
    public static final String RESOLVED_REQUESTED_URI = "RESOLVED_REQUESTED_URI";
    public static final String HTTP_REASON_PHRASE = "HTTP_REASON_PHRASE";
    public static final String TEXT_PLAIN = "text/plain";
    public static final String APPLICATION_JSON = "application/json";
    public static final String APPLICATION_XML = "application/xml";
    public static final String APPLICATION_OCTET_STREAM = "application/octet-stream";
    public static final String PROTOCOL = "PROTOCOL";
    public static final String TO = "TO";
    public static final String LOCAL_ADDRESS = "LOCAL_ADDRESS";
    public static final String HTTP_VERSION = "HTTP_VERSION";
    public static final String MUTUAL_SSL_RESULT = "MUTUAL_SSL_HANDSHAKE_RESULT";
    public static final String LISTENER_PORT = "LISTENER_PORT";
    public static final String HTTP_DEFAULT_HOST = "0.0.0.0";
    public static final String TLS_STORE_TYPE = "tlsStoreType";
    public static final String PKCS_STORE_TYPE = "PKCS12";
    public static final String AUTO = "AUTO";
    public static final String ALWAYS = "ALWAYS";
    public static final String NEVER = "NEVER";
    public static final String FORWARDED_ENABLE = "enable";
    public static final String FORWARDED_TRANSITION = "transition";
    public static final String FORWARDED_DISABLE = "disable";
    public static final String DISABLE = "disable";
    public static final String DEFAULT_HOST = "b7a.default";

    public static final String HTTP_PACKAGE_PATH = "ballerina" + ORG_NAME_SEPARATOR + "http";

    public static final BString HTTP_REQUEST_METHOD = StringUtils.fromString("method");
    public static final String HTTP_METHOD_GET = "GET";
    public static final String HTTP_METHOD_POST = "POST";
    public static final String HTTP_METHOD_PUT = "PUT";
    public static final String HTTP_METHOD_PATCH = "PATCH";
    public static final String HTTP_METHOD_DELETE = "DELETE";
    public static final String HTTP_METHOD_OPTIONS = "OPTIONS";
    public static final String HTTP_METHOD_HEAD = "HEAD";
    public static final String DEFAULT_HTTP_METHOD = "default";

    /* Annotations */
    public static final String ANN_NAME_RESOURCE_CONFIG = "ResourceConfig";
    public static final String ANN_RESOURCE_ATTR_METHODS = "methods";
    public static final String ANN_RESOURCE_ATTR_PATH = "path";
    public static final String ANN_RESOURCE_ATTR_BODY = "body";
    public static final String ANN_RESOURCE_ATTR_CONSUMES = "consumes";
    public static final String ANN_RESOURCE_ATTR_PRODUCES = "produces";
    public static final String ANN_NAME_CONFIG = "configuration";
    public static final String ANN_NAME_HTTP_SERVICE_CONFIG = "ServiceConfig";
    public static final String ANN_CONFIG_ATTR_HOST = "host";
    public static final String ANN_CONFIG_ATTR_PORT = "port";
    public static final String ANN_CONFIG_ATTR_HTTP_VERSION = "httpVersion";
    public static final String ANN_CONFIG_ATTR_HTTPS_PORT = "httpsPort";
    public static final String ANN_CONFIG_ATTR_KEEP_ALIVE = "keepAlive";
    public static final String ANN_CONFIG_ATTR_BASE_PATH = "basePath";
    public static final String ANN_CONFIG_ATTR_SCHEME = "scheme";
    public static final String ANN_CONFIG_ATTR_TLS_STORE_TYPE = "tlsStoreType";
    public static final String ANN_CONFIG_ATTR_KEY_STORE_FILE = "keyStoreFile";
    public static final String ANN_CONFIG_ATTR_KEY_STORE_PASS = "keyStorePassword";
    public static final String ANN_CONFIG_ATTR_TRUST_STORE_FILE = "trustStoreFile";
    public static final String ANN_CONFIG_ATTR_TRUST_STORE_PASS = "trustStorePassword";
    public static final String ANN_CONFIG_ATTR_CERT_PASS = "certPassword";
    public static final String ANN_CONFIG_ATTR_SSL_VERIFY_CLIENT = "sslVerifyClient";
    public static final String ANN_CONFIG_ATTR_SSL_ENABLED_PROTOCOLS = "sslEnabledProtocols";
    public static final String ANN_CONFIG_ATTR_CIPHERS = "ciphers";
    public static final String ANN_CONFIG_ATTR_SSL_PROTOCOL = "sslProtocol";
    public static final String ANN_CONFIG_ATTR_VALIDATE_CERT_ENABLED = "validateCertEnabled";
    public static final BString ANN_CONFIG_ATTR_COMPRESSION = StringUtils.fromString("compression");
    public static final BString ANN_CONFIG_ATTR_COMPRESSION_ENABLE = StringUtils.fromString("enable");
    public static final BString ANN_CONFIG_ATTR_COMPRESSION_CONTENT_TYPES = StringUtils.fromString("contentTypes");
    public static final String ANN_CONFIG_ATTR_CACHE_SIZE = "cacheSize";
    public static final String ANN_CONFIG_ATTR_CACHE_VALIDITY_PERIOD = "cacheValidityPeriod";
    public static final String ANN_CONFIG_ATTR_WEBSOCKET = "webSocket";
    public static final String ANN_CONFIG_ATTR_MAXIMUM_URL_LENGTH = "maxUriLength";
    public static final String ANN_CONFIG_ATTR_MAXIMUM_HEADER_SIZE = "maxHeaderSize";
    public static final String ANN_CONFIG_ATTR_MAXIMUM_ENTITY_BODY_SIZE = "maxEntityBodySize";
    public static final BString ANN_CONFIG_ATTR_CHUNKING = StringUtils.fromString("chunking");
    public static final BString ANN_CONFIG_ATTR_PATTERN = StringUtils.fromString("pattern");
    public static final BString ANN_CONFIG_ATTR_ALLOW_NO_VERSION = StringUtils.fromString("allowNoVersion");
    public static final BString ANN_CONFIG_ATTR_MATCH_MAJOR_VERSION = StringUtils.fromString("matchMajorVersion");
    public static final String CONFIG_ATTR_WEBSOCKET_UPGRADE = "webSocketUpgrade";
    public static final BString ANN_CONFIG_ATTR_WEBSOCKET_UPGRADE = StringUtils.fromString(
            CONFIG_ATTR_WEBSOCKET_UPGRADE);
    public static final BString ANN_WEBSOCKET_ATTR_UPGRADE_PATH = StringUtils.fromString("upgradePath");
    public static final String ANNOTATION_METHOD_GET = HTTP_METHOD_GET;
    public static final String ANNOTATION_METHOD_POST = HTTP_METHOD_POST;
    public static final String ANNOTATION_METHOD_PUT = HTTP_METHOD_PUT;
    public static final String ANNOTATION_METHOD_PATCH = HTTP_METHOD_PATCH;
    public static final String ANNOTATION_METHOD_DELETE = HTTP_METHOD_DELETE;
    public static final String ANNOTATION_METHOD_OPTIONS = HTTP_METHOD_OPTIONS;
    public static final String ANN_NAME_HTTP_INTROSPECTION_DOC_CONFIG = "IntrospectionDocConfig";
    public static final BString ANN_FIELD_DOC_NAME = StringUtils.fromString("name");
    public static final String ANN_NAME_PARAM_ORDER_CONFIG = "ParamOrderConfig";
    public static final BString ANN_FIELD_PATH_PARAM_ORDER = StringUtils.fromString("pathParamOrder");
    public static final BString ANN_FIELD_ALL_PARAM_ORDER = StringUtils.fromString("allParamOrder");
    public static final String ANN_NAME_PAYLOAD = "Payload";
    public static final String ANN_NAME_HEADER = "Header";
    public static final String ANN_NAME_CALLER_INFO = "CallerInfo";
    public static final String DIRTY_RESPONSE = "dirtyResponse";
    public static final BString ANN_FIELD_MEDIA_TYPE = StringUtils.fromString("mediaType");
    public static final BString ANN_FIELD_RESPOND_TYPE = StringUtils.fromString("respondType");
    public static final BString ANN_FIELD_NAME = StringUtils.fromString("name");
    public static final String ANN_NAME_CACHE = "Cache";

    public static final String VALUE_ATTRIBUTE = "value";

    public static final String COOKIE_HEADER = "Cookie";
    public static final String SESSION_ID = "BSESSIONID=";
    public static final String PATH = "Path=";
    public static final String RESPONSE_COOKIE_HEADER = "Set-Cookie";
    public static final String SESSION = "Session";
    public static final String HTTP_ONLY = "HttpOnly";
    public static final String SECURE = "Secure";

    public static final String ALLOW_ORIGIN = "allowOrigins";
    public static final String ALLOW_CREDENTIALS = "allowCredentials";
    public static final String ALLOW_METHODS = "allowMethods";
    public static final String MAX_AGE = "maxAge";
    public static final String ALLOW_HEADERS = "allowHeaders";
    public static final String EXPOSE_HEADERS = "exposeHeaders";
    public static final String PREFLIGHT_RESOURCES = "PREFLIGHT_RESOURCES";
    public static final String RESOURCES_CORS = "RESOURCES_CORS";
    public static final String LISTENER_INTERFACE_ID = "listener.interface.id";
    public static final String PACKAGE_BALLERINA_BUILTIN = "ballerina/builtin";

    public static final String CLIENT = "Client";
    public static final String HTTP_CLIENT = "HttpClient";
    public static final String CLIENT_CONFIG_HASH_CODE = "ClientConfigHashCode";

    public static final String MAIN_STRAND = "MAIN_STRAND";
    public static final String SRC_HANDLER = "SRC_HANDLER";
    public static final String REMOTE_ADDRESS = "REMOTE_ADDRESS";
    public static final String ORIGIN_HOST = "ORIGIN_HOST";
    public static final String POOLED_BYTE_BUFFER_FACTORY = "POOLED_BYTE_BUFFER_FACTORY";
    public static final String HTTP_SERVICE = "HTTP_SERVICE";
    public static final String VERSION = "{version}";
    public static final String DEFAULT_VERSION = "v.{major}.{minor}";
    public static final String MAJOR_VERSION = "{major}";
    public static final String MINOR_VERSION = "{minor}";
    public static final String STAR_IDENTIFIER = "*";
    public static final String PATH_PARAM_IDENTIFIER = "^";
    public static final String PATH_REST_PARAM_IDENTIFIER = "^^";
    public static final String OPEN_CURL_IDENTIFIER = "{";
    public static final String CLOSE_CURL_IDENTIFIER = "}";
    public static final String DOT_IDENTIFIER = ".";
    public static final String QUERY_PARAM = "query";
    public static final String PAYLOAD_PARAM = "payload";
    public static final String HEADER_PARAM = "header";

    /* Annotations */
    public static final String ANNOTATION_NAME_SOURCE = "Source";
    public static final String ANNOTATION_NAME_BASE_PATH = "BasePath";
    public static final String ANNOTATION_NAME_PATH = "Path";
    public static final String HTTP_CLIENT_EXCEPTION_CATEGORY = "http-client";
    public static final String SERVICE_ENDPOINT = "Listener";
    public static final String INBOUND_MESSAGE = "INBOUND_MESSAGE";
    public static final String CALLER = "Caller";
    public static final String REMOTE = "Remote";
    public static final String LOCAL = "Local";
    public static final String REQUEST = "Request";
    public static final String RESPONSE = "Response";
    public static final String HEADERS = "Headers";
    public static final String HTTP_FUTURE = "HttpFuture";
    public static final String PUSH_PROMISE = "PushPromise";
    public static final String ENTITY = "Entity";
    public static final String RESPONSE_CACHE_CONTROL = "ResponseCacheControl";
    public static final String REQUEST_CACHE_CONTROL = "RequestCacheControl";
    public static final String STRUCT_GENERIC_ERROR = "error";
    public static final String ERROR_DETAIL_RECORD = "ErrorDetail";
    public static final BString ERROR_DETAIL_BODY = StringUtils.fromString("body");
    public static final String TYPE_STRING = "string";
    public static final String TRANSPORT_MESSAGE = "transport_message";
    public static final String QUERY_PARAM_MAP = "queryParamMap";
    public static final String TRANSPORT_HANDLE = "transport_handle";
    public static final String TRANSPORT_PUSH_PROMISE = "transport_push_promise";
    public static final String MESSAGE_OUTPUT_STREAM = "message_output_stream";
    public static final String HTTP_SESSION = "http_session";
    public static final String MUTUAL_SSL_HANDSHAKE_RECORD = "MutualSslHandshake";

    public static final int NO_CONTENT_LENGTH_FOUND = -1;
    public static final short ONE_BYTE = 1;
    public static final String HTTP_HEADERS = "http_headers";
    public static final String SET_HOST_HEADER = "set_host_header";
    public static final String HTTP_TRAILER_HEADERS = "http_trailer_headers";
    public static final String LEADING_HEADER = "leading";
    public static final BString HEADER_REQUEST_FIELD = StringUtils.fromString("request");
    public static final String HEADER_VALUE_RECORD = "HeaderValue";
    public static final BString HEADER_VALUE_FIELD = StringUtils.fromString("value");
    public static final BString HEADER_VALUE_PARAM_FIELD = StringUtils.fromString("params");

    public static final String HTTP_TRANSPORT_CONF = "transports.netty.conf";
    public static final String CIPHERS = "ciphers";
    public static final String SSL_ENABLED_PROTOCOLS = "sslEnabledProtocols";
    public static final int OPTIONS_STRUCT_INDEX = 0;

    public static final int HTTP_MESSAGE_INDEX = 0;
    public static final int ENTITY_INDEX = 1;

    public static final String HTTP_ERROR_CODE = "{ballerina/http}HTTPError";
    public static final String HTTP_ERROR_RECORD = "HTTPError";
    public static final BString HTTP_ERROR_MESSAGE = StringUtils.fromString("message");
    public static final BString HTTP_ERROR_STATUS_CODE = StringUtils.fromString("statusCode");
    public static final String HTTP_CLIENT_REQUEST_ERROR = "ClientRequestError";
    public static final String HTTP_REMOTE_SERVER_ERROR = "RemoteServerError";

    // ServeConnector struct indices
    public static final BString HTTP_CONNECTOR_CONFIG_FIELD = StringUtils.fromString("config");
    public static final BString SERVICE_ENDPOINT_CONFIG_FIELD = StringUtils.fromString("config");
    public static final BString RESOURCE_ACCESSOR = StringUtils.fromString("resourceAccessor");
    public static final String SERVICE_ENDPOINT_CONNECTION_FIELD = "caller";

    //Connection struct indexes
    public static final int CONNECTION_HOST_INDEX = 0;
    public static final int CONNECTION_PORT_INDEX = 0;

    //Request struct field names
    public static final BString REQUEST_RAW_PATH_FIELD = StringUtils.fromString("rawPath");
    public static final BString REQUEST_METHOD_FIELD = StringUtils.fromString("method");
    public static final BString REQUEST_VERSION_FIELD = StringUtils.fromString("httpVersion");
    public static final BString REQUEST_USER_AGENT_FIELD = StringUtils.fromString("userAgent");
    public static final BString REQUEST_EXTRA_PATH_INFO_FIELD = StringUtils.fromString("extraPathInfo");
    public static final BString REQUEST_CACHE_CONTROL_FIELD = StringUtils.fromString("cacheControl");
    public static final BString REQUEST_REUSE_STATUS_FIELD = StringUtils.fromString("dirtyRequest");
    public static final BString REQUEST_NO_ENTITY_BODY_FIELD = StringUtils.fromString("noEntityBody");
    public static final BString REQUEST_MUTUAL_SSL_HANDSHAKE_FIELD = StringUtils.fromString("mutualSslHandshake");
    public static final BString REQUEST_MUTUAL_SSL_HANDSHAKE_STATUS = StringUtils.fromString("status");
    public static final BString MUTUAL_SSL_CERTIFICATE = StringUtils.fromString("base64EncodedCert");
    public static final String BASE_64_ENCODED_CERT = "BASE_64_ENCODED_CERT";

    //Response struct field names
    public static final BString RESPONSE_STATUS_CODE_FIELD = StringUtils.fromString("statusCode");
    public static final BString RESPONSE_REASON_PHRASE_FIELD = StringUtils.fromString("reasonPhrase");
    public static final BString RESPONSE_SERVER_FIELD = StringUtils.fromString("server");
    public static final BString RESOLVED_REQUESTED_URI_FIELD = StringUtils.fromString("resolvedRequestedURI");
    public static final BString RESPONSE_CACHE_CONTROL_FIELD = StringUtils.fromString("cacheControl");
    public static final String IN_RESPONSE_RECEIVED_TIME_FIELD = "receivedTime";

    //StatusCodeResponse struct field names
    public static final String STATUS_CODE_RESPONSE_BODY_FIELD = "body";
    public static final String STATUS_CODE_RESPONSE_STATUS_FIELD = "status";

    //PushPromise struct field names
    public static final BString PUSH_PROMISE_PATH_FIELD = StringUtils.fromString("path");
    public static final BString PUSH_PROMISE_METHOD_FIELD = StringUtils.fromString("method");

    //Proxy server struct field names
    public static final int PROXY_STRUCT_INDEX = 3;
    public static final String PROXY_HOST_INDEX = "host";
    public static final String PROXY_PORT_INDEX = "port";
    public static final String PROXY_USER_NAME_INDEX = "userName";
    public static final String PROXY_PASSWORD_INDEX = "password";

    //Connection Throttling struct field names
    public static final int CONNECTION_THROTTLING_STRUCT_INDEX = 4;
    public static final String CONNECTION_THROTTLING_MAX_ACTIVE_CONNECTIONS_INDEX = "maxActiveConnections";
    public static final String CONNECTION_THROTTLING_WAIT_TIME_INDEX = "waitTime";

    //Retry Struct field names
    public static final int RETRY_STRUCT_FIELD = 4;
    public static final String RETRY_COUNT_FIELD = "count";
    public static final String RETRY_INTERVAL_FIELD = "intervalInMillis";

    // Logging related runtime parameter names
    public static final String HTTP_TRACE_LOG = "http.tracelog";
    public static final String HTTP_TRACE_LOG_ENABLED = "http.tracelog.enabled";
    public static final String HTTP_ACCESS_LOG = "http.accesslog";
    public static final String HTTP_ACCESS_LOG_ENABLED = "http.accesslog.enabled";

    // TraceLog and AccessLog configs
    public static final BString HTTP_LOG_CONSOLE = StringUtils.fromString("console");
    public static final BString HTTP_LOG_FILE_PATH = StringUtils.fromString("path");
    public static final BString HTTP_TRACE_LOG_HOST = StringUtils.fromString("host");
    public static final BString HTTP_TRACE_LOG_PORT = StringUtils.fromString("port");
    public static final BString HTTP_LOGGING_PROTOCOL = StringUtils.fromString("HTTP");

    // ResponseCacheControl struct field names
    public static final BString RES_CACHE_CONTROL_MUST_REVALIDATE_FIELD = StringUtils.fromString("mustRevalidate");
    public static final BString RES_CACHE_CONTROL_NO_CACHE_FIELD = StringUtils.fromString("noCache");
    public static final BString RES_CACHE_CONTROL_NO_STORE_FIELD = StringUtils.fromString("noStore");
    public static final BString RES_CACHE_CONTROL_NO_TRANSFORM_FIELD = StringUtils.fromString("noTransform");
    public static final BString RES_CACHE_CONTROL_IS_PRIVATE_FIELD = StringUtils.fromString("isPrivate");
    public static final BString RES_CACHE_CONTROL_PROXY_REVALIDATE_FIELD = StringUtils.fromString("proxyRevalidate");
    public static final BString RES_CACHE_CONTROL_MAX_AGE_FIELD = StringUtils.fromString("maxAge");
    public static final BString RES_CACHE_CONTROL_S_MAXAGE_FIELD = StringUtils.fromString("sMaxAge");
    public static final BString RES_CACHE_CONTROL_NO_CACHE_FIELDS_FIELD = StringUtils.fromString("noCacheFields");
    public static final BString RES_CACHE_CONTROL_PRIVATE_FIELDS_FIELD = StringUtils.fromString("privateFields");

    // RequestCacheControl struct field names
    public static final BString REQ_CACHE_CONTROL_NO_CACHE_FIELD = StringUtils.fromString("noCache");
    public static final BString REQ_CACHE_CONTROL_NO_STORE_FIELD = StringUtils.fromString("noStore");
    public static final BString REQ_CACHE_CONTROL_NO_TRANSFORM_FIELD = StringUtils.fromString("noTransform");
    public static final BString REQ_CACHE_CONTROL_ONLY_IF_CACHED_FIELD = StringUtils.fromString("onlyIfCached");
    public static final BString REQ_CACHE_CONTROL_MAX_AGE_FIELD = StringUtils.fromString("maxAge");
    public static final BString REQ_CACHE_CONTROL_MAX_STALE_FIELD = StringUtils.fromString("maxStale");
    public static final BString REQ_CACHE_CONTROL_MIN_FRESH_FIELD = StringUtils.fromString("minFresh");

    public static final String CONNECTION_HEADER = "Connection";
    public static final String HEADER_VAL_CONNECTION_CLOSE = "Close";
    public static final String HEADER_VAL_CONNECTION_KEEP_ALIVE = "Keep-Alive";
    public static final String LINK_HEADER = "link";

    //Response codes
    public static final int INVALID_STATUS_CODE = 000;
    public static final int STATUS_CODE_100_CONTINUE = 100;
    public static final String HTTP_BAD_REQUEST = "400";
    public static final String HEADER_X_XID = "x-b7a-xid";
    public static final String HEADER_X_REGISTER_AT_URL = "x-b7a-register-at";
    public static final String HEADER_X_INFO_RECORD = "x-b7a-info-record";


    public static final String HTTP_SERVER_CONNECTOR = "HTTP_SERVER_CONNECTOR";
    public static final String HTTP_SERVICE_REGISTRY = "HTTP_SERVICE_REGISTRY";
    public static final String CONNECTOR_STARTED = "CONNECTOR_STARTED";
    public static final String ABSOLUTE_RESOURCE_PATH = "ABSOLUTE_RESOURCE_PATH";

    //HTTP Interceptor
    public static final BString ANN_INTERCEPTORS = StringUtils.fromString("interceptors");
    public static final String INTERCEPTORS = "INTERCEPTORS";
    public static final String INTERCEPTOR_SERVICES_REGISTRIES = "INTERCEPTOR_SERVICES_REGISTRIES";
    public static final String REQUEST_CONTEXT_NEXT = "REQUEST_CONTEXT_NEXT";
    public static final String REQUEST_CONTEXT = "RequestContext";
    public static final String ENTITY_OBJ = "EntityObj";
    public static final String INTERCEPTOR_SERVICE = "INTERCEPTOR_SERVICE";
    public static final String INTERCEPTOR_SERVICE_TYPE = "INTERCEPTOR_SERVICE_TYPE";
    public static final String REQUEST_INTERCEPTOR_INDEX = "REQUEST_INTERCEPTOR_INDEX";
    public static final String RESPONSE_INTERCEPTOR_INDEX = "RESPONSE_INTERCEPTOR_INDEX";
    public static final String INTERCEPTOR_SERVICE_ERROR = "INTERCEPTOR_SERVICE_ERROR";
    public static final String WAIT_FOR_FULL_REQUEST = "WAIT_FOR_FULL_REQUEST";
    public static final String HTTP_NORMAL = "Normal";
    public static final String REQUEST_INTERCEPTOR = "RequestInterceptor";
    public static final String RESPONSE_INTERCEPTOR = "ResponseInterceptor";
    public static final String REQUEST_ERROR_INTERCEPTOR = "RequestErrorInterceptor";
    public static final String RESPONSE_ERROR_INTERCEPTOR = "ResponseErrorInterceptor";
    public static final String TARGET_SERVICE = "TARGET_SERVICE";
    public static final String INTERCEPT_RESPONSE = "interceptResponse";
    public static final String INTERCEPT_RESPONSE_ERROR = "interceptResponseError";
    public static final String AUTHORIZATION_HEADER = "authorization";
    public static final String BEARER_AUTHORIZATION_HEADER = "Bearer ";
    public static final BString JWT_INFORMATION = StringUtils.fromString("JWT_INFORMATION");
    public static final String JWT_DECODER_CLASS_NAME = "JwtDecoder";
    public static final String JWT_DECODE_METHOD_NAME = "decodeJwt";

    //Service Endpoint
    public static final int SERVICE_ENDPOINT_NAME_INDEX = 0;
    public static final String SERVICE_ENDPOINT_CONFIG = "config";
    public static final BString SERVER_NAME = StringUtils.fromString("server");
    public static final String LISTENER_CONFIGURATION = "ListenerConfiguration";

    //Service Endpoint Config
    public static final BString ENDPOINT_CONFIG_HOST = StringUtils.fromString("host");
    public static final BString ENDPOINT_CONFIG_PORT = StringUtils.fromString("port");
    public static final BString ENDPOINT_CONFIG_INTERCEPTORS = StringUtils.fromString("interceptors");
    public static final BString ENDPOINT_CONFIG_KEEP_ALIVE = StringUtils.fromString("keepAlive");
    public static final BString ENDPOINT_CONFIG_TIMEOUT = StringUtils.fromString("timeout");
    public static final String ENDPOINT_CONFIG_CHUNKING = "chunking";
    public static final BString ENDPOINT_CONFIG_VERSION = StringUtils.fromString("httpVersion");
    public static final String ENDPOINT_REQUEST_LIMITS = "requestLimits";
    public static final BString ENDPOINT_CONFIG_GRACEFUL_STOP_TIMEOUT = StringUtils.fromString("gracefulStopTimeout");

    public static final BString MAX_URI_LENGTH = StringUtils.fromString("maxUriLength");
    public static final BString MAX_STATUS_LINE_LENGTH = StringUtils.fromString("maxStatusLineLength");
    public static final BString MAX_HEADER_SIZE = StringUtils.fromString("maxHeaderSize");
    public static final BString MAX_ENTITY_BODY_SIZE = StringUtils.fromString("maxEntityBodySize");

    public static final String ENDPOINT_CONFIG_PIPELINING = "pipelining";
    public static final String ENABLE_PIPELINING = "enable";
    public static final BString PIPELINING_REQUEST_LIMIT = StringUtils.fromString("maxPipelinedRequests");

    public static final BString ENDPOINT_CONFIG_SECURESOCKET = StringUtils.fromString("secureSocket");
    public static final BString SECURESOCKET_CONFIG_DISABLE_SSL = StringUtils.fromString("enable");
    public static final BString SECURESOCKET_CONFIG_CERT = StringUtils.fromString("cert");
    public static final BString SECURESOCKET_CONFIG_TRUSTSTORE_FILE_PATH = StringUtils.fromString("path");
    public static final BString SECURESOCKET_CONFIG_TRUSTSTORE_PASSWORD = StringUtils.fromString("password");
    public static final BString SECURESOCKET_CONFIG_KEY = StringUtils.fromString("key");
    public static final BString SECURESOCKET_CONFIG_CERTKEY_CERT_FILE = StringUtils.fromString("certFile");
    public static final BString SECURESOCKET_CONFIG_CERTKEY_KEY_FILE = StringUtils.fromString("keyFile");
    public static final BString SECURESOCKET_CONFIG_CERTKEY_KEY_PASSWORD = StringUtils.fromString("keyPassword");
    public static final BString SECURESOCKET_CONFIG_KEYSTORE_FILE_PATH = StringUtils.fromString("path");
    public static final BString SECURESOCKET_CONFIG_KEYSTORE_PASSWORD = StringUtils.fromString("password");
    public static final BString SECURESOCKET_CONFIG_PROTOCOL = StringUtils.fromString("protocol");
    public static final BString SECURESOCKET_CONFIG_PROTOCOL_NAME = StringUtils.fromString("name");
    public static final BString SECURESOCKET_CONFIG_PROTOCOL_VERSIONS = StringUtils.fromString("versions");
    public static final BString SECURESOCKET_CONFIG_CERT_VALIDATION = StringUtils.fromString("certValidation");
    public static final BString SECURESOCKET_CONFIG_CERT_VALIDATION_TYPE = StringUtils.fromString("cacheSize");
    public static final BString SECURESOCKET_CONFIG_CERT_VALIDATION_CACHE_SIZE = StringUtils.fromString("cacheSize");
    public static final BString SECURESOCKET_CONFIG_CERT_VALIDATION_CACHE_VALIDITY_PERIOD =
            StringUtils.fromString("cacheValidityPeriod");
    public static final BString SECURESOCKET_CONFIG_CIPHERS = StringUtils.fromString("ciphers");
    public static final BString SECURESOCKET_CONFIG_HOST_NAME_VERIFICATION_ENABLED =
            StringUtils.fromString("verifyHostName");
    public static final BString SECURESOCKET_CONFIG_SHARE_SESSION = StringUtils.fromString("shareSession");
    public static final BString SECURESOCKET_CONFIG_HANDSHAKE_TIMEOUT = StringUtils.fromString("handshakeTimeout");
    public static final BString SECURESOCKET_CONFIG_SESSION_TIMEOUT = StringUtils.fromString("sessionTimeout");
    public static final BString SECURESOCKET_CONFIG_MUTUAL_SSL = StringUtils.fromString("mutualSsl");
    public static final BString SECURESOCKET_CONFIG_VERIFY_CLIENT = StringUtils.fromString("verifyClient");
    public static final BString SECURESOCKET_CONFIG_CERT_VALIDATION_TYPE_OCSP_STAPLING =
            StringUtils.fromString("OCSP_STAPLING");

    //Socket Config
    public static final BString SOCKET_CONFIG = StringUtils.fromString("socketConfig");
    public static final BString SOCKET_CONFIG_SO_BACKLOG = StringUtils.fromString("soBackLog");
    public static final BString SOCKET_CONFIG_CONNECT_TIMEOUT = StringUtils.fromString("connectTimeOut");
    public static final BString SOCKET_CONFIG_RECEIVE_BUFFER_SIZE = StringUtils.fromString("receiveBufferSize");
    public static final BString SOCKET_CONFIG_SEND_BUFFER_SIZE = StringUtils.fromString("sendBufferSize");
    public static final BString SOCKET_CONFIG_TCP_NO_DELAY = StringUtils.fromString("tcpNoDelay");
    public static final BString SOCKET_CONFIG_SOCKET_REUSE = StringUtils.fromString("socketReuse");
    public static final BString SOCKET_CONFIG_KEEP_ALIVE = StringUtils.fromString("keepAlive");

    //Client Endpoint (CallerActions)
    public static final String CLIENT_ENDPOINT_SERVICE_URI = "url";
    public static final String CLIENT_ENDPOINT_CONFIG = "config";
    public static final int CLIENT_ENDPOINT_CONFIG_INDEX = 0;
    public static final int CLIENT_ENDPOINT_URL_INDEX = 0;
    public static final int CLIENT_GLOBAL_POOL_INDEX = 1;

    //Client Endpoint Config
    public static final BString CLIENT_EP_AUTH = StringUtils.fromString("auth");
    public static final BString CLIENT_EP_CHUNKING = StringUtils.fromString("chunking");
    public static final BString CLIENT_EP_ENDPOINT_TIMEOUT = StringUtils.fromString("timeout");
    public static final BString CLIENT_EP_IS_KEEP_ALIVE = StringUtils.fromString("keepAlive");
    public static final BString CLIENT_EP_HTTP_VERSION = StringUtils.fromString("httpVersion");
    public static final BString CLIENT_EP_FORWARDED = StringUtils.fromString("forwarded");
    public static final String TARGET_SERVICES = "targets";
    public static final String CLIENT_EP_ACCEPT_ENCODING = "acceptEncoding";
    public static final BString HTTP2_PRIOR_KNOWLEDGE = StringUtils.fromString("http2PriorKnowledge");
    public static final BString HTTP1_SETTINGS = StringUtils.fromString("http1Settings");
    public static final BString HTTP2_SETTINGS = StringUtils.fromString("http2Settings");
    public static final BString REQUEST_LIMITS = StringUtils.fromString("requestLimits");
    public static final BString RESPONSE_LIMITS = StringUtils.fromString("responseLimits");

    //Connection Throttling field names
    public static final String CONNECTION_THROTTLING_STRUCT_REFERENCE = "connectionThrottling";
    public static final String CONNECTION_THROTTLING_MAX_ACTIVE_CONNECTIONS = "maxActiveConnections";
    public static final String CONNECTION_THROTTLING_WAIT_TIME = "waitTime";
    public static final String CONNECTION_THROTTLING_MAX_ACTIVE_STREAMS_PER_CONNECTION =
            "maxActiveStreamsPerConnection";

    //Client connection pooling configs
    public static final BString CONNECTION_POOLING_MAX_ACTIVE_CONNECTIONS = StringUtils.fromString(
            "maxActiveConnections");
    public static final BString CONNECTION_POOLING_MAX_IDLE_CONNECTIONS = StringUtils.fromString("maxIdleConnections");
    public static final BString CONNECTION_POOLING_WAIT_TIME = StringUtils.fromString("waitTime");
    public static final BString CONNECTION_POOLING_MAX_ACTIVE_STREAMS_PER_CONNECTION = StringUtils.fromString(
            "maxActiveStreamsPerConnection");
    public static final BString CONNECTION_POOLING_EVICTABLE_IDLE_TIME = StringUtils.fromString(
            "minEvictableIdleTime");
    public static final BString CONNECTION_POOLING_TIME_BETWEEN_EVICTION_RUNS = StringUtils.fromString(
            "timeBetweenEvictionRuns");
    public static final String HTTP_CLIENT_CONNECTION_POOL = "PoolConfiguration";
    public static final String CONNECTION_MANAGER = "ConnectionManager";
    public static final int POOL_CONFIG_INDEX = 1;
    public static final BString USER_DEFINED_POOL_CONFIG = StringUtils.fromString("poolConfig");

    //FollowRedirect field names
    public static final String FOLLOW_REDIRECT_STRUCT_REFERENCE = "followRedirects";
    public static final String FOLLOW_REDIRECT_ENABLED = "enabled";
    public static final String FOLLOW_REDIRECT_MAXCOUNT = "maxCount";

    //Proxy field names
    public static final BString PROXY_STRUCT_REFERENCE = StringUtils.fromString("proxy");
    public static final BString PROXY_HOST = StringUtils.fromString("host");
    public static final BString PROXY_PORT = StringUtils.fromString("port");
    public static final BString PROXY_USERNAME = StringUtils.fromString("userName");
    public static final BString PROXY_PASSWORD = StringUtils.fromString("password");

    public static final String HTTP_SERVICE_TYPE = "Service";
    // Filter related
    public static final String ENDPOINT_CONFIG_FILTERS = "filters";
    public static final String FILTERS = "FILTERS";
    public static final String HTTP_REQUEST_FILTER_FUNCTION_NAME = "filterRequest";

    // Retry Config
    public static final String CLIENT_EP_RETRY = "retry";
    public static final String RETRY_COUNT = "count";
    public static final String RETRY_INTERVAL = "intervalInMillis";

    public static final BString SERVICE_ENDPOINT_PROTOCOL_FIELD = StringUtils.fromString("protocol");
    public static final BString CALLER_PRESENT_FIELD = StringUtils.fromString("present");

    //Remote struct field names
    public static final BString REMOTE_STRUCT_FIELD = StringUtils.fromString("remoteAddress");
    public static final BString REMOTE_HOST_FIELD = StringUtils.fromString("host");
    public static final BString REMOTE_PORT_FIELD = StringUtils.fromString("port");
    public static final BString REMOTE_IP_FIELD = StringUtils.fromString("ip");
    public static final String REMOTE_SOCKET_ADDRESS = "remoteSocketAddress";

    //Local struct field names
    public static final BString LOCAL_STRUCT_INDEX = StringUtils.fromString("localAddress");
    public static final BString LOCAL_HOST_FIELD = StringUtils.fromString("host");
    public static final BString LOCAL_PORT_FIELD = StringUtils.fromString("port");
    public static final BString LOCAL_IP_FIELD = StringUtils.fromString("ip");

    //Link struct field names
    public static final String LINK = "Link";
    public static final BString LINK_REL = StringUtils.fromString("rel");
    public static final BString LINK_HREF = StringUtils.fromString("href");
    public static final BString LINK_METHODS = StringUtils.fromString("methods");
    public static final BString LINK_TYPES = StringUtils.fromString("types");

    //WebSocket Related constants for WebSocket upgrade
    public static final String NATIVE_DATA_WEBSOCKET_CONNECTION_MANAGER = "NATIVE_DATA_WEBSOCKET_CONNECTION_MANAGER";

    public static final int REQUEST_STRUCT_INDEX = 1;
    public static final boolean DIRTY_REQUEST = true;
    public static final String NO_ENTITY_BODY = "NO_ENTITY_BODY";

    public static final String MOCK_LISTENER_ENDPOINT = "MockListener";
    public static final String HTTP_LISTENER_ENDPOINT = "Listener";

    public static final String PLUS = "+";
    public static final String COLON = ":";
    public static final String DOLLAR = "$";
    public static final String SINGLE_SLASH = "/";
    public static final String QUESTION_MARK = "?";
    public static final String PLUS_SIGN = "\\+";
    public static final String PLUS_SIGN_ENCODED = "%2B";
    public static final String PERCENTAGE = "%";
    public static final String PERCENTAGE_ENCODED = "%25";
    public static final String AND_SIGN = "&";
    public static final String EQUAL_SIGN = "=";
    public static final String EMPTY = "";
    public static final String QUOTATION_MARK = "\"";
    public static final String DOUBLE_SLASH = "//";
    public static final String WHITESPACE = " ";
    public static final String REGEX = "(?<!(http:|https:))//";
    public static final String SCHEME_SEPARATOR = "://";
    public static final String HTTP_SCHEME = "http";
    public static final String HTTPS_SCHEME = "https";

    public static final String SERVER_CONNECTOR_FUTURE = "ServerConnectorFuture";

    public static final String HTTP_VERSION_1_1 = "1.1";

    public static final String CURRENT_TRANSACTION_CONTEXT_PROPERTY = "currentTrxContext";

    @Deprecated
    public static final String HTTP_MODULE_VERSION = "1.0.6";
    public static final String PACKAGE = "ballerina";

    @Deprecated
    public static final String PROTOCOL_PACKAGE_HTTP =
            PACKAGE + ORG_NAME_SEPARATOR + PROTOCOL_HTTP + COLON + HTTP_MODULE_VERSION;
    @Deprecated
    public static final Module PROTOCOL_HTTP_PKG_ID =
            new Module(BALLERINA_BUILTIN_PKG_PREFIX, PROTOCOL_HTTP, HTTP_MODULE_VERSION);

    public static final String OBSERVABILITY_CONTEXT_PROPERTY = "observabilityContext";

    public static final BString REQUEST_CTX_MEMBERS = StringUtils.fromString("members");

    private HttpConstants() {
    }
}
