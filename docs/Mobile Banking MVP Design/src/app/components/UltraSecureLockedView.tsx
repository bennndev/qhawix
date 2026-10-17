import React from 'react';
import { motion } from 'motion/react';
import { Lock, Eye, Shield, Clock, Fingerprint } from 'lucide-react';
import { OwlIcon } from './OwlIcon';

interface UltraSecureLockedViewProps {
  onUnlock: () => void;
  userName: string;
  endTime: string;
}

export const UltraSecureLockedView: React.FC<UltraSecureLockedViewProps> = ({
  onUnlock,
  userName,
  endTime,
}) => {
  const [showProtectedBalance, setShowProtectedBalance] = React.useState(false);
  const [currentTime, setCurrentTime] = React.useState(new Date());

  React.useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const timeUntilEnd = () => {
    const now = currentTime;
    const [endHour, endMinute] = endTime.split(':').map(Number);
    const end = new Date();
    end.setHours(endHour, endMinute, 0, 0);
    
    if (end < now) {
      end.setDate(end.getDate() + 1);
    }
    
    const diff = end.getTime() - now.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    return { hours, minutes };
  };

  const { hours, minutes } = timeUntilEnd();

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#1a0b2e] via-[#2d1b4e] to-[#1a0b2e] overflow-y-auto pb-20">
      {/* Animated Background */}
      <div className="absolute inset-0 overflow-hidden">
        <motion.div
          className="absolute w-96 h-96 bg-purple-500/10 rounded-full blur-3xl"
          animate={{
            x: [0, 100, 0],
            y: [0, 50, 0],
          }}
          transition={{ duration: 20, repeat: Infinity }}
          style={{ top: '10%', left: '10%' }}
        />
        <motion.div
          className="absolute w-96 h-96 bg-indigo-500/10 rounded-full blur-3xl"
          animate={{
            x: [0, -100, 0],
            y: [0, -50, 0],
          }}
          transition={{ duration: 15, repeat: Infinity }}
          style={{ bottom: '10%', right: '10%' }}
        />
      </div>

      {/* Content */}
      <div className="relative z-10 px-6 pt-20">
        {/* Header */}
        <div className="text-center mb-8">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', duration: 0.6 }}
            className="inline-block mb-6"
          >
            <OwlIcon state="idle" size={80} />
          </motion.div>
          
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-white text-3xl mb-3"
          >
            Modo Ultra Seguro
          </motion.h1>
          
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-purple-200"
          >
            Hola, {userName}
          </motion.p>
        </div>

        {/* Lock Icon */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2 }}
          className="flex justify-center mb-8"
        >
          <div className="relative">
            <motion.div
              animate={{ rotate: [0, 5, -5, 0] }}
              transition={{ duration: 2, repeat: Infinity, repeatDelay: 3 }}
              className="w-24 h-24 bg-gradient-to-br from-purple-500 to-indigo-500 rounded-3xl flex items-center justify-center shadow-2xl"
            >
              <Lock className="text-white" size={48} />
            </motion.div>
            <motion.div
              className="absolute inset-0 bg-purple-400 rounded-3xl blur-xl"
              animate={{ opacity: [0.3, 0.6, 0.3] }}
              transition={{ duration: 2, repeat: Infinity }}
            />
          </div>
        </motion.div>

        {/* Status Message */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white/10 backdrop-blur-xl rounded-3xl p-6 border border-white/20 mb-6"
        >
          <div className="text-center mb-4">
            <p className="text-white text-lg mb-2">🔒 Tus datos están protegidos</p>
            <p className="text-purple-200 text-sm">
              El modo ultra seguro está activo según tu programación
            </p>
          </div>

          {/* Countdown */}
          <div className="bg-purple-500/20 rounded-2xl p-4 border border-purple-300/30">
            <div className="flex items-center justify-center gap-2 mb-2">
              <Clock className="text-purple-200" size={20} />
              <span className="text-purple-200 text-sm">Se desactivará en:</span>
            </div>
            <div className="flex items-center justify-center gap-4">
              <div className="text-center">
                <div className="text-white text-3xl font-mono tabular-nums">{String(hours).padStart(2, '0')}</div>
                <div className="text-purple-300 text-xs">horas</div>
              </div>
              <div className="text-white text-3xl">:</div>
              <div className="text-center">
                <div className="text-white text-3xl font-mono tabular-nums">{String(minutes).padStart(2, '0')}</div>
                <div className="text-purple-300 text-xs">minutos</div>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Protected Balance */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-white/10 backdrop-blur-xl rounded-3xl p-6 border border-white/20 mb-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-white">Consultar Saldo Protegido</h3>
            <button
              onClick={() => setShowProtectedBalance(!showProtectedBalance)}
              className={`w-12 h-12 rounded-xl flex items-center justify-center transition-colors ${
                showProtectedBalance ? 'bg-purple-500' : 'bg-white/20'
              }`}
            >
              <Eye className="text-white" size={20} />
            </button>
          </div>

          {showProtectedBalance ? (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="bg-purple-500/20 rounded-2xl p-4 border border-purple-300/30"
            >
              <p className="text-purple-200 text-sm mb-2">Saldo disponible</p>
              <p className="text-white text-2xl" style={{ filter: 'blur(4px)' }}>
                S/ •••••.••
              </p>
              <p className="text-purple-300 text-xs mt-3">
                Los montos están ocultos por seguridad
              </p>
            </motion.div>
          ) : (
            <div className="text-center py-4">
              <Shield className="text-purple-300 mx-auto mb-2" size={32} />
              <p className="text-purple-200 text-sm">
                Toca el ícono para ver saldo oculto
              </p>
            </div>
          )}
        </motion.div>

        {/* Restricted Transactions */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-white/10 backdrop-blur-xl rounded-3xl p-6 border border-white/20 mb-6"
        >
          <h3 className="text-white mb-4">Actividad Reciente</h3>
          <div className="space-y-3">
            {[1, 2, 3].map((_, index) => (
              <div
                key={index}
                className="bg-white/5 rounded-2xl p-4 border border-white/10"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-white text-sm mb-1">Empresa protegida</p>
                    <p className="text-purple-300 text-xs">
                      {new Date(Date.now() - index * 24 * 60 * 60 * 1000).toLocaleDateString('es-PE', {
                        day: '2-digit',
                        month: 'short',
                      })}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-white" style={{ filter: 'blur(4px)' }}>
                      -S/ •••.••
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Active Restrictions */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="bg-gradient-to-r from-red-500/20 to-orange-500/20 backdrop-blur-xl rounded-3xl p-6 border border-red-300/30 mb-6"
        >
          <h3 className="text-white mb-3">Restricciones Activas</h3>
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-red-400 rounded-full" />
              <p className="text-red-200 text-sm">Transferencias bloqueadas</p>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-red-400 rounded-full" />
              <p className="text-red-200 text-sm">Datos sensibles ocultos</p>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-red-400 rounded-full" />
              <p className="text-red-200 text-sm">Nombres de empresas reemplazados</p>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-red-400 rounded-full" />
              <p className="text-red-200 text-sm">Modificaciones de configuración deshabilitadas</p>
            </div>
          </div>
        </motion.div>

        {/* Unlock Button */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.7 }}
        >
          <button
            onClick={onUnlock}
            className="w-full bg-gradient-to-r from-purple-500 to-indigo-500 rounded-2xl p-4 flex items-center justify-center gap-3 shadow-xl"
          >
            <Fingerprint className="text-white" size={24} />
            <div className="text-left">
              <p className="text-white">Desactivar Modo Ultra Seguro</p>
              <p className="text-purple-200 text-xs">Requiere autenticación biométrica</p>
            </div>
          </button>
        </motion.div>

        {/* AURA Message */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="mt-6 bg-gradient-to-r from-cyan-500/20 to-blue-500/20 backdrop-blur-xl rounded-3xl p-4 border border-cyan-300/30"
        >
          <div className="flex items-start gap-3">
            <OwlIcon state="idle" size={32} />
            <div>
              <p className="text-white text-sm mb-1">AURA Guardian</p>
              <p className="text-cyan-200 text-xs">
                Tus datos financieros están completamente protegidos durante el horario nocturno. 
                Solo puedes consultar información básica. Para acceso completo, desactiva el modo 
                con tu huella digital o espera hasta las {endTime}.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};
