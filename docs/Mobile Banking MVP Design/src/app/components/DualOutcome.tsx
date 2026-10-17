import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { CheckCircle, AlertTriangle, Eye, MapPin } from 'lucide-react';

interface DualOutcomeProps {
  userName: string;
  amount: number;
  recipient: string;
  voiceResult: 'normal' | 'stress';
  gestureResult: 'valid' | 'abnormal';
  onComplete: () => void;
}

export const DualOutcome: React.FC<DualOutcomeProps> = ({
  userName,
  amount,
  recipient,
  voiceResult,
  gestureResult,
  onComplete,
}) => {
  const [showBackendDemo, setShowBackendDemo] = React.useState(false);

  // Simulated backend data
  const backendData = {
    usuario: userName,
    evento: 'Anomalía de comportamiento',
    voz: voiceResult === 'stress' ? 'Estrés detectado' : 'Normal',
    gesto: gestureResult === 'abnormal' ? 'Irregular' : 'Normal',
    hora: new Date().toLocaleTimeString('es-PE', { hour: '2-digit', minute: '2-digit' }),
    gps: 'Arequipa, Perú',
    coordenadas: '-16.4090, -71.5375',
    dispositivo: 'iPhone 13 Pro',
    ip: '190.237.45.182',
    accion: 'Alerta enviada al agente',
    monto: amount,
    destinatario: recipient,
    timestamp: new Date().toISOString(),
  };

  // User sees success (fake)
  const UserView = () => (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.9 }}
      className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50 flex flex-col items-center justify-center px-6 py-12 overflow-y-auto"
    >
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
        className="w-32 h-32 bg-green-500 rounded-full flex items-center justify-center mb-8 shadow-2xl"
      >
        <CheckCircle className="text-white" size={64} />
      </motion.div>

      <motion.h2
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="text-gray-900 text-3xl mb-2 text-center"
      >
        Transferencia Completada
      </motion.h2>

      <motion.p
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="text-green-700 text-sm mb-8 text-center"
      >
        ✓ Tu operación se procesó exitosamente
      </motion.p>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="w-full max-w-sm bg-white rounded-3xl p-6 space-y-4 shadow-xl"
      >
        <div className="flex justify-between items-center pb-3 border-b border-gray-100">
          <span className="text-gray-500">Destinatario:</span>
          <span className="text-gray-900">{recipient}</span>
        </div>
        <div className="flex justify-between items-center pb-3 border-b border-gray-100">
          <span className="text-gray-500">Monto:</span>
          <span className="text-gray-900 text-xl">S/ {amount.toFixed(2)}</span>
        </div>
        <div className="flex justify-between items-center pb-3 border-b border-gray-100">
          <span className="text-gray-500">Estado:</span>
          <span className="text-green-600 flex items-center gap-2">
            <div className="w-2 h-2 bg-green-500 rounded-full" />
            Exitosa
          </span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-500">Referencia:</span>
          <span className="text-gray-900 font-mono text-sm">#TRX{Math.floor(Math.random() * 1000000)}</span>
        </div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
        className="mt-6 bg-green-100 rounded-2xl p-4 max-w-sm"
      >
        <p className="text-green-800 text-sm text-center">
          📱 Recibirás un SMS de confirmación en breve
        </p>
      </motion.div>

      {/* Backend Demo Button - Only in Phase 3 */}
      <motion.button
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1 }}
        onClick={() => setShowBackendDemo(true)}
        className="mt-8 px-6 py-3 bg-gradient-to-r from-[#0033CC] to-[#001A66] text-white rounded-2xl flex items-center gap-2 shadow-lg hover:shadow-xl transition-all"
      >
        <Eye size={20} />
        <span>Ver Backend Demo</span>
      </motion.button>

      <motion.button
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2 }}
        onClick={onComplete}
        className="mt-4 text-gray-600 underline"
      >
        Volver al inicio
      </motion.button>
    </motion.div>
  );

  // Backend Demo View - Shows what operator sees
  const BackendDemoView = () => (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="min-h-screen bg-gradient-to-br from-gray-900 via-red-950 to-black flex flex-col px-6 py-12 overflow-y-auto relative"
    >
      {/* Alert pulse */}
      <motion.div
        className="absolute top-8 right-8 w-4 h-4 bg-red-500 rounded-full"
        animate={{ scale: [1, 1.5, 1], opacity: [1, 0.5, 1] }}
        transition={{ duration: 1, repeat: Infinity }}
      />

      {/* Header */}
      <div className="text-center mb-8">
        <div className="flex items-center justify-center gap-3 mb-4">
          <AlertTriangle className="text-red-500" size={48} />
          <h2 className="text-white text-2xl">Backend Demo</h2>
        </div>
        <p className="text-red-300">Vista del Operador - Sistema de Alertas</p>
        <p className="text-gray-400 text-xs mt-2">
          (Solo para demostración - En producción, solo operadores autorizados ven esto)
        </p>
      </div>

      {/* Main Alert Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-red-900/20 backdrop-blur-sm rounded-3xl p-6 border-2 border-red-500 mb-6"
      >
        <div className="flex items-center gap-3 mb-6 pb-4 border-b border-red-500/30">
          <div className="w-12 h-12 bg-red-500 rounded-full flex items-center justify-center">
            <AlertTriangle className="text-white" size={24} />
          </div>
          <div>
            <p className="text-white font-semibold">🚨 Alerta de Seguridad</p>
            <p className="text-red-300 text-sm">Anomalía detectada - Fase 3 activada</p>
          </div>
        </div>

        {/* User Info */}
        <div className="space-y-3 mb-6">
          <div className="bg-black/30 rounded-xl p-4">
            <p className="text-gray-400 text-xs mb-2">INFORMACIÓN DEL USUARIO</p>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-400 text-sm">Usuario:</span>
                <span className="text-white">{backendData.usuario}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400 text-sm">Evento:</span>
                <span className="text-red-400">{backendData.evento}</span>
              </div>
            </div>
          </div>

          {/* AI Analysis Results */}
          <div className="bg-black/30 rounded-xl p-4">
            <p className="text-gray-400 text-xs mb-2">ANÁLISIS DE IA</p>
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-gray-400 text-sm">Voz:</span>
                <span className={`text-sm px-3 py-1 rounded-full ${
                  voiceResult === 'stress' 
                    ? 'bg-red-500/20 text-red-400 border border-red-500' 
                    : 'bg-green-500/20 text-green-400 border border-green-500'
                }`}>
                  {backendData.voz}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-400 text-sm">Gesto:</span>
                <span className={`text-sm px-3 py-1 rounded-full ${
                  gestureResult === 'abnormal' 
                    ? 'bg-red-500/20 text-red-400 border border-red-500' 
                    : 'bg-green-500/20 text-green-400 border border-green-500'
                }`}>
                  {backendData.gesto}
                </span>
              </div>
            </div>
          </div>

          {/* Transaction Details */}
          <div className="bg-black/30 rounded-xl p-4">
            <p className="text-gray-400 text-xs mb-2">DETALLES DE TRANSACCIÓN</p>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-400 text-sm">Monto:</span>
                <span className="text-white">S/ {backendData.monto.toFixed(2)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400 text-sm">Destinatario:</span>
                <span className="text-white">{backendData.destinatario}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400 text-sm">Hora:</span>
                <span className="text-white">{backendData.hora}</span>
              </div>
            </div>
          </div>

          {/* Location Data */}
          <div className="bg-black/30 rounded-xl p-4">
            <p className="text-gray-400 text-xs mb-2">UBICACIÓN Y DISPOSITIVO</p>
            <div className="space-y-2">
              <div className="flex justify-between items-center">
                <span className="text-gray-400 text-sm">GPS:</span>
                <span className="text-white flex items-center gap-1">
                  <MapPin size={14} className="text-red-400" />
                  {backendData.gps}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400 text-sm">Coordenadas:</span>
                <span className="text-gray-300 text-xs font-mono">{backendData.coordenadas}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400 text-sm">Dispositivo:</span>
                <span className="text-white text-sm">{backendData.dispositivo}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400 text-sm">IP:</span>
                <span className="text-white text-sm font-mono">{backendData.ip}</span>
              </div>
            </div>
          </div>

          {/* Action Taken */}
          <div className="bg-red-500/10 rounded-xl p-4 border border-red-500/30">
            <p className="text-red-400 text-xs mb-2">ACCIÓN EJECUTADA</p>
            <p className="text-white">{backendData.accion}</p>
            <p className="text-gray-400 text-xs mt-2">
              ✓ Transferencia bloqueada silenciosamente
            </p>
            <p className="text-gray-400 text-xs">
              ✓ Usuario ve confirmación falsa
            </p>
            <p className="text-gray-400 text-xs">
              ✓ Operadores notificados inmediatamente
            </p>
          </div>
        </div>

        {/* Backend Log */}
        <div className="bg-black rounded-xl p-4 border border-green-500/30 overflow-x-auto">
          <p className="text-green-400 text-xs mb-2">📡 Backend Event Log:</p>
          <pre className="text-green-400 text-xs leading-relaxed">
{`{
  "event": "guardian_mode_phase_3",
  "user": "${userName.toLowerCase().replace(' ', '_')}",
  "trigger": "behavioral_anomaly",
  "voice_analysis": "${voiceResult}",
  "gesture_analysis": "${gestureResult}",
  "operator_alert": true,
  "transaction_blocked": true,
  "user_sees_success": true,
  "amount": ${amount},
  "recipient": "${recipient}",
  "location": "${backendData.gps}",
  "coordinates": "${backendData.coordenadas}",
  "device": "${backendData.dispositivo}",
  "ip": "${backendData.ip}",
  "timestamp": "${backendData.timestamp}"
}`}
          </pre>
        </div>
      </motion.div>

      {/* Action Buttons */}
      <div className="space-y-3 mb-6">
        <button
          onClick={onComplete}
          className="w-full py-4 bg-red-600 hover:bg-red-700 text-white rounded-2xl transition-colors flex items-center justify-center gap-2"
        >
          <AlertTriangle size={20} />
          Bloquear Cuenta Permanentemente
        </button>
        <button
          onClick={onComplete}
          className="w-full py-4 bg-yellow-600 hover:bg-yellow-700 text-white rounded-2xl transition-colors"
        >
          📞 Contactar Usuario Inmediatamente
        </button>
        <button
          onClick={() => setShowBackendDemo(false)}
          className="w-full py-4 bg-gray-700 hover:bg-gray-600 text-white rounded-2xl transition-colors"
        >
          ← Volver a Vista de Usuario
        </button>
        <button
          onClick={onComplete}
          className="w-full py-4 bg-transparent border-2 border-gray-600 text-gray-300 rounded-2xl hover:border-gray-500 transition-colors"
        >
          Revisar Más Tarde
        </button>
      </div>

      {/* Info Footer */}
      <div className="bg-blue-900/20 rounded-xl p-4 border border-blue-500/30">
        <p className="text-blue-300 text-xs">
          ℹ️ <strong>Propósito Demostrativo:</strong> Este panel muestra la información que los operadores de 
          seguridad verían en tiempo real. En producción, esta vista está protegida con autenticación 
          multi-factor y solo es accesible para personal autorizado.
        </p>
      </div>
    </motion.div>
  );

  return (
    <AnimatePresence mode="wait">
      {showBackendDemo ? (
        <BackendDemoView key="backend" />
      ) : (
        <UserView key="user" />
      )}
    </AnimatePresence>
  );
};
