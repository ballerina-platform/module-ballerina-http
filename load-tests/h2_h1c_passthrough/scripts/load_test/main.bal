import ballerina/io;
import ballerina/time;
import ballerina/lang.runtime;
import ballerina/log;
import ballerina/http;

public function main(string label, string output_csv_path) returns error? {
    http:Client loadTestClient = check new ("https://bal.perf.test:443/passthrough",
        httpVersion = "2.0",
        http2Settings = {
            http2PriorKnowledge: true
        }
    );
    int sentCount = 0;
    int errorCount = 0;
    int receivedCount = 0;
    time:Utc startedTime = time:utcNow();
    time:Utc expiryTime = time:utcAddSeconds(startedTime, 600);
    json payload = {event: "event"};
    while time:utcDiffSeconds(expiryTime, time:utcNow()) > 0D {
        json|error response = loadTestClient->post("", payload);
        sentCount += 1;
        if response is error {
            errorCount += 1;
        }
        if response == payload {
            receivedCount += 1;
        }
        runtime:sleep(0.1);
    }
    decimal time = time:utcDiffSeconds(time:utcNow(), startedTime);
    log:printInfo("Test summary: ", sent = sentCount, received = receivedCount, errors = errorCount, duration = time);
    any[] results = [label, sentCount, <float>time/<float>receivedCount, 0, 0, 0, 0, 0, 0, <float>errorCount/<float>sentCount, 
        <float>receivedCount/<float>time, 0, 0, time:utcNow()[0], 0, 1];
    check writeResultsToCsv(results, output_csv_path);

}

function writeResultsToCsv(any[] results, string output_path) returns error? {
    string[][] summary_data = check io:fileReadCsv(output_path);
    string[] final_results = [];
    foreach var result in results {
        final_results.push(result.toString());
    }
    summary_data.push(final_results);
    check io:fileWriteCsv(output_path, summary_data);
}
