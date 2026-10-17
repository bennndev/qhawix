import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, MapPin, Home, Briefcase, Dumbbell, Plus, Check } from 'lucide-react';

interface GeolocationProps {
  onBack: () => void;
}

interface TrustedZone {
  id: string;
  name: string;
  icon: any;
  address: string;
  color: string;
  lat: number;
  lng: number;
}

export const Geolocation: React.FC<GeolocationProps> = ({ onBack }) => {
  const [trustedZones, setTrustedZones] = React.useState<TrustedZone[]>([
    {
      id: '1',
      name: 'Home',
      icon: Home,
      address: 'Av. Javier Prado 2465, San Isidro',
      color: 'from-blue-500 to-cyan-500',
      lat: -12.0931,
      lng: -77.0465,
    },
    {
      id: '2',
      name: 'Office',
      icon: Briefcase,
      address: 'Av. República de Panamá 3065, San Isidro',
      color: 'from-purple-500 to-pink-500',
      lat: -12.0989,
      lng: -77.0398,
    },
  ]);

  const [alertsEnabled, setAlertsEnabled] = React.useState(true);
  const [showAddZone, setShowAddZone] = React.useState(false);

  const recentActivity = [
    { location: 'Home', time: '2 hours ago', status: 'safe' },
    { location: 'Shopping Center Jockey Plaza', time: '5 hours ago', status: 'alert' },
    { location: 'Office', time: 'Yesterday', status: 'safe' },
  ];

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
            <h1 className="text-white text-2xl">Intelligent Geolocation</h1>
            <p className="text-cyan-200 text-sm">Trusted zones & alerts</p>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Map Placeholder */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl overflow-hidden shadow-sm"
        >
          <div className="w-full h-48 bg-gradient-to-br from-blue-100 to-cyan-100 relative">
            {/* Simplified map visualization */}
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-center">
                <MapPin className="text-blue-600 mx-auto mb-2" size={32} />
                <p className="text-gray-700 text-sm">Lima, Peru</p>
                <p className="text-gray-500 text-xs">2 Trusted Zones Active</p>
              </div>
            </div>

            {/* Zone markers */}
            {trustedZones.map((zone, index) => (
              <motion.div
                key={zone.id}
                className="absolute w-8 h-8 bg-green-500 rounded-full border-4 border-white shadow-lg"
                style={{
                  left: `${30 + index * 35}%`,
                  top: `${40 + index * 10}%`,
                }}
                animate={{
                  scale: [1, 1.2, 1],
                }}
                transition={{
                  duration: 2,
                  repeat: Infinity,
                  delay: index * 0.5,
                }}
              >
                <div className="absolute -top-1 -right-1 w-3 h-3 bg-green-400 rounded-full animate-ping" />
              </motion.div>
            ))}
          </div>

          <div className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-900 text-sm">Location Tracking</p>
                <p className="text-gray-600 text-xs">Monitor access from trusted zones</p>
              </div>
              <button
                onClick={() => setAlertsEnabled(!alertsEnabled)}
                className={`w-14 h-8 rounded-full transition-colors relative ${
                  alertsEnabled ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
                }`}
              >
                <motion.div
                  className="w-6 h-6 bg-white rounded-full absolute top-1"
                  animate={{ left: alertsEnabled ? '28px' : '4px' }}
                  transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                />
              </button>
            </div>
          </div>
        </motion.div>

        {/* Trusted Zones */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-900">Trusted Zones</h3>
            <motion.button
              onClick={() => setShowAddZone(!showAddZone)}
              className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center"
              whileTap={{ scale: 0.95 }}
            >
              <Plus className="text-blue-600" size={18} />
            </motion.button>
          </div>

          <div className="space-y-3">
            {trustedZones.map((zone, index) => (
              <motion.div
                key={zone.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.1 + index * 0.05 }}
                className="flex items-center gap-4 p-3 bg-gray-50 rounded-xl"
              >
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${zone.color} flex items-center justify-center flex-shrink-0`}>
                  <zone.icon className="text-white" size={20} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-gray-900 text-sm mb-0.5">{zone.name}</p>
                  <p className="text-gray-500 text-xs truncate">{zone.address}</p>
                </div>
                <div className="w-6 h-6 bg-green-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <Check className="text-white" size={14} />
                </div>
              </motion.div>
            ))}
          </div>

          {showAddZone && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="mt-4 pt-4 border-t border-gray-200"
            >
              <div className="space-y-3">
                <button className="w-full py-3 bg-gray-50 hover:bg-gray-100 rounded-xl text-gray-700 text-sm transition-colors flex items-center justify-center gap-2">
                  <MapPin size={16} />
                  Use Current Location
                </button>
                <button className="w-full py-3 bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white rounded-xl text-sm">
                  Add Custom Location
                </button>
              </div>
            </motion.div>
          )}
        </motion.div>

        {/* Recent Activity */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Location Activity</h3>
          <div className="space-y-3">
            {recentActivity.map((activity, index) => (
              <div
                key={index}
                className={`flex items-center justify-between p-3 rounded-xl ${
                  activity.status === 'safe' ? 'bg-green-50' : 'bg-orange-50'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div
                    className={`w-2 h-2 rounded-full ${
                      activity.status === 'safe' ? 'bg-green-500' : 'bg-orange-500'
                    }`}
                  />
                  <div>
                    <p className="text-gray-900 text-sm">{activity.location}</p>
                    <p className="text-gray-500 text-xs">{activity.time}</p>
                  </div>
                </div>
                <div
                  className={`px-2 py-1 rounded-full text-xs ${
                    activity.status === 'safe'
                      ? 'bg-green-100 text-green-700'
                      : 'bg-orange-100 text-orange-700'
                  }`}
                >
                  {activity.status === 'safe' ? 'Trusted' : 'Unknown'}
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Alert Settings */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-gradient-to-r from-orange-50 to-red-50 rounded-2xl p-4 border border-orange-200"
        >
          <h3 className="text-orange-900 text-sm mb-2">Alert Triggers</h3>
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-orange-500 rounded-full" />
              <p className="text-orange-700 text-xs">Login from unknown location</p>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-orange-500 rounded-full" />
              <p className="text-orange-700 text-xs">Transaction outside trusted zones</p>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-orange-500 rounded-full" />
              <p className="text-orange-700 text-xs">Rapid location changes detected</p>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};
