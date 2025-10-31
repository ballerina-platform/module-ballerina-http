# Real-Time Stock Monitor - Server-Sent Events (SSE) Example

A comprehensive real-world example demonstrating Server-Sent Events (SSE) implementation using the Ballerina HTTP module. This example simulates a real-time stock price monitoring system with live updates.

## 📋 Overview

This project demonstrates:
- **Server-Sent Events (SSE)** implementation in Ballerina
- Real-time data streaming from server to client
- Multiple SSE endpoints with different data streams
- Event stream generation using custom stream generators
- Client-side SSE consumption with JavaScript EventSource API
- Real-world use case: Stock price monitoring

## 🏗️ Architecture

### Server Components

1. **Stock Price Stream** (`/stock-monitor/prices`)
   - Streams real-time stock price updates every 2 seconds
   - Supports filtering by stock symbols via query parameters
   - Returns `stream<http:SseEvent, error?>`

2. **Market Summary Stream** (`/stock-monitor/market-summary`)
   - Streams market-wide statistics every 5 seconds
   - Provides aggregated data across all stocks

3. **REST Endpoints**
   - `/stock-monitor/current-prices` - Get current snapshot of all stocks
   - `/stock-monitor/symbols` - Get list of available stock symbols

### Client Components

- Interactive HTML/JavaScript client
- Real-time stock cards with live price updates
- Market summary dashboard
- Event log for debugging
- Connection controls

## 🚀 Features

### SSE Implementation Features

- ✅ **Custom Stream Generators**: Demonstrates how to create stream generators for SSE events
- ✅ **Event Types**: Multiple event types (`stock-update`, `market-summary`)
- ✅ **Event IDs**: Sequential event IDs for tracking
- ✅ **Event Data**: JSON-formatted data in SSE events
- ✅ **Event Comments**: Additional metadata in SSE events
- ✅ **Query Parameters**: Filter stocks using query parameters
- ✅ **Error Handling**: Proper validation and error responses
- ✅ **Graceful Shutdown**: Stream termination after max events

### Application Features

- 📊 8 simulated stocks (AAPL, GOOGL, MSFT, AMZN, TSLA, META, NVDA, JPM)
- 💹 Realistic price fluctuations (-2% to +2% per update)
- 📈 Market summary with aggregated statistics
- 🎨 Beautiful, responsive UI with animations
- 🔌 Connection state management
- 📝 Real-time event logging

## 📁 Project Structure

```
stock-monitor/
├── Ballerina.toml          # Project configuration
├── service.bal             # Main SSE service implementation
├── client.html             # HTML/JavaScript SSE client
└── README.md               # This file
```

## 🛠️ Prerequisites

- Ballerina Swan Lake (2201.10.0 or later)
- A modern web browser with EventSource API support

## 📦 Installation & Running

### 1. Navigate to the project directory

```bash
cd stock-monitor
```

### 2. Run the Ballerina service

```bash
bal run
```

The service will start on `http://localhost:9090`

### 3. Open the client

Open your web browser and navigate to:
```
http://localhost:9090/stock-monitor
```

## 💻 Usage

### Using the Web Client

1. **Connect to All Stocks**: Click "Connect" without entering any symbols
2. **Connect to Specific Stocks**: Enter comma-separated symbols (e.g., `AAPL,GOOGL,MSFT`) and click "Connect"
3. **View Updates**: Watch real-time stock price updates and market summary
4. **Disconnect**: Click "Disconnect" to stop the stream

### Using Test Scripts\r\n\r\n**Windows (PowerShell)**:\r\n```powershell\r\n.\test-sse.ps1\r\n```\r\n\r\n**Linux/macOS (Bash)**:\r\n```bash\r\nchmod +x test-sse.sh\r\n./test-sse.sh\r\n```\r\n\r\n### Using curl to Test SSE Endpoints

#### Stock Prices Stream (All Stocks)
```bash
curl -N http://localhost:9090/stock-monitor/prices
```

#### Stock Prices Stream (Specific Stocks)
```bash
curl -N "http://localhost:9090/stock-monitor/prices?symbols=AAPL,GOOGL,MSFT"
```

#### Market Summary Stream
```bash
curl -N http://localhost:9090/stock-monitor/market-summary
```

#### Current Prices (REST)
```bash
curl http://localhost:9090/stock-monitor/current-prices
```

## 🔧 Configuration Options

### Modify Update Intervals

In `service.bal`, adjust the sleep duration:

```ballerina
// Stock prices update interval (default: 2 seconds)
runtime:sleep(2);

// Market summary update interval (default: 5 seconds)
runtime:sleep(5);
```

### Change Maximum Events

```ballerina
// Limit events to prevent infinite streams
private final int maxEvents = 1000; // Adjust as needed
```

### Customize Stock List

```ballerina
const map<string> STOCKS = {
    "YOUR_SYMBOL": "Company Name",
    // Add more stocks...
};

map<decimal> stockPrices = {
    "YOUR_SYMBOL": 100.00,
    // Add initial prices...
};
```
## 📚 Learn More

### Ballerina Documentation
- [Ballerina HTTP Module](https://central.ballerina.io/ballerina/http/latest)
- [Ballerina Streams](https://ballerina.io/learn/by-example/streams/)
- [Ballerina Error Handling](https://ballerina.io/learn/by-example/error-handling/)

### SSE Resources
- [MDN: Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
- [EventSource API](https://developer.mozilla.org/en-US/docs/Web/API/EventSource)
- [SSE Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)

