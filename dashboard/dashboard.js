// SkynetPi Dashboard - OpenClaw Monitor v3
const LOG_SERVER = 'http://127.0.0.1:8765';
const MAX_LOG_ENTRIES = 25;

let messageCount = 0;
let startTime = Date.now();
let lastEventTime = '';
let isConnected = false;

// DOM elements
const elements = {
  statusDot: document.getElementById('status-dot'),
  clock: document.getElementById('clock'),
  actionIcon: document.getElementById('action-icon'),
  actionText: document.getElementById('action-text'),
  session: document.getElementById('session'),
  channel: document.getElementById('channel'),
  log: document.getElementById('log'),
  uptime: document.getElementById('uptime'),
  messages: document.getElementById('messages')
};

// Update clock
function updateClock() {
  const now = new Date();
  elements.clock.textContent = now.toLocaleTimeString('pt-BR', { 
    hour: '2-digit', 
    minute: '2-digit' 
  });
}
setInterval(updateClock, 1000);
updateClock();

// Update uptime
function updateUptime() {
  const elapsed = Math.floor((Date.now() - startTime) / 1000);
  const mins = Math.floor(elapsed / 60);
  const hours = Math.floor(mins / 60);
  if (hours > 0) {
    elements.uptime.textContent = `⏱️ ${hours}h${mins % 60}m`;
  } else {
    elements.uptime.textContent = `⏱️ ${mins}m`;
  }
}
setInterval(updateUptime, 10000);
updateUptime();

// Add log entry
function addLog(icon, text, time, type = 'action') {
  const entry = document.createElement('div');
  entry.className = `log-entry ${type}`;
  
  let timeStr = '';
  if (time) {
    const d = new Date(time);
    timeStr = d.toLocaleTimeString('pt-BR', { 
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    });
  }
  
  entry.innerHTML = `<span class="time">${timeStr}</span>${icon} ${escapeHtml(text)}`;
  elements.log.appendChild(entry);
  
  while (elements.log.children.length > MAX_LOG_ENTRIES) {
    elements.log.removeChild(elements.log.firstChild);
  }
  
  elements.log.scrollTop = elements.log.scrollHeight;
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Set current action
function setAction(icon, text) {
  elements.actionIcon.textContent = icon;
  elements.actionText.textContent = text;
}

// Set status
function setStatus(status) {
  elements.statusDot.className = 'status-dot ' + status;
}

// Tool display names
const TOOL_NAMES = {
  'web_search': 'Pesquisando web',
  'web_fetch': 'Acessando página',
  'browser': 'Navegador',
  'exec': 'Executando comando',
  'read': 'Lendo arquivo',
  'write': 'Escrevendo arquivo',
  'edit': 'Editando arquivo',
  'message': 'Enviando mensagem',
  'image': 'Analisando imagem',
  'tts': 'Gerando áudio',
  'memory_search': 'Buscando memória',
  'cron': 'Agendamento',
  'process': 'Processo',
};

// Fetch events from log server
async function fetchEvents() {
  try {
    const response = await fetch(LOG_SERVER);
    if (!response.ok) throw new Error('Server error');
    
    const data = await response.json();
    
    if (!isConnected) {
      isConnected = true;
      setStatus('');
      elements.session.textContent = 'main';
      elements.channel.textContent = 'WhatsApp';
    }
    
    if (data.events && data.events.length > 0) {
      // Process new events (only those after lastEventTime)
      for (const event of data.events) {
        if (event.time && event.time > lastEventTime) {
          lastEventTime = event.time;
          
          // Update current action display
          if (event.type === 'tweet') {
            // Status tweet - truncate to 3 lines (~90 chars)
            let text = event.text;
            if (text.length > 90) text = text.substring(0, 87) + '...';
            setAction('💭', text.substring(0, 30) + (text.length > 30 ? '...' : ''));
            setStatus('busy');
            addLog(event.icon, text, event.time, 'tweet');
          } else if (event.type === 'kvm') {
            setAction(event.icon, event.text);
            setStatus('busy');
            addLog(event.icon, event.text, event.time, 'kvm');
          } else if (event.type === 'tool') {
            const toolName = TOOL_NAMES[event.text.toLowerCase()] || event.text;
            setAction('⚡', toolName + '...');
            setStatus('busy');
            addLog('⚡', toolName, event.time);
          } else if (event.type === 'message') {
            messageCount++;
            elements.messages.textContent = `💬 ${messageCount}`;
            setAction('📥', 'Mensagem recebida');
            setStatus('busy');
            addLog('📥', 'Mensagem recebida', event.time);
          } else if (event.type === 'reply') {
            setAction('✅', 'Resposta enviada');
            setStatus('');
            addLog('✅', 'Resposta enviada', event.time);
          } else if (event.type === 'thinking') {
            setAction('🤔', 'Processando...');
            setStatus('busy');
          }
        }
      }
    }
    
  } catch (err) {
    if (isConnected) {
      isConnected = false;
      setStatus('disconnected');
      setAction('🔄', 'Reconectando...');
    }
  }
}

// Initialize
function init() {
  setAction('🤖', 'Iniciando...');
  setStatus('');
  elements.session.textContent = 'main';
  elements.channel.textContent = 'WhatsApp';
  
  // Poll every 1 second
  setInterval(fetchEvents, 1000);
  fetchEvents();
  
  // Initial status after 2s
  setTimeout(() => {
    if (elements.actionText.textContent === 'Iniciando...') {
      setAction('🤖', 'Online');
    }
  }, 2000);
}

window.addEventListener('load', init);

// Touch to refresh
document.body.addEventListener('click', fetchEvents);
