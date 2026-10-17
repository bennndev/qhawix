import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Moon, Clock, Volume2, Shield, Eye, Ban, Lock } from 'lucide-react';

interface UltraSecureModeProps {
  onBack: () => void;
  isActive: boolean;
  onToggle: (active: boolean) => void;
}

export const UltraSecureMode: React.FC<UltraSecureModeProps> = ({ onBack, isActive, onToggle }) => {
  const [scheduleEnabled, setScheduleEnabled] = React.useState(true);
  const [startTime, setStartTime] = React.useState('23:00');
  const [endTime, setEndTime] = React.useState('06:00');
  const [voiceActivation, setVoiceActivation] = React.useState(true);
  const [currentTime, setCurrentTime] = React.useState(new Date());

  React.useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Check if current time is within ultra secure schedule
  const isInSchedule = () => {
    const now = currentTime;
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    const currentTimeMinutes = currentHour * 60 + currentMinute;

    const [startHour, startMinute] = startTime.split(':').map(Number);
    const [endHour, endMinute] = endTime.split(':').map(Number);
    
    const startMinutes = startHour * 60 + startMinute;
    const endMinutes = endHour * 60 + endMinute;

    // Handle overnight schedules (e.g., 23:00 to 06:00)
    if (startMinutes > endMinutes) {
      return currentTimeMinutes >= startMinutes || currentTimeMinutes < endMinutes;
    }
    return currentTimeMinutes >= startMinutes && currentTimeMinutes < endMinutes;
  };

  const timeUntilEnd = () => {
    const now = currentTime;
    const [endHour, endMinute] = endTime.split(':').map(Number);
    const end = new Date();
    end.setHours(endHour, endMinute, 0, 0);
    
    // If end time is tomorrow
    if (end < now) {
      end.setDate(end.getDate() + 1);
    }
    
    const diff = end.getTime() - now.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    return `${hours}h ${minutes}m`;
  };

  const restrictions = [
    { icon: Ban, label: 'Sin Transferencias', description: 'Todas las transferencias bloqueadas' },
    { icon: Eye, label: 'Modo Solo Vista', description: 'Solo consulta de saldos e historial' },
    { icon: Shield, label: 'Monitoreo Mejorado', description: 'Todos los accesos registrados' },
    { icon: Lock, label: 'Datos Ocultos', description: 'Nombres de empresas reemplazados' },
  ];

  const autoActivated = scheduleEnabled && isInSchedule();

  return (
    <div className="min-h-screen bg-gray-50 overflow-y-auto pb-20">
      {/* Header */}
      <div className={`pt-12 pb-8 px-6 transition-colors ${
        isActive 
          ? 'bg-gradient-to-br from-purple-900 to-indigo-900' 
          : 'bg-gradient-to-br from-[#0033CC] to-[#001A66]'
      }`}>
        <div className="flex items-center gap-4 mb-6">
          <motion.button
            onClick={onBack}
            className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="text-white" size={20} />
          </motion.button>
          <div>
            <h1 className="text-white text-2xl">Modo Ultra Seguro</h1>
            <p className="text-cyan-200 text-sm">Modo nocturno y horarios personalizados</p>
          </div>
        </div>

        {/* Status Card */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className={`w-14 h-14 rounded-xl flex items-center justify-center ${
                isActive ? 'bg-purple-500' : 'bg-white/20'
              }`}>
                <Moon className="text-white" size={28} />
              </div>
              <div>
                <p className="text-white text-lg">
                  {isActive ? 'Modo Activo' : 'Modo Inactivo'}
                </p>
                <p className="text-cyan-200 text-sm">
                  {isActive ? 'Tu cuenta está protegida' : 'Toca para activar'}
                </p>
              </div>
            </div>
            <button
              onClick={() => onToggle(!isActive)}
              className={`w-16 h-9 rounded-full transition-colors relative ${
                isActive ? 'bg-purple-500' : 'bg-white/30'
              }`}
            >
              <motion.div
                className="w-7 h-7 bg-white rounded-full absolute top-1"
                animate={{ left: isActive ? '32px' : '4px' }}
                transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              />
            </button>
          </div>

          {isActive && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="bg-purple-500/30 rounded-xl p-3 border border-purple-300/30"
            >
              <p className="text-white text-xs text-center">
                🛡️ Todas las transacciones bloqueadas. Acceso solo lectura habilitado.
              </p>
              {autoActivated && (
                <p className="text-cyan-200 text-xs text-center mt-2">
                  ⏰ Activación automática · Desactiva en {timeUntilEnd()}
                </p>
              )}
            </motion.div>
          )}
        </motion.div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Auto Schedule Status */}
        {autoActivated && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-gradient-to-r from-purple-500 to-indigo-500 rounded-2xl p-4 text-white shadow-lg"
          >
            <div className="flex items-center gap-3 mb-2">
              <Moon className="text-white" size={24} />
              <div className="flex-1">
                <p className="text-white font-medium">Activación Automática</p>
                <p className="text-purple-100 text-sm">Horario nocturno 23:00 - 06:00</p>
              </div>
            </div>
            <div className="bg-white/20 rounded-xl p-3 backdrop-blur-sm">
              <p className="text-white text-xs">
                El modo ultra seguro se activó automáticamente según tu horario configurado.
                Tiempo restante: <span className="font-mono">{timeUntilEnd()}</span>
              </p>
            </div>
          </motion.div>
        )}

        {/* Schedule Configuration */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
                <Clock className="text-blue-600" size={20} />
              </div>
              <div>
                <h3 className="text-gray-900">Programación Automática</h3>
                <p className="text-gray-600 text-sm">Activar según horario</p>
              </div>
            </div>
            <button
              onClick={() => setScheduleEnabled(!scheduleEnabled)}
              className={`w-14 h-8 rounded-full transition-colors relative ${
                scheduleEnabled ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
              }`}
            >
              <motion.div
                className="w-6 h-6 bg-white rounded-full absolute top-1"
                animate={{ left: scheduleEnabled ? '28px' : '4px' }}
                transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              />
            </button>
          </div>

          {scheduleEnabled && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="space-y-4 mt-4"
            >
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-gray-700 text-sm mb-2 block">Hora de Inicio</label>
                  <input
                    type="time"
                    value={startTime}
                    onChange={(e) => setStartTime(e.target.value)}
                    className="w-full px-4 py-3 bg-gray-50 rounded-xl border border-gray-200 focus:border-[#0033CC] focus:outline-none"
                  />
                </div>
                <div>
                  <label className="text-gray-700 text-sm mb-2 block">Hora de Fin</label>
                  <input
                    type="time"
                    value={endTime}
                    onChange={(e) => setEndTime(e.target.value)}
                    className="w-full px-4 py-3 bg-gray-50 rounded-xl border border-gray-200 focus:border-[#0033CC] focus:outline-none"
                  />
                </div>
              </div>
              <div className="bg-blue-50 rounded-xl p-3 border border-blue-200">
                <p className="text-blue-900 text-xs">
                  El modo se activará automáticamente todos los días de {startTime} a {endTime}
                </p>
              </div>
            </motion.div>
          )}
        </motion.div>

        {/* Voice Activation */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-purple-100 rounded-xl flex items-center justify-center">
                <Volume2 className="text-purple-600" size={20} />
              </div>
              <div>
                <h3 className="text-gray-900">Activación por Voz</h3>
                <p className="text-gray-600 text-sm">Habilitar comando de voz</p>
              </div>
            </div>
            <button
              onClick={() => setVoiceActivation(!voiceActivation)}
              className={`w-14 h-8 rounded-full transition-colors relative ${
                voiceActivation ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
              }`}
            >
              <motion.div
                className="w-6 h-6 bg-white rounded-full absolute top-1"
                animate={{ left: voiceActivation ? '28px' : '4px' }}
                transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              />
            </button>
          </div>

          {voiceActivation && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="bg-purple-50 rounded-xl p-4 border border-purple-200"
            >
              <p className="text-purple-900 text-sm mb-2">Frase de Activación:</p>
              <p className="text-purple-700 text-xs mb-3">\"Activar modo ultra seguro\"</p>
              <p className="text-purple-900 text-sm mb-2">Frase de Desactivación:</p>
              <p className="text-purple-700 text-xs">\"Desactivar modo ultra seguro\"</p>
              <div className="mt-3 pt-3 border-t border-purple-200">
                <p className="text-purple-600 text-xs">
                  ℹ️ Requiere autenticación biométrica (huella o rostro) para desactivar
                </p>
              </div>
            </motion.div>
          )}
        </motion.div>

        {/* Active Restrictions */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Cuando Está Activo</h3>
          <div className="space-y-3">
            {restrictions.map((restriction, index) => (
              <div key={index} className="flex items-start gap-3 pb-3 border-b border-gray-100 last:border-0 last:pb-0">
                <div className="w-10 h-10 bg-red-50 rounded-xl flex items-center justify-center flex-shrink-0">
                  <restriction.icon className="text-red-600" size={18} />
                </div>
                <div>
                  <p className="text-gray-900 text-sm mb-0.5">{restriction.label}</p>
                  <p className="text-gray-600 text-xs">{restriction.description}</p>
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Data Hiding Examples */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.25 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Ocultamiento de Datos</h3>
          <div className="space-y-3">
            <div className="bg-gray-50 rounded-xl p-4">
              <p className="text-gray-600 text-xs mb-2">Saldos de cuenta:</p>
              <div className="flex items-center gap-2">
                <span className="text-gray-900">S/ 15,432.75</span>
                <span className="text-gray-400">→</span>
                <span className="text-gray-900" style={{ filter: 'blur(8px)' }}>S/ 15,432.75</span>
              </div>
            </div>
            <div className="bg-gray-50 rounded-xl p-4">
              <p className="text-gray-600 text-xs mb-2">Nombres de empresas:</p>
              <div className="flex items-center gap-2">
                <span className="text-gray-900 text-sm">Spotify Premium</span>
                <span className="text-gray-400">→</span>
                <span className="text-gray-900 text-sm">Empresa protegida</span>
              </div>
            </div>
            <div className="bg-gray-50 rounded-xl p-4">
              <p className="text-gray-600 text-xs mb-2">Números de tarjeta:</p>
              <div className="flex items-center gap-2">
                <span className="text-gray-900 text-sm font-mono">•••• •••• •••• 9010</span>
                <span className="text-gray-400">→</span>
                <span className="text-gray-900 text-sm font-mono">•••• •••• •••• ••••</span>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Alert Settings */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-gradient-to-r from-orange-50 to-red-50 rounded-2xl p-4 border border-orange-200"
        >
          <h3 className="text-orange-900 text-sm mb-2">Alertas de Violación</h3>
          <p className="text-orange-700 text-xs mb-3">
            Recibirás notificaciones inmediatas si alguien intenta:
          </p>
          <div className="space-y-1">
            <p className="text-orange-700 text-xs">• Realizar una transferencia durante el período activo</p>
            <p className="text-orange-700 text-xs">• Iniciar sesión desde un dispositivo desconocido</p>
            <p className="text-orange-700 text-xs">• Acceder desde una ubicación inusual</p>
            <p className="text-orange-700 text-xs">• Modificar configuraciones de seguridad</p>
          </div>
        </motion.div>

        {/* Geolocation Trigger */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.35 }}
          className="bg-gradient-to-r from-green-50 to-emerald-50 rounded-2xl p-4 border border-green-200"
        >
          <h3 className="text-green-900 text-sm mb-2">Activación por Ubicación</h3>
          <p className="text-green-700 text-xs mb-3">
            El modo ultra seguro puede activarse automáticamente cuando:
          </p>
          <div className="space-y-1">
            <p className="text-green-700 text-xs">• Sales de tus zonas de confianza configuradas</p>
            <p className="text-green-700 text-xs">• Te conectas a una red WiFi pública</p>
            <p className="text-green-700 text-xs">• Se detecta una ubicación de alto riesgo</p>
          </div>
        </motion.div>
      </div>
    </div>
  );
};
