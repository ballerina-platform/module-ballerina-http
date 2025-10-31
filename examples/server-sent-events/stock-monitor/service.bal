import ballerina/http;
import ballerina/lang.runtime;
import ballerina/random;
import ballerina/log;
import ballerina/io;
import ballerina/time;

type Stock record {|
    string symbol;
    string name;
    decimal price;
    decimal changePercent;
    string timestamp;
|};


const map<string> STOCKS = {
    "AAPL": "Apple Inc.",
    "GOOGL": "Alphabet Inc.",
    "MSFT": "Microsoft Corporation",
    "AMZN": "Amazon.com Inc.",
    "TSLA": "Tesla Inc.",
    "META": "Meta Platforms Inc.",
    "NVDA": "NVIDIA Corporation",
    "JPM": "JPMorgan Chase & Co."
};


isolated map<decimal> stockPrices = {
    "AAPL": 178.50,
    "GOOGL": 142.30,
    "MSFT": 385.20,
    "AMZN": 151.75,
    "TSLA": 242.80,
    "META": 356.90,
    "NVDA": 495.40,
    "JPM": 157.30
};

// HTTP listener on port 9090
listener http:Listener stockListener = new (9090);

service /stock\-monitor on stockListener {

    // Serve the HTML client
    resource function get .() returns http:Response|http:InternalServerError {
        http:Response response = new;
        string|io:Error htmlContent = io:fileReadString("client.html");
        if htmlContent is io:Error {
            log:printError("Error loading client.html", htmlContent);
            return <http:InternalServerError>{
                body: "Error loading client page"
            };
        }
        response.setTextPayload(htmlContent, "text/html");
        return response;
    }

    // SSE endpoint - streams real-time stock prices
    // Returns a stream of SseEvent objects
    resource function get prices(string? symbols) returns stream<http:SseEvent, error?>|http:BadRequest {
        log:printInfo("New SSE connection established");
        
        // Parse requested symbols or use all stocks
        string[] requestedSymbols = symbols is string ? parseSymbols(symbols) : STOCKS.keys();
        
        // Validate symbols
        foreach string symbol in requestedSymbols {
            if !STOCKS.hasKey(symbol) {
                return <http:BadRequest>{
                    body: {
                        message: string `Invalid stock symbol: ${symbol}`,
                        validSymbols: STOCKS.keys()
                    }
                };
            }
        }
        
        // Create and return the stock price stream
        return createStockPriceStream(requestedSymbols);
    }

    // SSE endpoint - streams market summary statistics
    resource function get market\-summary() returns stream<http:SseEvent, error?> {
        log:printInfo("Market summary SSE connection established");
        return createMarketSummaryStream();
    }

    // REST endpoint - get current prices for all stocks
    resource function get current\-prices() returns map<Stock> {
        map<Stock> currentStocks = {};
        // Get snapshot of prices outside lock to avoid restricted variable usage
        map<decimal> pricesSnapshot;
        lock {
            pricesSnapshot = stockPrices.clone();
        }
        foreach [string, decimal] [symbol, price] in pricesSnapshot.entries() {
            currentStocks[symbol] = createStockData(symbol, price);
        }
        return currentStocks;
    }

    // REST endpoint - get available stock symbols
    resource function get symbols() returns map<string> {
        return STOCKS;
    }
}

// Creates a stream of SSE events for stock prices
function createStockPriceStream(string[] symbols) returns stream<http:SseEvent, error?> {
    // Create a stream that generates events every 2 seconds
    stream<http:SseEvent, error?> eventStream = new (new StockPriceGenerator(symbols));
    return eventStream;
}

// Creates a stream of SSE events for market summary
function createMarketSummaryStream() returns stream<http:SseEvent, error?> {
    stream<http:SseEvent, error?> eventStream = new (new MarketSummaryGenerator());
    return eventStream;
}

// Stream generator for stock prices
class StockPriceGenerator {
    private string[] symbols;
    private int eventCount = 0;
    private final int maxEvents = 1000; // Limit to prevent infinite streams in tests

    function init(string[] symbols) {
        self.symbols = symbols;
    }

    public isolated function next() returns record {|http:SseEvent value;|}|error? {
        if self.eventCount >= self.maxEvents {
            log:printInfo("Reached maximum event count, closing stream");
            return (); // End the stream
        }

        // Wait for 2 seconds between updates
        runtime:sleep(2);

        // Update prices with random fluctuations
        foreach string symbol in self.symbols {
            lock {
                decimal currentPrice = stockPrices.get(symbol);
                decimal|error newPrice = updateStockPrice(currentPrice);
                if newPrice is decimal {
                    stockPrices[symbol] = newPrice;
                }
            }
        }

        // Create event data
        map<decimal> pricesSnapshot;
        lock {
            pricesSnapshot = stockPrices.clone();
        }
        
        map<Stock> stockData = {};
        foreach string symbol in self.symbols {
            if pricesSnapshot.hasKey(symbol) {
                stockData[symbol] = createStockData(symbol, pricesSnapshot.get(symbol));
            }
        }

        // Create SSE event with JSON data
        http:SseEvent event = {
            id: self.eventCount.toString(),
            event: "stock-update",
            data: stockData.toJsonString(),
            comment: "Real-time stock price update"
        };

        self.eventCount += 1;
        log:printDebug(string `Sent event ${self.eventCount} with ${self.symbols.length()} stock(s)`);
        
        return {value: event};
    }
}

// Stream generator for market summary
class MarketSummaryGenerator {
    private int eventCount = 0;
    private final int maxEvents = 500;

    public isolated function next() returns record {|http:SseEvent value;|}|error? {
        if self.eventCount >= self.maxEvents {
            return ();
        }

        runtime:sleep(5); // Update every 5 seconds

        // Calculate market statistics
        decimal totalValue = 0;
        int stockCount = 0;
        
        lock {
            stockCount = stockPrices.length();
            foreach decimal price in stockPrices {
                totalValue += price;
            }
        }

        // Simulate market change percentage
        int|error randomVal = random:createIntInRange(-300, 300);
        decimal marketChange = randomVal is int ? <decimal>randomVal / 100.0 : 0.0;
        
        map<json> summary = {
            "totalMarketValue": totalValue,
            "averagePrice": totalValue / <decimal>stockCount,
            "marketChangePercent": marketChange,
            "activeStocks": stockCount,
            "timestamp": getCurrentTimestamp()
        };

        http:SseEvent event = {
            id: self.eventCount.toString(),
            event: "market-summary",
            data: summary.toJsonString()
        };

        self.eventCount += 1;
        return {value: event};
    }
}

// Helper function to update stock price with realistic fluctuations
isolated function updateStockPrice(decimal currentPrice) returns decimal|error {
    // Random price change between -2% and +2%
    int randVal = check random:createIntInRange(-200, 200);
    decimal changePercent = <decimal>randVal / 10000.0d;
    decimal newPrice = currentPrice * (1.0d + changePercent);
    return <decimal>(<int>(newPrice * 100.0d)) / 100.0d;
}

// Helper function to create stock data record
isolated function createStockData(string symbol, decimal price) returns Stock {
    decimal basePrice = 150.0d; // Assumed base for change calculation
    decimal changePercent = ((price - basePrice) / basePrice) * 100.0d;
    
    return {
        symbol: symbol,
        name: STOCKS.get(symbol),
        price: price,
        changePercent: <decimal>(<int>(changePercent * 100.0d)) / 100.0,
        timestamp: getCurrentTimestamp()
    };
}

// Helper function to get current timestamp
isolated function getCurrentTimestamp() returns string {
    time:Utc currentTime = time:utcNow();
    string|error timeStr = time:utcToString(currentTime);
    return timeStr is string ? timeStr : "2025-10-31T00:00:00Z";
}

// Helper function to parse comma-separated symbols
function parseSymbols(string symbolsStr) returns string[] {
    string[] symbols = [];
    string[] parts = re `,`.split(symbolsStr);
    foreach string part in parts {
        string trimmed = part.trim();
        if trimmed.length() > 0 {
            symbols.push(trimmed.toUpperAscii());
        }
    }
    return symbols;
}
