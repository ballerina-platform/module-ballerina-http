// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

const int requestTest = 9000;
const int requestTest2 = 9093;
const int databindingTest = 9001;
const int producesConsumesTest = 9002;
const int uriMatrixParamMatchingTest = 9003;
const int uriTemplateTest1 = 9004;
const int uriTemplateTest2 = 9005;
const int uriTemplateDefaultTest1 = 9006;
const int uriTemplateDefaultTest2 = 9007;
const int uriTemplateDefaultTest3 = 9008;
const int uriTemplateMatchingTest = 9009;
const int virtualHostTest = 9010;
const int serviceTest = 9011;
const int CompressionConfigTest = 9012;
const int serviceConfigTest = 7070;
const int corsConfigTest = 9013;
const int connectionNativeTest = 9014;
const int serviceDetachTest = 9015;
const int serviceEndpointTest = 9016;
const int parseHeaderTest = 9017;
const int multipartRequestTest = 9018;
const int responseTest = 9094;
const int entityTest = 9097;
const int mimeTest = 9096;
const int proxyTest1 = 9019;
const int proxyTest2 = 9020;
const int streamTest1 = 9021;
const int streamTest2 = 9022;
const int introResTest = 9023;

// Integration test ports
// HTTP
const int acceptEncodingHeaderTestPort = 9500;
const int requestLimitsTestPort1 = 9501;
const int requestLimitsTestPort2 = 9502;
const int requestLimitsTestPort3 = 9503;
const int requestLimitsTestPort4 = 9504;
const int compressionAnnotationTestPort = 9505;
const int echoServiceTestPort = 9506;
const int echoHttpsServiceTestPort = 9507;
const int ecommerceTestPort = 9508;
const int httpClientActionTestPort1 = 9509;
const int httpClientActionTestPort2 = 9510;
const int httpClientContinueTestPort1 = 9511;
const int httpClientContinueTestPort2 = 9512;
const int httpServerFieldTestPort1 = 9513;
const int idleTimeoutTestPort = 9514;
const int httpHeaderTestPort1 = 9515;
const int httpHeaderTestPort2 = 9516;
const int httpOptionsTestPort = 9517;
const int httpPayloadTestPort1 = 9518;
const int httpPayloadTestPort2 = 9519;
const int httpStatusCodeTestPort = 9520;
const int httpUrlTestPort1 = 9521;
const int httpUrlTestPort2 = 9522;
const int httpVerbTestPort = 9523;
const int httpRoutingTestPort = 9524;
const int serviceChainingTestPort = 9525;
const int trailingHeaderTestPort1 = 9526;
const int trailingHeaderTestPort2 = 9527;
const int reuseRequestTestPort = 9528;
const int expectContinueTestPort1 = 9529;
const int expectContinueTestPort2 = 9530;
const int pipeliningTestPort1 = 9531;
const int pipeliningTestPort2 = 9532;
const int pipeliningTestPort3 = 9533;
const int keepAliveClientTestPort = 9534;
const int multipleClientTestPort1 = 9535;
const int multipleClientTestPort2 = 9536;
const int resourceFunctionTestPort = 9537;
const int retryFunctionTestPort1 = 9538;
const int retryFunctionTestPort2 = 9539;
const int serializeXmlTestPort = 9540;
const int cachingTestPort1 = 9541;
const int cachingTestPort2 = 9542;
const int cachingTestPort3 = 9543;
const int cachingTestPort4 = 9544;
const int callerActionTestPort = 9545;
const int dirtyResponseTestPort = 9546;
const int listenerMethodTestPort1 = 9547;
const int listenerMethodTestPort2 = 9548;
const int clientDatabindingTestPort1 = 9549;
const int clientDatabindingTestPort2 = 9550;
const int clientDatabindingTestPort3 = 9551;
const int queryParamBindingTest = 9552;
const int basePathTest = 9553;
const int resourceReturnTest = 9554;
const int requestLimitsTestPort5 = 9555;
const int requestLimitsTestPort6 = 9556;
const int responseLimitsTestPort1 = 9557;
const int responseLimitsTestPort2 = 9558;
const int responseLimitsTestPort3 = 9559;
const int responseLimitsTestPort4 = 9560;
const int responseLimitsTestPort5 = 9561;
const int headerParamBindingTest = 9562;
const int outRequestTypeTest = 9563;
const int outRequestOptionsTest = 9564;
const int pathParamCheckTestPort = 9565;
const int httpReturnNilTestPort = 9566;
const int clientForwardTestPort1 = 9567;
const int clientForwardTestPort2 = 9568;
const int cBClientWithoutStatusCodesTestPort1 = 9569;
const int cBClientWithoutStatusCodesTestPort2 = 9570;
const int foClientWithoutStatusCodeTestPort1 = 9571;
const int foClientWithoutStatusCodeTestPort2 = 9572;
const int inResponseCachedPayloadTestPort = 9573;
const int inResponseCachedPayloadTestBEPort = 9574;
const int httpEnumMethodsTestPort = 9575;
const int payloadAccessAfterRespondingTestPort = 9576;
const int cacheAnnotationTestPort1 = 9577;
const int cacheAnnotationTestPort2 = 9578;
const int serviceMediaTypeSubtypePrefixPort = 9579;
const int queryParamBindingIdealTestPort = 9580;
const int headerParamBindingIdealTestPort = 9581;
const int clientWithoutSchemeTestPort = 9582;
const int databindingTestWithInterceptorsPort = 9583;
const int defaultRequestInterceptorTestPort = 9584;
const int requestInterceptorWithCallerRespondTestPort = 9585;
const int requestInterceptorReturnsErrorTestPort = 9586;
const int requestErrorInterceptorTestPort = 9587;
const int requestInterceptorDataBindingTestPort1 = 9588;
const int requestInterceptorDataBindingTestPort2 = 9589;
const int requestInterceptorSetPayloadTestPort = 9590;
const int requestInterceptorWithoutCtxNextTestPort = 9591;
const int requestInterceptorHttpVerbTestPort = 9592;
const int requestInterceptorBasePathTestPort = 9593;
const int getRequestInterceptorBasePathTestPort = 9594;
const int requestInterceptorSkipTestPort = 9595;
const int requestInterceptorNegativeTestPort1 = 9596;
const int requestInterceptorNegativeTestPort2 = 9597;
const int requestInterceptorNegativeTestPort3 = 9598;
const int requestInterceptorNegativeTestPort4 = 9599;
const int requestInterceptorNegativeTestPort5 = 9600;
const int requestInterceptorNegativeTestPort6 = 9601;
const int requestInterceptorCallerRespondContinueTestPort = 9602;
const int requestInterceptorStringPayloadBindingTestPort = 9603;
const int requestInterceptorRecordPayloadBindingTestPort = 9604;
const int requestInterceptorRecordArrayPayloadBindingTestPort = 9605;
const int requestInterceptorByteArrayPayloadBindingTestPort = 9606;
const int requestInterceptorWithQueryParamTestPort = 9607;
const int requestInterceptorServiceConfigTestPort1 = 9608;
const int requestInterceptorServiceConfigTestPort2 = 9609;
const int clientFormUrlEncodedTestPort = 9610;
const int typedHeadersTestPort = 9611;
const int urlEncodedResponsesTestPort = 9612;

//HTTP2
const int serverPushTestPort1 = 9701;
const int serverPushTestPort2 = 9702;
const int http2RedirectTestPort1 = 9703;
const int http2RedirectTestPort2 = 9704;
const int http2RedirectTestPort3 = 9705;
const int http2RetryFunctionTestPort1 = 9706;
const int http2RetryFunctionTestPort2 = 9707;

//Security
const int securedListenerPort = 9400;
const int stsPort = 9445;
