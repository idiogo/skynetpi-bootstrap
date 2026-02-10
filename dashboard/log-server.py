#!/usr/bin/env python3
"""Log server for SkynetPi Dashboard - with status tweets"""
import http.server
import json
import glob
import os

PORT = 8765
LOG_DIR = "/tmp/openclaw"
KVM_LOG = "/tmp/kvm-events.json"
STATUS_LOG = "/tmp/skynetpi-status.json"

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

def get_openclaw_events(limit=10):
    """Read events from OpenClaw logs"""
    log_files = sorted(glob.glob(f"{LOG_DIR}/openclaw-*.log"), reverse=True)
    if not log_files:
        return []
    
    events = []
    seen_times = set()
    
    with open(log_files[0], 'rb') as f:
        f.seek(0, 2)
        size = f.tell()
        f.seek(max(0, size - 10000))
        content = f.read().decode('utf-8', errors='ignore')
    
    for line in content.split('\n'):
        if not line.strip():
            continue
        try:
            data = json.loads(line)
            time = data.get('time', '')
            if time in seen_times:
                continue
            
            msg = str(data.get('1', ''))
            event = None
            
            if 'tool start' in msg:
                tool = msg.split('tool=')[-1].split()[0] if 'tool=' in msg else ''
                
                if tool == 'web_search':
                    event = {'type': 'tool', 'icon': '🔍', 'text': 'Pesquisando', 'time': time}
                elif tool == 'web_fetch':
                    event = {'type': 'tool', 'icon': '🌐', 'text': 'Acessando página', 'time': time}
                elif tool == 'Read':
                    event = {'type': 'tool', 'icon': '📖', 'text': 'Lendo arquivo', 'time': time}
                elif tool == 'Write':
                    event = {'type': 'tool', 'icon': '✍️', 'text': 'Escrevendo', 'time': time}
                elif tool == 'Edit':
                    event = {'type': 'tool', 'icon': '📝', 'text': 'Editando', 'time': time}
                elif tool == 'message':
                    event = {'type': 'tool', 'icon': '📤', 'text': 'Enviando msg', 'time': time}
                elif tool == 'image':
                    event = {'type': 'kvm', 'icon': '👁️', 'text': 'Analisando imagem', 'time': time}
            
            elif 'inbound message' in msg:
                event = {'type': 'message', 'icon': '📥', 'text': 'Mensagem recebida', 'time': time}
            
            elif 'auto-reply sent' in msg:
                event = {'type': 'reply', 'icon': '✅', 'text': 'Respondido', 'time': time}
            
            if event:
                seen_times.add(time)
                events.append(event)
                
        except json.JSONDecodeError:
            continue
    
    return events[-limit:]

def get_all_events():
    """Combine all events, sorted by time"""
    tweets = get_status_tweets()
    kvm = get_kvm_events()
    openclaw = get_openclaw_events()
    
    all_events = tweets + kvm + openclaw
    all_events.sort(key=lambda x: x.get('time', ''))
    
    return all_events[-25:]

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
