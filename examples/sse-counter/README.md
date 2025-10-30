### How to Run:

```bash
bal run
```

### How to Test:

1. **Open the HTML client:**
   - Open `client.html` in your browser
   - It will auto-connect and display events

2. **Or use curl:**
   ```bash
   curl -N http://localhost:8080/counter/events
   ```

3. **Expected output:**
   ```
   event: counter
   id: 1
   data: Count: 1

   event: counter
   id: 2
   data: Count: 2
   ...
   ```