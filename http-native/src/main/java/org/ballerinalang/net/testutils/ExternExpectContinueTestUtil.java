/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

package org.ballerinalang.net.testutils;

import io.netty.buffer.Unpooled;
import io.netty.handler.codec.http.DefaultHttpRequest;
import io.netty.handler.codec.http.DefaultLastHttpContent;
import io.netty.handler.codec.http.FullHttpResponse;
import io.netty.handler.codec.http.HttpHeaderNames;
import io.netty.handler.codec.http.HttpHeaderValues;
import io.netty.handler.codec.http.HttpMethod;
import io.netty.handler.codec.http.HttpResponseStatus;
import io.netty.handler.codec.http.HttpVersion;
import io.netty.util.CharsetUtil;
import org.ballerinalang.net.testutils.client.HttpClient;
import org.ballerinalang.net.testutils.client.HttpUrlClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.Assert;

import java.io.IOException;
import java.nio.charset.Charset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Contains utility functions used for verifying the server-side 100-continue behaviour.
 */
public class ExternExpectContinueTestUtil {

    private static final Logger log = LoggerFactory.getLogger(ExternExpectContinueTestUtil.class);
    private static final String LARGE_ENTITY = "Lorem ipsum dolor sit amet, libris quaerendum sea ei, in nec fugit " +
            "prodesset. Pro te quas mundi, mel viderer inimicus urbanitas an. No dolor essent timeam mei, exerci " +
            "virtute nostrum pri ad. Graeco doctus ea eam.\n" +
            "\n" +
            "Eu exerci iuvaret euismod nec. Erat graecis vivendo eos et, an vel tation adipisci repudiandae. Vix " +
            "fuisset laboramus te, erant prompta offendit qui cu, velit utroque percipitur nam no. Eum ubique vidisse" +
            " corpora no, vim in modus scripserit delicatissimi. Nam te mazim moderatius. Nisl eligendi eu his, " +
            "consul dolorem pericula eam at.\n" +
            "\n" +
            "Vix persecuti persequeris cu, sea ne meis integre. Has no nonumes sensibus persecuti, natum nusquam " +
            "mentitum ius id. Mea ne quis legendos volutpat, doming ornatus est ne, has quas rebum periculis ei. Per " +
            "ea unum euismod, purto senserit moderatius vis ea, pro no nostro percipit philosophia. Agam modus ne cum" +
            ".\n" +
            "\n" +
            "At mei quas prodesset. Ei his laudem eripuit civibus. Reque dolorem quo no. At vix diam partem " +
            "reprimique, no vis ignota nusquam pertinacia.\n" +
            "\n" +
            "Sensibus expetenda neglegentur ad eam, zril voluptatum vis te. Libris deseruisse sea ex, vel exerci " +
            "quidam at, minim voluptaria intellegam eum ut. Id probo mollis delenit cum, timeam mentitum sea ut, usu " +
            "omnium oportere ei. Cu eos illud lucilius, te nec ipsum accumsan vulputate, at omnes imperdiet molestiae" +
            " mel. Affert propriae noluisse an usu, pri viris iuvaret cu, at elit persequeris sed.\n" +
            "\n" +
            "Sed id unum elit altera, cu nobis nominavi sit. Eum id munere delenit urbanitas. Usu causae denique " +
            "antiopam eu, pro ut virtute qualisque. Solet habemus mnesarchum eum ne, an eum congue luptatum " +
            "mediocritatem, mei semper admodum perfecto eu. Sea euripidis interesset ea, eripuit adversarium no nam. " +
            "Mundi rationibus voluptatibus pro in. Alia malis tantas ne his.\n" +
            "\n" +
            "Sit ex debitis nonumes omittam. Ei his eleifend suavitate, voluptua corrumpit ius cu. Sea ornatus " +
            "nonumes an, noluisse principes sed ad. Labores recteque qui ad. Pro recteque sententiae signiferumque an" +
            ".\n" +
            "\n" +
            "Pro ad civibus praesent. Ad quo percipit conclusionemque, unum soleat mea ea. Eu fugit constituto qui. " +
            "No augue nihil luptatum quo, ut pri utinam recusabo. Cum ut senserit complectitur, per et tota ceteros " +
            "suscipiantur.\n" +
            "\n" +
            "Ut ornatus ocurreret eum. Vivendum imperdiet ne his. Usu meis malis offendit an, et duo omnium vivendum " +
            "convenire. Iusto fierent legendos mea cu. Ea eum recteque adipiscing, eos ut brute delenit ancillae, " +
            "pertinax assentior maiestatis sit ex.\n" +
            "\n" +
            "His no oblique oportere. Mei ad agam graeco theophrastus, et mel etiam aeque oblique, id diam graeci est" +
            ". Dico detracto ut duo, mea ea reque saperet explicari. Quo eu alienum consetetur, soleat suscipiantur " +
            "per id, eos et affert docendi menandri. Vel luptatum oportere interesset ne. Suas unum vix no, est ad " +
            "impedit salutatus vulputate.\n" +
            "\n" +
            "Iudico graecis conceptam mei an. Minim simul et nam, quod torquatos per ad. Ea quando adolescens " +
            "contentiones sit, eos at tritani aliquid offendit. Nibh delenit admodum an mea. Oratio oporteat " +
            "interesset usu ei, quo corrumpit gubergren ea. Putant laoreet voluptua at eum.\n" +
            "\n" +
            "Ne vix clita viderer habemus. Dicant eleifend ad has, ad suas utinam mea. Quo fabellas eleifend eu, an " +
            "mea esse tincidunt comprehensam. An vide adipisci scribentur vim, vel ad velit conclusionemque, animal " +
            "impetus vis te.\n" +
            "\n" +
            "Civibus verterem est at. Ne his odio homero, at mel vero elit, an quo adipisci urbanitas. Eu veritus " +
            "omittam volutpat est, simul apeirian quaestio id vis. Ridens utroque ad vis, choro aperiam lobortis et " +
            "ius, munere maiestatis an mea.\n" +
            "\n" +
            "His ea vidit iriure cotidieque, et nam doming accusam. Sed cu cetero feugait. Id prima scaevola " +
            "tacimates duo. Sensibus appellantur mel ex, an mel clita equidem perfecto.\n" +
            "\n" +
            "Vix diam iudico in, qui cu probo congue offendit, ne vitae appetere vel. An vim vide patrioque, cum at " +
            "nobis liberavisse, ius in idque constituto. Sea esse prodesset eu, mea doctus legimus te. Sint aperiri " +
            "repudiare ei sed. Denique luptatum lobortis nam eu, at omnis soleat expetenda mel, ei periculis " +
            "principes pertinacia usu. Brute insolens erroribus has ut, deleniti maluisset at sit.\n" +
            "\n" +
            "Iudicabit consetetur eu quo, eam eu wisi quas neglegentur, no pro sint fugit facer. Nonumy minimum " +
            "evertitur cu mea. Meis possit ut has, nec wisi iriure definitionem in, no perpetua vituperatoribus usu. " +
            "Sea ea reque error percipitur. Legendos pericula conclusionemque has eu, sed nullam argumentum " +
            "efficiendi ad. Vel paulo iudicabit eu, brute definitiones et nec. Ut pro vidit maiorum, indoctum " +
            "definiebas interesset eos ei, sed meis contentiones an.\n" +
            "\n" +
            "Legere graeci intellegam usu ad, mei partem latine apeirian ei, ex decore graeco mnesarchum duo. Eu tale" +
            " posidonium adversarium ius. Vis at iudico omnesque. Te aperiri feugait delectus ius, quot adipiscing te" +
            " quo. Consul euripidis sententiae ius in. No fabulas denique duo, eum id etiam iudico.\n" +
            "\n" +
            "Quot molestiae theophrastus mel ad, aeque disputando per eu, impedit vocibus consequat at vix. Fabellas " +
            "adipiscing deterruisset te sea. Eos an sale tincidunt, eu pri deserunt neglegentur, option eripuit " +
            "ancillae vel te. Sea oratio iisque ut.\n" +
            "\n" +
            "Vel regione similique ex, repudiare inciderint ad duo, nihil tibique torquatos eu eam. Modo iudico " +
            "consequat vel no, at ius nibh gubergren. Nec eros mutat justo ex, ipsum posidonium argumentum pro no. " +
            "Decore soluta latine cu eos, nam quas insolens repudiandae ad, patrioque voluptatum te pro.\n" +
            "\n" +
            "At vis semper civibus, posse quando sensibus pri ad, nec ut minimum laboramus. Agam quaeque has ne, tota" +
            " soluta mollis ea mel. Et vel virtute omnesque. Assum patrioque et nam, in cum ludus bonorum molestie, " +
            "sed laoreet tibique nominati at. Posse euismod repudiandae in his, nec zril complectitur deterruisset " +
            "ad, has falli perfecto id. No dicta minimum sit, mea laudem labore animal ex.\n" +
            "\n" +
            "Aperiri graecis eligendi ne nam. Per nulla euismod consequuntur id. Ea tota animal lucilius qui, " +
            "eligendi platonem usu et. An solet tantas vis. Cu utamur perfecto has, et sea mundi percipit intellegam" +
            ".\n" +
            "\n" +
            "Augue laboramus eam ut, et lorem nobis voluptatibus his. Eos dico suas persius eu, dicant fierent sea " +
            "te, nec cu erat numquam deterruisset. Te per dignissim vituperatoribus, brute petentium ne sit, eu " +
            "ridens splendide usu. Tibique contentiones ne vix, prima ceteros mei cu. Ius ex minim luptatum " +
            "persequeris, iusto zril mel ut. An vim feugiat deseruisse, at sed nulla deserunt.\n" +
            "\n" +
            "Mel soluta verear adversarium ut, no sint etiam eos. At qui vocent voluptua temporibus. An nec dicunt " +
            "feugiat placerat. Cum an laudem recusabo, at vis harum decore. Quo no saperet volutpat, quas " +
            "conclusionemque ei mel, illum tantas per id.\n" +
            "\n" +
            "Pri vidit dolor mollis ad, maiorum albucius inimicus ut eum. Congue tincidunt instructior mei an, graeci" +
            " omittantur eum cu. Menandri electram sadipscing quo no. An invidunt senserit ius, ea euismod voluptua " +
            "has, id inciderint contentiones ius. Ad cum error honestatis.\n" +
            "\n" +
            "Ut legimus accusamus maiestatis est. Discere corpora quaestio est ne. Ei option concludaturque vix. " +
            "Autem mazim tamquam in nec, ex cum ponderum dignissim, unum dicat nulla ius eu. No sea fabellas probatus" +
            " necessitatibus, consulatu dissentiunt et qui, et repudiare consequuntur vim.\n" +
            "\n" +
            "Ad impetus tractatos instructior nec, esse tritani periculis usu ad. Has in habeo debitis senserit, mea " +
            "at aliquid praesent. Nobis facete ad mel, ex quod theophrastus duo. An eripuit delectus eum, has an " +
            "electram suavitate.\n" +
            "\n" +
            "Eum dicit mentitum at, agam liber aeterno nec ea. Ut sed vide impetus saperet. Sumo utroque menandri eum" +
            " no, te eum cibo molestiae, ea vis oratio tibique denique. Prima tibique commune sed ea, vim choro " +
            "alienum et.\n";
    private static final byte[] LARGE_ENTITY_BYTES = LARGE_ENTITY.getBytes(CharsetUtil.UTF_8);
    private static final int LARGE_ENTITY_LENGTH = LARGE_ENTITY_BYTES.length;

    //Test 100 continue response and for request with expect:100-continue header
    public static boolean externTest100Continue(int servicePort) {
        HttpClient httpClient = new HttpClient("localhost", servicePort);

        DefaultHttpRequest httpRequest = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/continue");
        DefaultLastHttpContent reqPayload = new DefaultLastHttpContent(
                Unpooled.wrappedBuffer(LARGE_ENTITY_BYTES));

        httpRequest.headers().set(HttpHeaderNames.CONTENT_LENGTH, LARGE_ENTITY_LENGTH);
        httpRequest.headers().set(HttpHeaderNames.CONTENT_TYPE, HttpHeaderValues.TEXT_PLAIN);
        httpRequest.headers().set("X-Status", "Positive");

        List<FullHttpResponse> responses = httpClient.sendExpectContinueRequest(httpRequest, reqPayload);

        Assert.assertFalse(httpClient.waitForChannelClose());

        // 100-continue response
        Assert.assertEquals(responses.get(0).status(), HttpResponseStatus.CONTINUE);
        Assert.assertEquals(Integer.parseInt(responses.get(0).headers().get(HttpHeaderNames.CONTENT_LENGTH)), 0);

        // Actual response
        String responsePayload = Utils.getEntityBodyFrom(responses.get(1));
        Assert.assertEquals(responses.get(1).status(), HttpResponseStatus.OK);
        Assert.assertEquals(responsePayload, LARGE_ENTITY);
        Assert.assertEquals(responsePayload.getBytes(CharsetUtil.UTF_8).length, LARGE_ENTITY_LENGTH);
        Assert.assertEquals(Integer.parseInt(responses.get(1).headers().get(HttpHeaderNames.CONTENT_LENGTH)),
                            LARGE_ENTITY_LENGTH);
        return true;
    }

    //Test ignoring inbound payload with a 417 response for request with expect:100-continue header")
    public static boolean externTest100ContinueNegative(int servicePort) {
        HttpClient httpClient = new HttpClient("localhost", servicePort);

        DefaultHttpRequest httpRequest = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST, "/continue");
        DefaultLastHttpContent reqPayload = new DefaultLastHttpContent(
                Unpooled.wrappedBuffer(LARGE_ENTITY_BYTES));

        httpRequest.headers().set(HttpHeaderNames.CONTENT_LENGTH, LARGE_ENTITY_LENGTH);
        httpRequest.headers().set(HttpHeaderNames.CONTENT_TYPE, HttpHeaderValues.TEXT_PLAIN);

        List<FullHttpResponse> responses = httpClient.sendExpectContinueRequest(httpRequest, reqPayload);

        Assert.assertFalse(httpClient.waitForChannelClose());

        // 417 Expectation Failed response
        Assert.assertEquals(responses.get(0).status(), HttpResponseStatus.EXPECTATION_FAILED, "Response code mismatch");
        int length = Integer.parseInt(responses.get(0).headers().get(HttpHeaderNames.CONTENT_LENGTH));
        Assert.assertEquals(length, 26, "Content length mismatched");
        String payload = responses.get(0).content().readCharSequence(length, Charset.defaultCharset()).toString();
        Assert.assertEquals(payload, "Do not send me any payload", "Entity body mismatched");
        // Actual response
        Assert.assertEquals(responses.size(), 1,
                            "Multiple responses received when only a 417 response was expected");
        return true;
    }

    //Test multipart form data request with expect:100-continue header
    public static boolean externTestMultipartWith100ContinueHeader(int servicePort) {
        Map<String, String> headers = new HashMap<>();
        headers.put(HttpHeaderNames.EXPECT.toString(), HttpHeaderValues.CONTINUE.toString());

        Map<String, String> formData = new HashMap<>();
        formData.put("person", "engineer");
        formData.put("team", "ballerina");

        HttpResponse response = null;
        try {
            response = HttpUrlClient.doMultipartFormData(
                    HttpUrlClient.getServiceURLHttp(servicePort, "continue/getFormParam"), headers, formData);
        } catch (IOException e) {
            log.error("Error in processing multipart HTTP request" + e.getMessage());
            return false;
        }
        Assert.assertNotNull(response);
        Assert.assertEquals(response.getResponseCode(), 200, "Response code mismatched");
        Assert.assertEquals(response.getData(), "Result = Key:person Value: engineer Key:team Value: ballerina");
        return true;
    }

    public static boolean externTest100ContinuePassthrough(int servicePort) {
        HttpClient httpClient = new HttpClient("localhost", servicePort);

        DefaultHttpRequest reqHeaders = new DefaultHttpRequest(HttpVersion.HTTP_1_1, HttpMethod.POST,
                                                               "/continue/testPassthrough");
        DefaultLastHttpContent reqPayload = new DefaultLastHttpContent(
                Unpooled.wrappedBuffer(LARGE_ENTITY_BYTES));

        reqHeaders.headers().set(HttpHeaderNames.CONTENT_LENGTH, LARGE_ENTITY_LENGTH);
        reqHeaders.headers().set(HttpHeaderNames.CONTENT_TYPE, HttpHeaderValues.TEXT_PLAIN);

        List<FullHttpResponse> responses = httpClient.sendExpectContinueRequest(reqHeaders, reqPayload);

        Assert.assertFalse(httpClient.waitForChannelClose());

        // 100-continue response
        Assert.assertEquals(responses.get(0).status(), HttpResponseStatus.CONTINUE);
        Assert.assertEquals(Integer.parseInt(responses.get(0).headers().get(HttpHeaderNames.CONTENT_LENGTH)), 0);

        // Actual response
        String responsePayload = Utils.getEntityBodyFrom(responses.get(1));
        Assert.assertEquals(responses.get(1).status(), HttpResponseStatus.OK);
        Assert.assertEquals(responsePayload, LARGE_ENTITY);
        Assert.assertEquals(responsePayload.getBytes(CharsetUtil.UTF_8).length, LARGE_ENTITY_LENGTH);
        Assert.assertEquals(Integer.parseInt(responses.get(1).headers().get(HttpHeaderNames.CONTENT_LENGTH)),
                            LARGE_ENTITY_LENGTH);
        return true;
    }

    private ExternExpectContinueTestUtil() {
    }
}
