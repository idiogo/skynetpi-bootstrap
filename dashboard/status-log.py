#!/usr/bin/env python3
"""Simple status logger for dashboard tweets"""
import json
import os
import sys
from datetime import datetime

STATUS_FILE = "/tmp/skynetpi-status.json"
MAX_ENTRIES = 30

def log_status(text):
    """Log a status update (tweet)"""
    entries = []
    if os.path.exists(STATUS_FILE):
        try:
            with open(STATUS_FILE, 'r') as f:
                entries = json.load(f)
        except:
            entries = []
    
    # Truncate text to ~150 chars for display
    if len(text) > 150:
        text = text[:147] + "..."
    
    entries.append({
        "time": datetime.utcnow().isoformat() + "Z",
        "text": text
    })
    
    # Keep only last N entries
    entries = entries[-MAX_ENTRIES:]
    
    with open(STATUS_FILE, 'w') as f:
        json.dump(entries, f)

if __name__ == '__main__':
    if len(sys.argv) > 1:
        log_status(' '.join(sys.argv[1:]))
        print("Logged!")
    else:
        print("Usage: status-log.py <message>")
