#!/usr/bin/env python3
"""
Debug Log Server for iPhone App
Receives NDJSON logs from iPhone and writes to debug.log file
"""
import http.server
import socketserver
import json
import os
import sys
from datetime import datetime

# Configuration
LOG_FILE = "/Users/johnuja/Desktop/Haven2.0/.cursor/debug.log"
PORT = 8080

def get_local_ip():
    """Get the Mac's local IP address"""
    import socket
    try:
        # Connect to a remote address to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

class LogHandler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        """Handle POST requests with NDJSON log data"""
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            # Parse JSON log entry
            log_entry = json.loads(post_data.decode('utf-8'))
            
            # Write to log file (append mode)
            with open(LOG_FILE, 'a') as f:
                f.write(json.dumps(log_entry) + '\n')
            
            # Send success response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
            
        except Exception as e:
            print(f"Error processing log: {e}", file=sys.stderr)
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())
    
    def log_message(self, format, *args):
        """Suppress default request logging"""
        pass

def main():
    # Ensure log file directory exists
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    
    # Clear existing log file
    if os.path.exists(LOG_FILE):
        os.remove(LOG_FILE)
        print(f"Cleared existing log file: {LOG_FILE}")
    
    # Get local IP
    local_ip = get_local_ip()
    
    # Start server
    with socketserver.TCPServer(("", PORT), LogHandler) as httpd:
        print(f"\n{'='*60}")
        print(f"Debug Log Server Started")
        print(f"{'='*60}")
        print(f"Mac IP Address: {local_ip}")
        print(f"Server URL: http://{local_ip}:{PORT}/ingest")
        print(f"Log File: {LOG_FILE}")
        print(f"{'='*60}")
        print(f"\nServer is running. Press Ctrl+C to stop.\n")
        print(f"Update your Swift code to use: http://{local_ip}:{PORT}/ingest")
        print(f"{'='*60}\n")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\nServer stopped.")

if __name__ == "__main__":
    main()

