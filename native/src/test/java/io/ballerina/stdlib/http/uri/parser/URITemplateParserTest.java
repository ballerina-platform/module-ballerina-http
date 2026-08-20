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

package io.ballerina.stdlib.http.uri.parser;

import io.ballerina.stdlib.http.api.HttpResourceArguments;
import io.ballerina.stdlib.http.uri.URITemplate;
import io.ballerina.stdlib.http.uri.URITemplateException;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.io.UnsupportedEncodingException;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNull;
import static org.testng.Assert.assertThrows;

/**
 * Unit tests for the URI template parser and the node tree it builds, driven end to end: a template is parsed
 * into the tree and then real URIs are matched against it.
 *
 * <p>The production tree stores a resource per leaf, so these tests store a {@link String} name instead and
 * assert which name a URI resolves to, along with the path parameters that were bound on the way.
 */
public class URITemplateParserTest {

    /**
     * The smallest {@link DataElement} that behaves like the production one: it holds a value and hands it to
     * the return agent when the tree reaches it.
     */
    private static final class StringDataElement implements DataElement<String, String> {

        private String data;

        @Override
        public void setData(String data) {
            this.data = data;
        }

        @Override
        public boolean hasData() {
            return data != null;
        }

        @Override
        public boolean getData(String inboundMessage, DataReturnAgent<String> dataReturnAgent) {
            if (data == null) {
                return false;
            }
            dataReturnAgent.setData(data);
            return true;
        }
    }

    private URITemplate<String, String> uriTemplate;

    @BeforeMethod
    public void setup() throws URITemplateException {
        uriTemplate = new URITemplate<>(new Literal<>(new StringDataElement(), "/"));
    }

    private void parse(String template, String resource) throws URITemplateException, UnsupportedEncodingException {
        uriTemplate.parse(template, resource, StringDataElement::new);
    }

    private String match(String uri, HttpResourceArguments args) {
        return uriTemplate.matches(uri, args, "inbound");
    }

    private String match(String uri) {
        return match(uri, new HttpResourceArguments());
    }

    @Test(description = "The root template matches the root path")
    public void testRootTemplate() throws Exception {
        parse("/", "root");
        assertEquals(match("/"), "root", "Root path did not resolve to the root resource");
    }

    @Test(description = "A multi segment literal path matches exactly and nothing else")
    public void testLiteralPath() throws Exception {
        parse("/orders/pending", "pending");
        assertEquals(match("/orders/pending"), "pending", "Literal path did not resolve");
        assertNull(match("/orders/other"), "A different literal must not resolve");
        assertNull(match("/orders"), "A prefix of the template must not resolve");
    }

    @Test(description = "A trailing slash in the template is ignored at parse time, but the matcher does not "
            + "apply the same normalisation to an incoming request")
    public void testTrailingSlashInTemplate() throws Exception {
        parse("/orders/", "orders");
        assertEquals(match("/orders"), "orders", "Template with a trailing slash did not match the bare path");
        assertNull(match("/orders/"),
                   "A request with a trailing slash is matched literally, not normalised like the template was");
    }

    @Test(description = "A path parameter is bound to the segment it matched")
    public void testSinglePathParameter() throws Exception {
        parse("/orders/{orderId}", "byId");
        HttpResourceArguments args = new HttpResourceArguments();
        assertEquals(match("/orders/42", args), "byId", "Path with a parameter did not resolve");
        assertEquals(args.getMap().get("orderId").get(0), "42", "orderId was not bound to the matched segment");
    }

    @Test(description = "Several path parameters across segments are each bound to their own segment")
    public void testMultiplePathParameters() throws Exception {
        parse("/orders/{orderId}/items/{itemId}", "item");
        HttpResourceArguments args = new HttpResourceArguments();
        assertEquals(match("/orders/7/items/9", args), "item", "Nested parameter path did not resolve");
        assertEquals(args.getMap().get("orderId").get(0), "7", "orderId was not bound");
        assertEquals(args.getMap().get("itemId").get(1), "9", "itemId was not bound at its own expression index");
    }

    @Test(description = "A parameter value is URL decoded when it is bound")
    public void testPathParameterIsDecoded() throws Exception {
        parse("/orders/{orderId}", "byId");
        HttpResourceArguments args = new HttpResourceArguments();
        assertEquals(match("/orders/a%20b", args), "byId", "Encoded parameter did not resolve");
        assertEquals(args.getMap().get("orderId").get(0), "a b", "Parameter value was not URL decoded");
    }

    @Test(description = "A literal and an expression in the same segment parse, but the matcher compares the "
            + "literal against the whole segment, so such a template never matches a request")
    public void testLiteralPrefixBeforeParameterParsesButDoesNotMatch() throws Exception {
        parse("/orders/id-{orderId}", "prefixed");
        assertNull(match("/orders/id-42", new HttpResourceArguments()),
                   "A literal prefixed expression is not supported by the matcher and must not resolve");
    }

    @Test(description = "A literal path is preferred over a parameter that would also match the same URI")
    public void testLiteralTakesPrecedenceOverParameter() throws Exception {
        parse("/orders/{orderId}", "byId");
        parse("/orders/pending", "pending");
        assertEquals(match("/orders/pending"), "pending", "The literal path should win over the parameter");
        assertEquals(match("/orders/42"), "byId", "A non matching literal should fall through to the parameter");
    }

    @Test(description = "Templates sharing a prefix are merged into one tree rather than duplicating nodes")
    public void testSharedPrefixTemplates() throws Exception {
        parse("/orders/{orderId}/items", "items");
        parse("/orders/{orderId}/status", "status");
        assertEquals(match("/orders/1/items"), "items", "First shared-prefix template did not resolve");
        assertEquals(match("/orders/1/status"), "status", "Second shared-prefix template did not resolve");
        assertNull(match("/orders/1/unknown"), "An unregistered leaf must not resolve");
    }

    @Test(description = "A path with no registered resource resolves to nothing rather than failing")
    public void testUnmatchedPathReturnsNull() throws Exception {
        parse("/orders", "orders");
        assertNull(match("/customers"), "An unregistered path must not resolve");
    }

    @Test(description = "An intermediate node without its own resource does not resolve on its own")
    public void testIntermediateNodeWithoutDataDoesNotResolve() throws Exception {
        parse("/orders/{orderId}/items", "items");
        assertNull(match("/orders/1"), "An intermediate node carries no resource and must not resolve");
    }

    @Test(description = "A prefix modifier binds only when the value length matches the prefix exactly")
    public void testPrefixModifierOnParameter() throws Exception {
        parse("/orders/{orderId:2}", "byShortId");
        HttpResourceArguments matching = new HttpResourceArguments();
        assertEquals(match("/orders/42", matching), "byShortId", "A value of the prefix length should match");
        assertEquals(matching.getMap().get("orderId").get(0), "42", "Parameter was not bound");
        assertNull(match("/orders/12345", new HttpResourceArguments()),
                   "A value longer than the prefix must not match");
        assertNull(match("/orders/4", new HttpResourceArguments()),
                   "A value shorter than the prefix must not match either");
    }

    @Test(description = "The parser rejects a template that opens a second expression before closing the first")
    public void testNestedExpressionIsRejected() {
        assertThrows(URITemplateException.class, () -> parse("/orders/{a{b}}", "bad"));
    }

    @Test(description = "The parser rejects a closing brace with no expression open")
    public void testStrayClosingBraceIsRejected() {
        assertThrows(URITemplateException.class, () -> parse("/orders/a}", "bad"));
    }

    @Test(description = "The parser rejects an expression with nothing between the braces")
    public void testEmptyExpressionIsRejected() {
        assertThrows(URITemplateException.class, () -> parse("/orders/{}", "bad"));
    }

    @Test(description = "The parser rejects an open brace too close to the end of the segment to hold a name")
    public void testDanglingOpenBraceIsRejected() {
        assertThrows(URITemplateException.class, () -> parse("/orders/{a", "bad"));
    }

    @Test(description = "A variable name with a character that is not allowed in an identifier is rejected")
    public void testInvalidVariableCharacterIsRejected() {
        assertThrows(URITemplateException.class, () -> parse("/orders/{order id}", "bad"));
    }

    @Test(description = "A zero or negative prefix modifier is rejected")
    public void testInvalidPrefixModifierIsRejected() {
        assertThrows(URITemplateException.class, () -> parse("/orders/{orderId:0}", "bad"));
        assertThrows(URITemplateException.class, () -> parse("/orders/{orderId:-1}", "bad"));
    }

    @Test(description = "A template starting with a wildcard is rejected outright")
    public void testTemplateStartingWithWildcardIsRejected() {
        assertThrows(URITemplateException.class, () -> parse("*/orders", "bad"));
    }

    @Test(description = "A wildcard segment matches the remainder of the path")
    public void testWildcardSegmentMatchesRemainder() throws Exception {
        parse("/files/*", "files");
        assertEquals(match("/files/a"), "files", "Wildcard did not match a single trailing segment");
        assertEquals(match("/files/a/b/c"), "files", "Wildcard did not match a multi segment remainder");
    }

    @Test(description = "Parsing pre-split segments takes the same route as parsing a template string")
    public void testParseFromSegments() throws Exception {
        uriTemplate.parse(new String[]{"orders", "{orderId}"}, "byId", StringDataElement::new);
        HttpResourceArguments args = new HttpResourceArguments();
        assertEquals(match("/orders/42", args), "byId", "Segment based parsing did not build a matching tree");
        assertEquals(args.getMap().get("orderId").get(0), "42", "Parameter was not bound via segment parsing");
    }

    @Test(description = "An empty segment array registers the resource at the root of the tree")
    public void testParseFromEmptySegmentsBindsRoot() throws Exception {
        uriTemplate.parse(new String[]{}, "root", StringDataElement::new);
        assertEquals(match("/"), "root", "An empty segment array did not bind the root resource");
    }

    @Test(description = "Comma separated names in one expression are all bound from the matched segment")
    public void testMultipleVariablesInOneExpression() throws Exception {
        parse("/orders/{a,b}", "multi");
        HttpResourceArguments args = new HttpResourceArguments();
        assertEquals(match("/orders/value", args), "multi", "An expression with two names did not resolve");
        assertEquals(args.getMap().get("a").get(0), "value", "First name was not bound");
        assertEquals(args.getMap().get("b").get(0), "value", "Second name was not bound");
    }

    @Test(description = "An expression that starts with a comma has a zero length name and is rejected")
    public void testZeroLengthVariableReferenceIsRejected() {
        assertThrows(URITemplateException.class, () -> parse("/orders/{,a}", "bad"));
    }
}
