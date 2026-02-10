#!/usr/bin/env python3
"""Simple log server for SkynetPi Dashboard - with KVM events"""
import http.server
import json
import glob
import os

PORT = 8765
LOG_DIR = "/tmp/openclaw"
KVM_LOG = "/tmp/kvm-events.json"

def get_kvm_events():
    """Read KVM events from dedicated log"""
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
                result.append({
                    'type': 'kvm',
                    'icon': '⌨️',
                    'text': detail,
                    'time': e.get('time', '')
                })
            elif action == 'mouse':
                result.append({
                    'type': 'kvm',
                    'icon': '🖱️',
                    'text': detail,
                    'time': e.get('time', '')
                })
            elif action == 'screen':
                result.append({
                    'type': 'kvm',
                    'icon': '📸',
                    'text': detail,
                    'time': e.get('time', '')
                })
            elif action == 'vision':
                result.append({
                    'type': 'kvm',
                    'icon': '👁️',
                    'text': detail,
                    'time': e.get('time', '')
                })
        return result
    except:
        return []

def get_openclaw_events(limit=15):
    """Read events from OpenClaw logs"""
    log_files = sorted(glob.glob(f"{LOG_DIR}/openclaw-*.log"), reverse=True)
    if not log_files:
        return []
    
    events = []
    seen_times = set()
    
    with open(log_files[0], 'rb') as f:
        f.seek(0, 2)
        size = f.tell()
        f.seek(max(0, size - 12000))
        content = f.read().decode('utf-8', errors='ignore')
    
    for line in content.split('\n'):
        if not line.strip():
            continue
        try:
            data = json.loads(line)
            time = data.get('time', '')
            if time in seen_times:
                continue
            
            msg = str(data.get('1', '')) + ' ' + str(data.get('2', ''))
            event = None
            
            if 'tool start' in msg:
                tool = msg.split('tool=')[-1].split()[0] if 'tool=' in msg else ''
                
                if tool == 'web_search':
                    event = {'type': 'tool', 'icon': '🔍', 'text': 'Pesquisando web', 'time': time}
                elif tool == 'web_fetch':
                    event = {'type': 'tool', 'icon': '🌐', 'text': 'Acessando página', 'time': time}
                elif tool == 'Read':
                    event = {'type': 'tool', 'icon': '📖', 'text': 'Lendo arquivo', 'time': time}
                elif tool == 'Write':
                    event = {'type': 'tool', 'icon': '✍️', 'text': 'Escrevendo arquivo', 'time': time}
                elif tool == 'Edit':
                    event = {'type': 'tool', 'icon': '📝', 'text': 'Editando arquivo', 'time': time}
                elif tool == 'message':
                    event = {'type': 'tool', 'icon': '📤', 'text': 'Enviando mensagem', 'time': time}
                elif tool == 'image':
                    event = {'type': 'kvm', 'icon': '👁️', 'text': 'Analisando tela', 'time': time}
                elif tool == 'memory_search':
                    event = {'type': 'tool', 'icon': '🧠', 'text': 'Buscando memória', 'time': time}
                elif tool == 'tts':
                    event = {'type': 'tool', 'icon': '🔊', 'text': 'Gerando áudio', 'time': time}
                elif tool == 'exec':
                    event = {'type': 'tool', 'icon': '⚡', 'text': 'Executando', 'time': time}
                elif tool:
                    event = {'type': 'tool', 'icon': '🔧', 'text': tool, 'time': time}
            
            elif 'inbound message' in msg or 'web-inbound' in str(data.get('0', '')):
                event = {'type': 'message', 'icon': '📥', 'text': 'Mensagem recebida', 'time': time}
            
            elif 'auto-reply sent' in msg or 'Auto-replied' in msg:
                event = {'type': 'reply', 'icon': '✅', 'text': 'Resposta enviada', 'time': time}
            
            elif 'embedded run start' in msg:
                event = {'type': 'thinking', 'icon': '🤔', 'text': 'Pensando...', 'time': time}
            
            if event:
                seen_times.add(time)
                events.append(event)
                
        except json.JSONDecodeError:
            continue
    
    return events[-limit:]

def get_all_events():
    """Combine KVM and OpenClaw events, sorted by time"""
    kvm = get_kvm_events()
    openclaw = get_openclaw_events()
    
    all_events = kvm + openclaw
    # Sort by time
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
