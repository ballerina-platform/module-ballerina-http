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

import ballerina/lang.'string as strings;
import ballerina/url;
import ballerina/mime;
import ballerina/regex;
import ballerina/test;

const string CONTENT_TYPE = "content-type";
const string ETAG = "etag";
const string CACHE_CONTROL = "cache-control";
const string LAST_MODIFIED = "last-modified";
const string CONTENT_ENCODING = "content-encoding";
const string ACCEPT_ENCODING = "accept-encoding";
const string CONTENT_LENGTH = "content-length";
const string TRANSFER_ENCODING = "transfer-encoding";
const string LOCATION = "location";
const string ORIGIN = "origin";
const string ALLOW = "Allow";
const string LINK = "link";
const string ACCESS_CONTROL_ALLOW_ORIGIN = "access-control-allow-origin";
const string ACCESS_CONTROL_ALLOW_CREDENTIALS = "access-control-allow-credentials";
const string ACCESS_CONTROL_ALLOW_HEADERS = "access-control-allow-headers";
const string ACCESS_CONTROL_ALLOW_METHODS = "access-control-allow-methods";
const string ACCESS_CONTROL_EXPOSE_HEADERS = "access-control-expose-headers";
const string ACCESS_CONTROL_MAX_AGE = "access-control-max-age";
const string ACCESS_CONTROL_REQUEST_HEADERS = "access-control-request-headers";
const string ACCESS_CONTROL_REQUEST_METHOD = "access-control-request-method";
const string IF_NONE_MATCH = "If-None-Match";
const string IF_MODIFIED_SINCE = "If-Modified-Since";
const string SERVER = "server";

const string ENCODING_GZIP = "gzip";
const string ENCODING_DEFLATE = "deflate";
const string HTTP_TRANSFER_ENCODING_IDENTITY = "identity";

const string HTTP_METHOD_GET = "GET";
const string HTTP_METHOD_POST = "POST";
const string HTTP_METHOD_PUT = "PUT";
const string HTTP_METHOD_PATCH = "PATCH";
const string HTTP_METHOD_DELETE = "DELETE";
const string HTTP_METHOD_OPTIONS = "OPTIONS";
const string HTTP_METHOD_HEAD = "HEAD";

const string TEXT_PLAIN = "text/plain";
const string APPLICATION_XML = "application/xml";
const string APPLICATION_JSON = "application/json";
const string APPLICATION_FORM = "application/x-www-form-urlencoded";
const string APPLICATION_BINARY = "application/octet-stream";

const string errorMessage = "Found an unexpected output:";


isolated function getContentDispositionForFormData(string partName)
                                    returns (mime:ContentDisposition) {
    mime:ContentDisposition contentDisposition = new;
    contentDisposition.name = partName;
    contentDisposition.disposition = "form-data";
    return contentDisposition;
}

isolated function assertJsonValue(json|error payload, string expectKey, json expectValue) {
    if payload is map<json> {
        test:assertEquals(payload[expectKey], expectValue, msg = "Found unexpected output");
    } else if payload is error {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

isolated function assertJsonPayload(json|error payload, json expectValue) {
    if payload is json {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

isolated function assertJsonPayloadtoJsonString(json|error payload, json expectValue) {
    if payload is json {
        test:assertEquals(payload.toJsonString(), expectValue.toJsonString(), msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

isolated function assertXmlPayload(xml|error payload, xml expectValue) {
    if payload is xml {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

isolated function assertBinaryPayload(byte[]|error payload, byte[] expectValue) {
    if payload is byte[] {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

isolated function assertTextPayload(string|error payload, string expectValue) {
    if payload is string {
        test:assertEquals(payload, expectValue, msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

isolated function assertUrlEncodedPayload(string payload, map<string> expectedValue) returns error? {
    map<string> retrievedPayload = {};
    string decodedPayload = check url:decode(payload, "UTF-8");
    string[] entries = regex:split(decodedPayload, "&");
    foreach string entry in entries {
        int? delimeterIdx = entry.indexOf("=");
        if delimeterIdx is int {
            string name = entry.substring(0, delimeterIdx);
            name = name.trim();
            string value = entry.substring(delimeterIdx + 1);
            value = value.trim();
            retrievedPayload[name] = value;
        }
    }
    test:assertEquals(retrievedPayload, expectedValue, msg = "Found unexpected output");
}

isolated function assertTrueTextPayload(string|error payload, string expectValue) {
    if payload is string {
        test:assertTrue(strings:includes(payload, expectValue), msg = "Found unexpected output");
    } else {
        test:assertFail(msg = "Found unexpected output type: " + payload.message());
    }
}

isolated function assertHeaderValue(string headerKey, string expectValue) {
    test:assertEquals(headerKey, expectValue, msg = "Found unexpected headerValue");
}

isolated function assertErrorHeaderValue(string[]? headerKey, string expectValue) {
    if (headerKey is string[]) {
        test:assertEquals(headerKey[0], expectValue, msg = "Found unexpected headerValue");
    } else {
        test:assertFail(msg = "Header not found");
    }
}

isolated function assertErrorMessage(any|error err, string expectValue) {
    if err is error {
        test:assertEquals(err.message(), expectValue, msg = "Found unexpected error message");
    } else {
        test:assertFail(msg = "Found unexpected output");
    }
}

isolated function assertErrorCauseMessage(any|error err, string expectValue) {
    if err is error {
        error? errorCause = err.cause();
        if errorCause is error {
            test:assertEquals(errorCause.message(), expectValue, msg = "Found unexpected error cause message");
        } else {
            test:assertFail(msg = "Found unexpected error cause");
        }
    } else {
        test:assertFail(msg = "Found unexpected output");
    }
}

const string LARGE_ENTITY = "Lorem ipsum dolor sit amet, libris quaerendum sea ei, in nec fugit " +
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