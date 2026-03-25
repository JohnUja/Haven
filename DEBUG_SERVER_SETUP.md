# Debug Server Setup for iPhone Testing

## Step 1: Find Your Mac's IP Address

Run this in Terminal on your Mac:

```bash
python3 /Users/johnuja/Desktop/Haven2.0/start_debug_server.py
```

The script will:
1. Find your Mac's local IP address automatically
2. Start a debug log server on port 8080
3. Display the server URL you need to use

**Example output:**
```
============================================================
Debug Log Server Started
============================================================
Mac IP Address: 192.168.1.100
Server URL: http://192.168.1.100:8080/ingest
Log File: /Users/johnuja/Desktop/Haven2.0/.cursor/debug.log
============================================================
```

## Step 2: Update Swift Code with Your Mac's IP

After you see the IP address, I'll update the Swift code to use that IP address.

## Step 3: Start the Server

Keep the Python script running in Terminal. It will receive logs from your iPhone.

## Step 4: Run the App on iPhone

Build and run the app on your iPhone. The logs will be sent to your Mac automatically.

## Step 5: View Logs

The logs will be written to: `/Users/johnuja/Desktop/Haven2.0/.cursor/debug.log`

You can watch the logs in real-time with:
```bash
tail -f /Users/johnuja/Desktop/Haven2.0/.cursor/debug.log
```

