import ballerina/http;
import ballerina/lang.runtime;

listener http:Listener counterListener = new(8080);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service /counter on counterListener {
    
    resource function get events() returns stream<http:SseEvent, error?>|error {
        CounterStream counterStream = new CounterStream();
        stream<http:SseEvent, error?> eventStream = new(counterStream);
        return eventStream;
    }
}

class CounterStream {
    *object:Iterable;
    private int count = 0;
    private final int maxCount = 10;
    
    public isolated function iterator() returns object {
        public isolated function next() returns record {|http:SseEvent value;|}|error?;
    } {
        return self;
    }
    
    public isolated function next() returns record {|http:SseEvent value;|}|error? {
        
        if self.count >= self.maxCount {
            return ();
        }
        
        self.count += 1;
        
        http:SseEvent event = {
            data: string `Count: ${self.count}`,
            event: "counter",
            id: self.count.toString()
        };
        
        runtime:sleep(1);
        
        return {value: event};
    }
}

