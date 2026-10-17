import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Eye, EyeOff, Lock } from 'lucide-react';

interface DataMaskingProps {
  onBack: () => void;
}

export const DataMasking: React.FC<DataMaskingProps> = ({ onBack }) => {
  const [maskingLevel, setMaskingLevel] = React.useState<'none' | 'partial' | 'full'>('none');
  const [autoMaskEnabled, setAutoMaskEnabled] = React.useState(false);

  const balance = 15432.75;
  const cardNumber = '4532 1234 5678 9010';
  const accountNumber = '0011-2233-4455-6677';

  const getMaskedBalance = () => {
    switch (maskingLevel) {
      case 'partial':
        return 'S/ •••32.75';
      case 'full':
        return 'S/ •••••.••';
      default:
        return `S/ ${balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}`;
    }
  };

  const getMaskedCard = () => {
    switch (maskingLevel) {
      case 'partial':
        return '•••• •••• •••• 9010';
      case 'full':
        return '•••• •••• •••• ••••';
      default:
        return cardNumber;
    }
  };

  const getMaskedAccount = () => {
    switch (maskingLevel) {
      case 'partial':
        return '••••-••••-••••-6677';
      case 'full':
        return '••••-••••-••••-••••';
      default:
        return accountNumber;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 overflow-y-auto pb-20">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#0033CC] to-[#001A66] pt-12 pb-8 px-6">
        <div className="flex items-center gap-4 mb-6">
          <motion.button
            onClick={onBack}
            className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="text-white" size={20} />
          </motion.button>
          <div>
            <h1 className="text-white text-2xl">Ocultamiento de Datos</h1>
            <p className="text-cyan-200 text-sm">Control de visibilidad</p>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-cyan-50 to-blue-50 rounded-2xl p-4 border border-cyan-200"
        >
          <div className="flex items-start gap-3">
            <Eye className="text-blue-600 flex-shrink-0 mt-0.5" size={20} />
            <div>
              <h3 className="text-blue-900 text-sm mb-1">Triple toque para ocultar</h3>
              <p className="text-blue-700 text-xs">
                Toca 3 veces rápidamente sobre cualquier monto o número de cuenta para ocultarlo 
                temporalmente. Ideal cuando usas la app en lugares públicos.
              </p>
            </div>
          </div>
        </motion.div>

        {/* Masking Level Selector */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Nivel de Privacidad</h3>
          <div className="space-y-3">
            <button
              onClick={() => setMaskingLevel('none')}
              className={`w-full p-4 rounded-xl border-2 transition-all text-left ${
                maskingLevel === 'none'
                  ? 'bg-blue-50 border-blue-300'
                  : 'bg-gray-50 border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    maskingLevel === 'none' ? 'bg-blue-100' : 'bg-gray-200'
                  }`}>
                    <Eye className={maskingLevel === 'none' ? 'text-blue-600' : 'text-gray-600'} size={20} />
                  </div>
                  <div>
                    <p className="text-gray-900 text-sm mb-0.5">Sin ocultamiento</p>
                    <p className="text-gray-600 text-xs">Todos los datos visibles</p>
                  </div>
                </div>
                {maskingLevel === 'none' && (
                  <div className="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center">
                    <div className="w-2 h-2 bg-white rounded-full" />
                  </div>
                )}
              </div>
            </button>

            <button
              onClick={() => setMaskingLevel('partial')}
              className={`w-full p-4 rounded-xl border-2 transition-all text-left ${
                maskingLevel === 'partial'
                  ? 'bg-purple-50 border-purple-300'
                  : 'bg-gray-50 border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    maskingLevel === 'partial' ? 'bg-purple-100' : 'bg-gray-200'
                  }`}>
                    <EyeOff className={maskingLevel === 'partial' ? 'text-purple-600' : 'text-gray-600'} size={20} />
                  </div>
                  <div>
                    <p className="text-gray-900 text-sm mb-0.5">Ocultamiento parcial</p>
                    <p className="text-gray-600 text-xs">Muestra últimos 4 dígitos</p>
                  </div>
                </div>
                {maskingLevel === 'partial' && (
                  <div className="w-6 h-6 bg-purple-500 rounded-full flex items-center justify-center">
                    <div className="w-2 h-2 bg-white rounded-full" />
                  </div>
                )}
              </div>
            </button>

            <button
              onClick={() => setMaskingLevel('full')}
              className={`w-full p-4 rounded-xl border-2 transition-all text-left ${
                maskingLevel === 'full'
                  ? 'bg-red-50 border-red-300'
                  : 'bg-gray-50 border-gray-200 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    maskingLevel === 'full' ? 'bg-red-100' : 'bg-gray-200'
                  }`}>
                    <Lock className={maskingLevel === 'full' ? 'text-red-600' : 'text-gray-600'} size={20} />
                  </div>
                  <div>
                    <p className="text-gray-900 text-sm mb-0.5">Ocultamiento total</p>
                    <p className="text-gray-600 text-xs">Todos los datos ocultos</p>
                  </div>
                </div>
                {maskingLevel === 'full' && (
                  <div className="w-6 h-6 bg-red-500 rounded-full flex items-center justify-center">
                    <div className="w-2 h-2 bg-white rounded-full" />
                  </div>
                )}
              </div>
            </button>
          </div>
        </motion.div>

        {/* Preview */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Vista Previa</h3>
          
          {/* Balance Card Preview */}
          <div className="bg-gradient-to-br from-[#0033CC] to-[#001A66] rounded-2xl p-6 mb-4">
            <p className="text-cyan-200 text-sm mb-2">Saldo disponible</p>
            <motion.p
              key={maskingLevel}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="text-white text-3xl mb-4"
              style={{ filter: maskingLevel !== 'none' ? 'blur(2px)' : 'none' }}
            >
              {getMaskedBalance()}
            </motion.p>
            
            <div className="space-y-2">
              <div>
                <p className="text-cyan-300 text-xs mb-1">Número de cuenta</p>
                <motion.p
                  key={`account-${maskingLevel}`}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="text-white text-sm font-mono"
                >
                  {getMaskedAccount()}
                </motion.p>
              </div>
              
              <div>
                <p className="text-cyan-300 text-xs mb-1">Tarjeta principal</p>
                <motion.p
                  key={`card-${maskingLevel}`}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="text-white text-sm font-mono"
                >
                  {getMaskedCard()}
                </motion.p>
              </div>
            </div>
          </div>

          {/* Status */}
          <div className={`p-3 rounded-xl ${
            maskingLevel === 'none' 
              ? 'bg-green-50' 
              : maskingLevel === 'partial' 
              ? 'bg-purple-50' 
              : 'bg-red-50'
          }`}>
            <p className={`text-xs text-center ${
              maskingLevel === 'none' 
                ? 'text-green-700' 
                : maskingLevel === 'partial' 
                ? 'text-purple-700' 
                : 'text-red-700'
            }`}>
              {maskingLevel === 'none' && '👁️ Todos los datos son visibles'}
              {maskingLevel === 'partial' && '🔒 Datos parcialmente ocultos'}
              {maskingLevel === 'full' && '🚫 Datos completamente ocultos'}
            </p>
          </div>
        </motion.div>

        {/* Auto-Mask Settings */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-gray-900 mb-1">Ocultamiento Automático</h3>
              <p className="text-gray-600 text-sm">Activa en lugares públicos</p>
            </div>
            <button
              onClick={() => setAutoMaskEnabled(!autoMaskEnabled)}
              className={`w-14 h-8 rounded-full transition-colors relative ${
                autoMaskEnabled ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
              }`}
            >
              <motion.div
                className="w-6 h-6 bg-white rounded-full absolute top-1"
                animate={{ left: autoMaskEnabled ? '28px' : '4px' }}
                transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              />
            </button>
          </div>

          {autoMaskEnabled && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="bg-blue-50 rounded-xl p-3 border border-blue-200"
            >
              <p className="text-blue-900 text-xs mb-2">Activación automática cuando:</p>
              <div className="space-y-1">
                <p className="text-blue-700 text-xs">• Estás fuera de zonas de confianza</p>
                <p className="text-blue-700 text-xs">• Se detecta WiFi pública</p>
                <p className="text-blue-700 text-xs">• La cámara frontal detecta múltiples personas</p>
              </div>
            </motion.div>
          )}
        </motion.div>

        {/* Tips */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-gradient-to-r from-orange-50 to-yellow-50 rounded-2xl p-4 border border-orange-200"
        >
          <h3 className="text-orange-900 text-sm mb-2">Consejos de Privacidad</h3>
          <div className="space-y-1">
            <p className="text-orange-700 text-xs">• Triple toque funciona en toda la app</p>
            <p className="text-orange-700 text-xs">• El ocultamiento es solo visual, los datos están seguros</p>
            <p className="text-orange-700 text-xs">• Puedes cambiar el nivel desde cualquier pantalla</p>
            <p className="text-orange-700 text-xs">• Se desactiva automáticamente al salir de la app</p>
          </div>
        </motion.div>
      </div>
    </div>
  );
};
