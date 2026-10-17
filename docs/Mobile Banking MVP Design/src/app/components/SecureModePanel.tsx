import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, Moon, Clock, MapPin, Volume2, Shield, FileText, ChevronRight } from 'lucide-react';

interface SecureModePanelProps {
  isOpen: boolean;
  onClose: () => void;
  ultraSecureMode: boolean;
  onToggleUltraSecure: () => void;
  onNavigateToConfig: (module: string) => void;
}

export const SecureModePanel: React.FC<SecureModePanelProps> = ({
  isOpen,
  onClose,
  ultraSecureMode,
  onToggleUltraSecure,
  onNavigateToConfig,
}) => {
  const [currentTime, setCurrentTime] = React.useState(new Date());

  React.useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const isNightTime = () => {
    const hour = currentTime.getHours();
    return hour >= 23 || hour < 6;
  };

  const quickActions = [
    {
      icon: Clock,
      label: 'Configurar Horario',
      description: 'Programar activación automática',
      action: 'ultra-secure',
      color: 'from-purple-500 to-indigo-500',
    },
    {
      icon: MapPin,
      label: 'Activar por Geolocalización',
      description: 'Protección basada en ubicación',
      action: 'geolocation',
      color: 'from-blue-500 to-cyan-500',
    },
    {
      icon: Volume2,
      label: 'Control por Voz',
      description: 'Comandos de voz para seguridad',
      action: 'voice-training',
      color: 'from-pink-500 to-rose-500',
    },
    {
      icon: FileText,
      label: 'Política de Privacidad',
      description: 'Ver términos y condiciones',
      action: 'legal-compliance',
      color: 'from-gray-500 to-gray-600',
    },
  ];

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40"
          />

          {/* Panel */}
          <motion.div
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed right-0 top-0 bottom-0 w-full max-w-[390px] bg-gradient-to-br from-[#0033CC] to-[#001A66] z-50 overflow-y-auto"
          >
            {/* Header */}
            <div className="pt-12 pb-6 px-6">
              <div className="flex items-center justify-between mb-2">
                <h2 className="text-white text-2xl">Modo Seguro</h2>
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={onClose}
                  className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
                >
                  <X className="text-white" size={20} />
                </motion.button>
              </div>
              <p className="text-cyan-200 text-sm">
                Gestión de protección automática
              </p>
            </div>

            {/* Main Toggle */}
            <div className="px-6 mb-6">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-white/10 backdrop-blur-xl rounded-3xl p-6 border border-white/20"
              >
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className={`w-14 h-14 rounded-2xl flex items-center justify-center ${
                      ultraSecureMode ? 'bg-purple-500' : 'bg-white/20'
                    }`}>
                      <Moon className="text-white" size={28} />
                    </div>
                    <div>
                      <p className="text-white text-lg">
                        Modo Ultra Seguro
                      </p>
                      <p className="text-cyan-200 text-xs">
                        {ultraSecureMode ? 'Activo ahora' : 'Desactivado'}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={onToggleUltraSecure}
                    className={`w-16 h-9 rounded-full transition-colors relative ${
                      ultraSecureMode ? 'bg-purple-500' : 'bg-white/30'
                    }`}
                  >
                    <motion.div
                      className="w-7 h-7 bg-white rounded-full absolute top-1 shadow-lg"
                      animate={{ left: ultraSecureMode ? '32px' : '4px' }}
                      transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                    />
                  </button>
                </div>

                {ultraSecureMode && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    className="bg-purple-500/20 rounded-2xl p-3 border border-purple-300/30"
                  >
                    <p className="text-white text-xs text-center">
                      🔒 Todos tus datos están protegidos y ocultos
                    </p>
                  </motion.div>
                )}

                {isNightTime() && !ultraSecureMode && (
                  <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    className="bg-yellow-500/20 rounded-2xl p-3 border border-yellow-300/30 mt-3"
                  >
                    <p className="text-yellow-200 text-xs text-center">
                      🌙 Es horario nocturno. Considera activar el modo seguro.
                    </p>
                  </motion.div>
                )}
              </motion.div>
            </div>

            {/* Status Info */}
            {ultraSecureMode && (
              <div className="px-6 mb-6">
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.1 }}
                  className="bg-white/5 backdrop-blur-sm rounded-2xl p-4 border border-white/10"
                >
                  <h3 className="text-white text-sm mb-3">Estado de Protección</h3>
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                      <p className="text-cyan-200 text-xs">Saldos ocultos</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                      <p className="text-cyan-200 text-xs">Transferencias bloqueadas</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                      <p className="text-cyan-200 text-xs">Nombres de empresas reemplazados</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                      <p className="text-cyan-200 text-xs">Datos sensibles protegidos</p>
                    </div>
                  </div>
                </motion.div>
              </div>
            )}

            {/* Quick Actions */}
            <div className="px-6 mb-6">
              <h3 className="text-white text-sm mb-3">Configuración Rápida</h3>
              <div className="space-y-3">
                {quickActions.map((action, index) => (
                  <motion.button
                    key={action.action}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.1 + index * 0.05 }}
                    onClick={() => {
                      onNavigateToConfig(action.action);
                      onClose();
                    }}
                    className="w-full bg-white/10 backdrop-blur-sm rounded-2xl p-4 border border-white/20 hover:bg-white/15 transition-all flex items-center gap-3 group"
                  >
                    <div className={`w-12 h-12 bg-gradient-to-br ${action.color} rounded-xl flex items-center justify-center`}>
                      <action.icon className="text-white" size={20} />
                    </div>
                    <div className="flex-1 text-left">
                      <p className="text-white text-sm mb-0.5">{action.label}</p>
                      <p className="text-cyan-200 text-xs">{action.description}</p>
                    </div>
                    <ChevronRight className="text-cyan-200 group-hover:translate-x-1 transition-transform" size={18} />
                  </motion.button>
                ))}
              </div>
            </div>

            {/* Deactivation Instructions */}
            {ultraSecureMode && (
              <div className="px-6 mb-6">
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                  className="bg-gradient-to-br from-orange-500/20 to-red-500/20 rounded-2xl p-4 border border-orange-300/30"
                >
                  <div className="flex items-start gap-3">
                    <Shield className="text-orange-300 flex-shrink-0 mt-1" size={20} />
                    <div>
                      <p className="text-white text-sm mb-2">Para Desactivar:</p>
                      <div className="space-y-1">
                        <p className="text-orange-200 text-xs">
                          1. Usa el comando de voz: <span className="font-semibold">"Desactivar modo ultra seguro"</span>
                        </p>
                        <p className="text-orange-200 text-xs">
                          2. Confirma con tu huella digital o rostro
                        </p>
                        <p className="text-orange-200 text-xs">
                          3. O espera hasta las 06:00 (desactivación automática)
                        </p>
                      </div>
                    </div>
                  </div>
                </motion.div>
              </div>
            )}

            {/* Time Display */}
            <div className="px-6 mb-6">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="bg-white/5 backdrop-blur-sm rounded-2xl p-4 text-center border border-white/10"
              >
                <p className="text-cyan-300 text-xs mb-2">Hora actual</p>
                <p className="text-white text-3xl font-mono tabular-nums">
                  {currentTime.toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' })}
                </p>
                {isNightTime() && (
                  <p className="text-yellow-300 text-xs mt-2">
                    🌙 Horario nocturno (23:00 - 06:00)
                  </p>
                )}
              </motion.div>
            </div>

            {/* Info Footer */}
            <div className="px-6 pb-12">
              <div className="bg-cyan-500/10 rounded-2xl p-4 border border-cyan-300/30">
                <p className="text-cyan-200 text-xs text-center">
                  💡 El Modo Ultra Seguro protege automáticamente tus datos durante 
                  horarios de alto riesgo. Configúralo según tus necesidades.
                </p>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
