import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, MapPin, Smartphone, Clock, Camera, Wifi, AlertTriangle, Download, Shield } from 'lucide-react';

interface AnomalyEvidenceProps {
  onBack: () => void;
  onBlock: () => void;
  onConfirm: () => void;
}

export const AnomalyEvidence: React.FC<AnomalyEvidenceProps> = ({ onBack, onBlock, onConfirm }) => {
  const [countdown, setCountdown] = React.useState(30);

  React.useEffect(() => {
    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) return 30;
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const evidenceData = {
    timestamp: new Date().toLocaleString('es-PE', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    }),
    location: {
      address: 'Av. Arequipa 2450, Lince, Lima',
      coordinates: '-12.0842, -77.0365',
      distance: '15.3 km de tu ubicación habitual',
    },
    device: {
      model: 'iPhone 13 Pro',
      os: 'iOS 17.2',
      browser: 'Safari 17.0',
      fingerprint: 'A3F9-B2E8-C1D7-9K4L',
    },
    network: {
      ip: '190.237.45.182',
      isp: 'Claro Perú',
      vpn: false,
      proxy: false,
    },
    attempt: {
      type: 'Transferencia',
      amount: 'S/ 5,850.00',
      recipient: 'Cuenta no registrada',
      failures: 2,
    },
  };

  return (
    <div className="min-h-screen bg-gray-50 overflow-y-auto pb-20">
      {/* Header - Alert Mode */}
      <div className="bg-gradient-to-br from-red-600 to-orange-600 pt-12 pb-8 px-6">
        <div className="flex items-center gap-4 mb-6">
          <motion.button
            onClick={onBack}
            className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="text-white" size={20} />
          </motion.button>
          <div>
            <h1 className="text-white text-2xl">Actividad Sospechosa</h1>
            <p className="text-orange-100 text-sm">Evidencia capturada automáticamente</p>
          </div>
        </div>

        {/* Countdown */}
        <motion.div
          animate={{ scale: [1, 1.02, 1] }}
          transition={{ duration: 1, repeat: Infinity }}
          className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 border border-white/20"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <AlertTriangle className="text-yellow-300" size={24} />
              <div>
                <p className="text-white text-sm">Responde en:</p>
                <p className="text-yellow-300 text-xs">Se bloqueará automáticamente</p>
              </div>
            </div>
            <div className="text-center">
              <p className="text-white text-3xl tabular-nums">{countdown}</p>
              <p className="text-orange-200 text-xs">segundos</p>
            </div>
          </div>
        </motion.div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-3">
          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            onClick={onConfirm}
            className="py-4 bg-gradient-to-r from-green-500 to-emerald-500 text-white rounded-2xl shadow-lg"
            whileTap={{ scale: 0.98 }}
          >
            ✓ Fui yo
          </motion.button>
          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            onClick={onBlock}
            className="py-4 bg-gradient-to-r from-red-500 to-orange-500 text-white rounded-2xl shadow-lg"
            whileTap={{ scale: 0.98 }}
          >
            ✕ Bloquear
          </motion.button>
        </div>

        {/* Attempt Details */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4 flex items-center gap-2">
            <AlertTriangle className="text-orange-600" size={20} />
            Intento Detectado
          </h3>
          <div className="space-y-3">
            <div className="flex justify-between p-3 bg-red-50 rounded-xl">
              <span className="text-gray-700 text-sm">Tipo de operación:</span>
              <span className="text-red-700">{evidenceData.attempt.type}</span>
            </div>
            <div className="flex justify-between p-3 bg-red-50 rounded-xl">
              <span className="text-gray-700 text-sm">Monto:</span>
              <span className="text-red-700 text-lg">{evidenceData.attempt.amount}</span>
            </div>
            <div className="flex justify-between p-3 bg-red-50 rounded-xl">
              <span className="text-gray-700 text-sm">Destinatario:</span>
              <span className="text-red-700">{evidenceData.attempt.recipient}</span>
            </div>
            <div className="flex justify-between p-3 bg-orange-50 rounded-xl">
              <span className="text-gray-700 text-sm">Intentos fallidos:</span>
              <span className="text-orange-700">{evidenceData.attempt.failures} previos</span>
            </div>
          </div>
        </motion.div>

        {/* Location Evidence */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4 flex items-center gap-2">
            <MapPin className="text-blue-600" size={20} />
            Ubicación Capturada
          </h3>
          
          {/* Map Placeholder */}
          <div className="w-full h-32 bg-gradient-to-br from-blue-100 to-cyan-100 rounded-xl mb-4 relative overflow-hidden">
            <div className="absolute inset-0 flex items-center justify-center">
              <MapPin className="text-red-600" size={48} />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-start gap-2">
              <MapPin className="text-gray-400 flex-shrink-0 mt-0.5" size={16} />
              <div>
                <p className="text-gray-700 text-sm">{evidenceData.location.address}</p>
                <p className="text-gray-500 text-xs">{evidenceData.location.coordinates}</p>
              </div>
            </div>
            <div className="bg-orange-50 rounded-lg p-3 border border-orange-200">
              <p className="text-orange-700 text-xs">⚠️ {evidenceData.location.distance}</p>
            </div>
          </div>
        </motion.div>

        {/* Device Evidence */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4 flex items-center gap-2">
            <Smartphone className="text-purple-600" size={20} />
            Información del Dispositivo
          </h3>
          <div className="space-y-2">
            <div className="flex justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-gray-600 text-sm">Modelo:</span>
              <span className="text-gray-900 text-sm">{evidenceData.device.model}</span>
            </div>
            <div className="flex justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-gray-600 text-sm">Sistema:</span>
              <span className="text-gray-900 text-sm">{evidenceData.device.os}</span>
            </div>
            <div className="flex justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-gray-600 text-sm">Navegador:</span>
              <span className="text-gray-900 text-sm">{evidenceData.device.browser}</span>
            </div>
            <div className="flex justify-between p-3 bg-purple-50 rounded-lg border border-purple-200">
              <span className="text-gray-600 text-sm">Huella digital:</span>
              <span className="text-purple-700 text-xs font-mono">{evidenceData.device.fingerprint}</span>
            </div>
          </div>
        </motion.div>

        {/* Network Evidence */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4 flex items-center gap-2">
            <Wifi className="text-green-600" size={20} />
            Información de Red
          </h3>
          <div className="space-y-2">
            <div className="flex justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-gray-600 text-sm">IP:</span>
              <span className="text-gray-900 text-sm font-mono">{evidenceData.network.ip}</span>
            </div>
            <div className="flex justify-between p-3 bg-gray-50 rounded-lg">
              <span className="text-gray-600 text-sm">Proveedor:</span>
              <span className="text-gray-900 text-sm">{evidenceData.network.isp}</span>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className={`p-3 rounded-lg ${evidenceData.network.vpn ? 'bg-red-50' : 'bg-green-50'}`}>
                <p className="text-xs text-gray-600 mb-1">VPN</p>
                <p className={`text-sm ${evidenceData.network.vpn ? 'text-red-700' : 'text-green-700'}`}>
                  {evidenceData.network.vpn ? 'Detectada' : 'No detectada'}
                </p>
              </div>
              <div className={`p-3 rounded-lg ${evidenceData.network.proxy ? 'bg-red-50' : 'bg-green-50'}`}>
                <p className="text-xs text-gray-600 mb-1">Proxy</p>
                <p className={`text-sm ${evidenceData.network.proxy ? 'text-red-700' : 'text-green-700'}`}>
                  {evidenceData.network.proxy ? 'Detectado' : 'No detectado'}
                </p>
              </div>
            </div>
          </div>
        </motion.div>

        {/* Timestamp */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-white rounded-2xl p-4 shadow-sm"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Clock className="text-gray-600" size={20} />
              <span className="text-gray-700 text-sm">Capturado:</span>
            </div>
            <span className="text-gray-900 text-sm font-mono">{evidenceData.timestamp}</span>
          </div>
        </motion.div>

        {/* Download Evidence */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="flex gap-3"
        >
          <button className="flex-1 py-3 bg-gray-200 hover:bg-gray-300 text-gray-700 rounded-xl transition-colors flex items-center justify-center gap-2">
            <Download size={18} />
            <span className="text-sm">Descargar Reporte</span>
          </button>
          <button className="flex-1 py-3 bg-blue-100 hover:bg-blue-200 text-blue-700 rounded-xl transition-colors flex items-center justify-center gap-2">
            <Shield size={18} />
            <span className="text-sm">Contactar Soporte</span>
          </button>
        </motion.div>

        {/* Legal Notice */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.7 }}
          className="bg-gradient-to-r from-blue-50 to-cyan-50 rounded-2xl p-4 border border-blue-200"
        >
          <h3 className="text-blue-900 text-sm mb-2">Nota Legal</h3>
          <p className="text-blue-700 text-xs">
            Esta evidencia ha sido capturada de acuerdo con la Ley 29733 de Protección de Datos Personales 
            y las normas de la SBS. El registro es inmutable y está disponible para investigaciones legales.
          </p>
        </motion.div>
      </div>
    </div>
  );
};
