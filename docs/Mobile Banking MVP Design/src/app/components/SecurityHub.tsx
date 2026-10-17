import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Shield, Moon, MapPin, Users, Eye, Mic, FileText, Activity, Sparkles } from 'lucide-react';
import { OwlIcon } from './OwlIcon';

interface SecurityHubProps {
  onBack: () => void;
  onFeatureSelect: (feature: string) => void;
  securityStatus: {
    ultraSecureMode: boolean;
    geolocation: boolean;
    trustedContacts: number;
    voiceProfile: boolean;
  };
}

export const SecurityHub: React.FC<SecurityHubProps> = ({ onBack, onFeatureSelect, securityStatus }) => {
  const features = [
    {
      id: 'high-balance',
      icon: Shield,
      title: 'Protección de Fondos Altos',
      description: 'IA gestiona y asegura montos elevados',
      color: 'from-blue-500 to-cyan-500',
      status: 'Activo',
    },
    {
      id: 'ultra-secure',
      icon: Moon,
      title: 'Modo Ultra Seguro',
      description: 'Modo nocturno y restricciones programadas',
      color: 'from-purple-500 to-pink-500',
      status: securityStatus.ultraSecureMode ? 'Activo' : 'Inactivo',
    },
    {
      id: 'geolocation',
      icon: MapPin,
      title: 'Geolocalización Inteligente',
      description: 'Zonas de confianza y alertas de ubicación',
      color: 'from-green-500 to-emerald-500',
      status: securityStatus.geolocation ? 'Activo' : 'Inactivo',
    },
    {
      id: 'trusted-contacts',
      icon: Users,
      title: 'Contactos de Confianza',
      description: `${securityStatus.trustedContacts} contactos configurados`,
      color: 'from-orange-500 to-red-500',
      status: securityStatus.trustedContacts > 0 ? 'Activo' : 'Configurar',
    },
    {
      id: 'decoy-account',
      icon: Eye,
      title: 'Modo Cuenta Señuelo',
      description: 'Vista limitada para seguridad',
      color: 'from-indigo-500 to-purple-500',
      status: 'Disponible',
    },
    {
      id: 'voice-control',
      icon: Mic,
      title: 'Control por Voz',
      description: 'Autenticación biométrica de voz',
      color: 'from-pink-500 to-rose-500',
      status: securityStatus.voiceProfile ? 'Activo' : 'Configurar',
    },
    {
      id: 'data-masking',
      icon: Eye,
      title: 'Ocultamiento de Datos',
      description: 'Control de visibilidad por niveles',
      color: 'from-cyan-500 to-blue-500',
      status: 'Activo',
    },
    {
      id: 'anomaly-detection',
      icon: Activity,
      title: 'Detección de Anomalías',
      description: 'Monitoreo de amenazas en tiempo real',
      color: 'from-red-500 to-orange-500',
      status: 'Activo',
    },
    {
      id: 'legal-compliance',
      icon: FileText,
      title: 'Legal y Cumplimiento',
      description: 'Derechos de privacidad y control de datos',
      color: 'from-gray-500 to-gray-700',
      status: 'Ver',
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50 overflow-y-auto pb-20">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#0033CC] to-[#001A66] pt-12 pb-8 px-6">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-4">
            <motion.button
              onClick={onBack}
              className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
              whileTap={{ scale: 0.95 }}
            >
              <ArrowLeft className="text-white" size={20} />
            </motion.button>
            <div>
              <h1 className="text-white text-2xl">Security Hub</h1>
              <p className="text-cyan-200 text-sm">Powered by AURA Guardian AI</p>
            </div>
          </div>
          <OwlIcon state="idle" size={36} />
        </div>

        {/* Security Score */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 border border-white/20"
        >
          <div className="flex items-center justify-between mb-3">
            <span className="text-cyan-200 text-sm">Security Score</span>
            <Sparkles className="text-yellow-300" size={20} />
          </div>
          <div className="flex items-end gap-2">
            <span className="text-white text-4xl">98</span>
            <span className="text-cyan-200 text-xl mb-1">/100</span>
          </div>
          <div className="w-full h-2 bg-white/20 rounded-full mt-3 overflow-hidden">
            <motion.div
              className="h-full bg-gradient-to-r from-green-400 to-cyan-400"
              initial={{ width: 0 }}
              animate={{ width: '98%' }}
              transition={{ duration: 1, delay: 0.3 }}
            />
          </div>
        </motion.div>
      </div>

      {/* Features Grid */}
      <div className="px-6 -mt-4 space-y-3 relative z-10">
        {features.map((feature, index) => (
          <motion.button
            key={feature.id}
            onClick={() => onFeatureSelect(feature.id)}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.05 }}
            className="w-full bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-shadow text-left"
            whileTap={{ scale: 0.98 }}
          >
            <div className="flex items-center gap-4">
              <div className={`w-14 h-14 rounded-xl bg-gradient-to-br ${feature.color} flex items-center justify-center flex-shrink-0`}>
                <feature.icon className="text-white" size={24} />
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="text-gray-900 mb-1">{feature.title}</h3>
                <p className="text-gray-500 text-sm">{feature.description}</p>
              </div>
              <div className="flex-shrink-0">
                <span
                  className={`text-xs px-2 py-1 rounded-full ${
                    feature.status === 'Active'
                      ? 'bg-green-100 text-green-700'
                      : feature.status === 'Inactive'
                      ? 'bg-gray-100 text-gray-600'
                      : feature.status === 'Setup Required'
                      ? 'bg-orange-100 text-orange-700'
                      : 'bg-blue-100 text-blue-700'
                  }`}
                >
                  {feature.status}
                </span>
              </div>
            </div>
          </motion.button>
        ))}
      </div>

      {/* AURA Assistant Tip */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="mx-6 mt-6 bg-gradient-to-r from-cyan-50 to-blue-50 rounded-2xl p-4 border border-cyan-200"
      >
        <div className="flex items-start gap-3">
          <OwlIcon state="idle" size={32} />
          <div>
            <p className="text-gray-900 text-sm mb-1">AURA Tip</p>
            <p className="text-gray-600 text-xs">
              Enable all security features for maximum protection. I'll monitor and alert you of any suspicious activity 24/7.
            </p>
          </div>
        </div>
      </motion.div>
    </div>
  );
};
