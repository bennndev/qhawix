import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, Send, Mic } from 'lucide-react';
import { OwlIcon } from './OwlIcon';

interface Message {
  id: string;
  type: 'aura' | 'user';
  content: string;
  timestamp: Date;
  actions?: Array<{ label: string; action: string }>;
}

interface AuraChatProps {
  isOpen: boolean;
  onClose: () => void;
  onVoiceMode: () => void;
  userName: string;
  context?: 'dashboard' | 'transfer' | 'security' | 'alert';
}

export const AuraChat: React.FC<AuraChatProps> = ({ 
  isOpen, 
  onClose, 
  onVoiceMode, 
  userName,
  context = 'dashboard' 
}) => {
  const [messages, setMessages] = React.useState<Message[]>([]);
  const [inputValue, setInputValue] = React.useState('');
  const messagesEndRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    // Initialize with context-appropriate greeting
    const greeting = getContextualGreeting();
    if (messages.length === 0 && greeting) {
      setMessages([greeting]);
    }
  }, [context]);

  React.useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const getContextualGreeting = (): Message | null => {
    const baseGreeting = {
      id: '1',
      type: 'aura' as const,
      timestamp: new Date(),
    };

    switch (context) {
      case 'dashboard':
        return {
          ...baseGreeting,
          content: `¡Hola ${userName}! 👋 Tu saldo está protegido. ¿En qué puedo ayudarte hoy?`,
          actions: [
            { label: 'Ver sugerencias', action: 'suggestions' },
            { label: 'Estado de seguridad', action: 'security' },
          ],
        };
      case 'transfer':
        return {
          ...baseGreeting,
          content: 'Estoy monitoreando esta transferencia para garantizar tu seguridad. ¿Necesitas ayuda?',
          actions: [
            { label: 'Verificar destinatario', action: 'verify' },
            { label: 'Cambiar monto', action: 'amount' },
          ],
        };
      case 'security':
        return {
          ...baseGreeting,
          content: 'Tu puntuación de seguridad es 98/100. ¿Quieres que revise algún aspecto específico?',
          actions: [
            { label: 'Revisar alertas', action: 'alerts' },
            { label: 'Configurar zona segura', action: 'zones' },
          ],
        };
      case 'alert':
        return {
          ...baseGreeting,
          content: '⚠️ Detecté actividad inusual. ¿Autorizaste esta operación?',
          actions: [
            { label: 'Sí, fui yo', action: 'confirm' },
            { label: 'No, bloquear', action: 'block' },
          ],
        };
      default:
        return null;
    }
  };

  const handleSend = () => {
    if (!inputValue.trim()) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      type: 'user',
      content: inputValue,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInputValue('');

    // Simulate AURA response
    setTimeout(() => {
      const response = generateAuraResponse(inputValue);
      setMessages((prev) => [...prev, response]);
    }, 800);
  };

  const generateAuraResponse = (input: string): Message => {
    const lowerInput = input.toLowerCase();
    
    let content = '';
    let actions: Array<{ label: string; action: string }> = [];

    if (lowerInput.includes('saldo') || lowerInput.includes('balance')) {
      content = 'Tu saldo actual es S/ 15,432.75. Detecté que supera tu umbral de seguridad. ¿Deseas transferir el excedente?';
      actions = [
        { label: 'Configurar transferencia', action: 'transfer' },
        { label: 'Ajustar umbral', action: 'threshold' },
      ];
    } else if (lowerInput.includes('transferir') || lowerInput.includes('enviar')) {
      content = 'Puedo ayudarte con la transferencia. ¿A quién deseas enviar dinero?';
      actions = [
        { label: 'Contacto guardado', action: 'saved' },
        { label: 'Nueva cuenta', action: 'new' },
      ];
    } else if (lowerInput.includes('segur') || lowerInput.includes('protec')) {
      content = 'Tu cuenta tiene 5 capas de protección activas. El modo ultra seguro se activará automáticamente a las 23:00.';
      actions = [
        { label: 'Ver configuración', action: 'config' },
        { label: 'Activar ahora', action: 'activate' },
      ];
    } else if (lowerInput.includes('alert') || lowerInput.includes('notif')) {
      content = 'No tienes alertas pendientes. Estoy monitoreando tu cuenta 24/7 desde ubicaciones de confianza.';
      actions = [
        { label: 'Ver historial', action: 'history' },
      ];
    } else {
      content = 'Entiendo. ¿Hay algo más en lo que pueda ayudarte?';
      actions = [
        { label: 'Ver saldo', action: 'balance' },
        { label: 'Configurar seguridad', action: 'security' },
      ];
    }

    return {
      id: Date.now().toString(),
      type: 'aura',
      content,
      timestamp: new Date(),
      actions,
    };
  };

  const handleAction = (action: string) => {
    console.log('AURA action triggered:', action);
    // In real app, this would trigger navigation or specific actions
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0, y: 20, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: 20, scale: 0.95 }}
          className="fixed inset-x-6 bottom-24 bg-white rounded-3xl shadow-2xl border-2 border-cyan-200 overflow-hidden z-40 max-w-[358px] mx-auto"
          style={{ maxHeight: '70vh' }}
        >
          {/* Header */}
          <div className="bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] p-4 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <OwlIcon state="listening" size={32} />
              <div>
                <h3 className="text-white">AURA</h3>
                <p className="text-cyan-100 text-xs">Asistente Inteligente</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <motion.button
                onClick={onVoiceMode}
                className="w-9 h-9 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
                whileTap={{ scale: 0.95 }}
              >
                <Mic className="text-white" size={18} />
              </motion.button>
              <motion.button
                onClick={onClose}
                className="w-9 h-9 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
                whileTap={{ scale: 0.95 }}
              >
                <X className="text-white" size={18} />
              </motion.button>
            </div>
          </div>

          {/* Messages */}
          <div className="p-4 overflow-y-auto" style={{ maxHeight: 'calc(70vh - 140px)' }}>
            <div className="space-y-3">
              {messages.map((message) => (
                <div
                  key={message.id}
                  className={`flex ${message.type === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  <div
                    className={`max-w-[85%] ${
                      message.type === 'user'
                        ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white'
                        : 'bg-gray-100 text-gray-900'
                    } rounded-2xl px-4 py-3`}
                  >
                    <p className="text-sm">{message.content}</p>
                    
                    {message.actions && message.actions.length > 0 && (
                      <div className="flex flex-wrap gap-2 mt-3">
                        {message.actions.map((action, idx) => (
                          <button
                            key={idx}
                            onClick={() => handleAction(action.action)}
                            className="px-3 py-1.5 bg-white/20 hover:bg-white/30 rounded-lg text-xs transition-colors backdrop-blur-sm border border-white/30"
                          >
                            {action.label}
                          </button>
                        ))}
                      </div>
                    )}
                    
                    <p className="text-xs opacity-60 mt-2">
                      {message.timestamp.toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' })}
                    </p>
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
          </div>

          {/* Input */}
          <div className="p-4 border-t border-gray-200 bg-white">
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleSend()}
                placeholder="Escribe tu pregunta..."
                className="flex-1 px-4 py-2 bg-gray-100 rounded-full border-0 focus:outline-none focus:ring-2 focus:ring-cyan-300 text-sm"
              />
              <motion.button
                onClick={handleSend}
                className="w-10 h-10 bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] rounded-full flex items-center justify-center"
                whileTap={{ scale: 0.95 }}
              >
                <Send className="text-white" size={18} />
              </motion.button>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};
