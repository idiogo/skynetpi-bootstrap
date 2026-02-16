#!/usr/bin/env python3
"""Log server for SkynetPi Dashboard - with detailed events v2"""
import http.server
import json
import glob
import os
import re

PORT = 8765
LOG_DIR = "/tmp/openclaw"
KVM_LOG = "/tmp/kvm-events.json"
STATUS_LOG = "/tmp/skynetpi-status.json"

def truncate(text, max_len=40):
    """Truncate text with ellipsis"""
    if not text:
        return ''
    text = str(text).replace('\n', ' ').strip()
    if len(text) > max_len:
        return text[:max_len-3] + '...'
    return text

def get_status_tweets():
    """Read status tweets (narrative logs)"""
    if not os.path.exists(STATUS_LOG):
        return []
    try:
        with open(STATUS_LOG, 'r') as f:
            entries = json.load(f)
        return [{'type': 'tweet', 'icon': '💭', 'text': e['text'], 'time': e['time']} for e in entries]
    except:
        return []

def get_kvm_events():
    """Read KVM events"""
    if not os.path.exists(KVM_LOG):
        return []
    try:
        with open(KVM_LOG, 'r') as f:
            events = json.load(f)
        result = []
        for e in events:
            action = e.get('action', '')
            detail = e.get('detail', '')
            if action == 'keyboard':
                result.append({'type': 'kvm', 'icon': '⌨️', 'text': detail, 'time': e.get('time', '')})
            elif action == 'mouse':
                result.append({'type': 'kvm', 'icon': '🖱️', 'text': detail, 'time': e.get('time', '')})
            elif action == 'screen':
                result.append({'type': 'kvm', 'icon': '📸', 'text': detail, 'time': e.get('time', '')})
            elif action == 'vision':
                result.append({'type': 'kvm', 'icon': '👁️', 'text': detail, 'time': e.get('time', '')})
        return result
    except:
        return []

def format_sender(sender):
    """Format sender identifier for display (last 8 chars)"""
    if not sender:
        return ''
    # Strip common prefixes, show last portion
    sender = str(sender)
    if len(sender) > 12:
        return '...' + sender[-8:]
    return sender

def get_openclaw_events(limit=20):
    """Read events from OpenClaw logs with details"""
    log_files = sorted(glob.glob(f"{LOG_DIR}/openclaw-*.log"), reverse=True)
    if not log_files:
        return []
    
    events = []
    seen = set()
    
    # Read last 100KB of log
    with open(log_files[0], 'rb') as f:
        f.seek(0, 2)
        size = f.tell()
        f.seek(max(0, size - 100000))
        content = f.read().decode('utf-8', errors='ignore')
    
    for line in content.split('\n'):
        if not line.strip():
            continue
        try:
            data = json.loads(line)
            time = data.get('time', '')
            msg1 = data.get('1', '')
            msg2 = str(data.get('2', ''))
            event = None
            event_key = None
            
            # Inbound message with body preview
            if 'inbound message' in msg2 or 'inbound web message' in msg2:
                if isinstance(msg1, dict):
                    body = msg1.get('body', '')
                    sender = msg1.get('from', '')
                    media = msg1.get('mediaType', '')
                    
                    # Extract just the message content (remove timestamp prefix)
                    if '] ' in body:
                        body = body.split('] ', 1)[-1]
                    
                    who = format_sender(sender)
                    preview = truncate(body, 25)
                    
                    if media and 'image' in media:
                        text = f'📷 {who}: {preview}' if preview else f'📷 Image from {who}'
                    elif preview:
                        text = f'{who}: {preview}'
                    else:
                        text = f'Msg from {who}'
                    
                    event = {'type': 'message', 'icon': '📥', 'text': text, 'time': time}
                    event_key = f"in-{time[:19]}"  # Dedupe by second
            
            # Auto-reply sent with preview
            elif 'auto-reply sent' in msg2:
                if isinstance(msg1, dict):
                    text_sent = msg1.get('text', '')
                    # Remove markdown
                    text_sent = re.sub(r'\*\*([^*]+)\*\*', r'\1', text_sent)
                    text_sent = re.sub(r'\*([^*]+)\*', r'\1', text_sent)
                    preview = truncate(text_sent, 35)
                    text = f'Me: {preview}' if preview else 'Reply sent'
                    event = {'type': 'reply', 'icon': '✅', 'text': text, 'time': time}
                    event_key = f"out-{time[:19]}"
            
            # Tool calls
            elif isinstance(msg1, str) and 'tool start' in msg1:
                tool_match = re.search(r'tool=(\w+)', msg1)
                tool = tool_match.group(1) if tool_match else ''
                
                if tool == 'web_search':
                    event = {'type': 'tool', 'icon': '🔍', 'text': 'Web search', 'time': time}
                elif tool == 'web_fetch':
                    event = {'type': 'tool', 'icon': '🌐', 'text': 'Fetching page', 'time': time}
                elif tool == 'Read':
                    event = {'type': 'tool', 'icon': '📖', 'text': 'Reading file', 'time': time}
                elif tool == 'Write':
                    event = {'type': 'tool', 'icon': '✍️', 'text': 'Writing file', 'time': time}
                elif tool == 'Edit':
                    event = {'type': 'tool', 'icon': '📝', 'text': 'Editing file', 'time': time}
                elif tool == 'exec':
                    event = {'type': 'tool', 'icon': '⚡', 'text': 'Running command', 'time': time}
                elif tool == 'message':
                    event = {'type': 'tool', 'icon': '📤', 'text': 'Sending message', 'time': time}
                elif tool == 'image':
                    event = {'type': 'tool', 'icon': '👁️', 'text': 'Analyzing image', 'time': time}
                elif tool == 'memory_search':
                    event = {'type': 'tool', 'icon': '🧠', 'text': 'Searching memory', 'time': time}
                elif tool == 'cron':
                    event = {'type': 'tool', 'icon': '⏰', 'text': 'Managing cron', 'time': time}
                elif tool == 'browser':
                    event = {'type': 'tool', 'icon': '🖥️', 'text': 'Controlling browser', 'time': time}
                elif tool:
                    event = {'type': 'tool', 'icon': '🔧', 'text': f'Tool: {tool}', 'time': time}
            
            # Gateway events
            elif isinstance(msg1, str):
                if 'gateway connected' in msg1.lower():
                    event = {'type': 'system', 'icon': '🟢', 'text': 'Gateway connected', 'time': time}
                elif 'gateway disconnected' in msg1.lower():
                    event = {'type': 'system', 'icon': '🔴', 'text': 'Gateway disconnected', 'time': time}
                elif 'Native image: loaded' in msg1:
                    event = {'type': 'tool', 'icon': '🖼️', 'text': 'Processing image', 'time': time}
            
            if event:
                key = event_key or f"{time}-{event['text'][:20]}"
                if key not in seen:
                    seen.add(key)
                    events.append(event)
                
        except json.JSONDecodeError:
            continue
    
    return events[-limit:]

def get_all_events():
    """Combine all events, sorted by time, prioritizing messages"""
    tweets = get_status_tweets()
    kvm = get_kvm_events()
    openclaw = get_openclaw_events(40)  # Get more events
    
    all_events = tweets + kvm + openclaw
    all_events.sort(key=lambda x: x.get('time', ''))
    
    # Keep recent events but ensure messages/replies are included
    recent = all_events[-40:]
    
    # Separate by priority
    high_priority = [e for e in recent if e['type'] in ('message', 'reply', 'system', 'tweet', 'kvm')]
    low_priority = [e for e in recent if e['type'] not in ('message', 'reply', 'system', 'tweet', 'kvm')]
    
    # Take last N of each, combine and sort
    result = high_priority[-15:] + low_priority[-10:]
    result.sort(key=lambda x: x.get('time', ''))
    
    return result[-25:]

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        events = get_all_events()
        self.wfile.write(json.dumps({'events': events}).encode())
    
    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    print(f"Log server running on http://127.0.0.1:{PORT}")
    server = http.server.HTTPServer(('127.0.0.1', PORT), Handler)
    server.serve_forever()
