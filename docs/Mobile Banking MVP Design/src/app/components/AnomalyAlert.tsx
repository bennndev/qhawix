import React from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { AlertTriangle, MapPin, Smartphone, Clock, X } from 'lucide-react';

interface Alert {
  id: string;
  type: 'login' | 'transaction' | 'location' | 'device';
  title: string;
  description: string;
  timestamp: string;
  severity: 'high' | 'medium' | 'low';
  location?: string;
  device?: string;
}

interface AnomalyAlertProps {
  alerts: Alert[];
  onDismiss: (id: string) => void;
  onViewDetails: (id: string) => void;
}

export const AnomalyAlert: React.FC<AnomalyAlertProps> = ({ alerts, onDismiss, onViewDetails }) => {
  const getAlertIcon = (type: Alert['type']) => {
    switch (type) {
      case 'location':
        return MapPin;
      case 'device':
        return Smartphone;
      default:
        return AlertTriangle;
    }
  };

  const getSeverityColor = (severity: Alert['severity']) => {
    switch (severity) {
      case 'high':
        return 'from-red-500 to-orange-500';
      case 'medium':
        return 'from-orange-500 to-yellow-500';
      case 'low':
        return 'from-yellow-500 to-green-500';
    }
  };

  return (
    <div className="fixed top-4 right-4 left-4 z-50 space-y-3 max-w-[358px] mx-auto">
      <AnimatePresence>
        {alerts.map((alert) => {
          const Icon = getAlertIcon(alert.type);
          return (
            <motion.div
              key={alert.id}
              initial={{ opacity: 0, y: -20, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, x: 100 }}
              className="bg-white rounded-2xl shadow-2xl border-2 border-red-200 overflow-hidden"
            >
              {/* Severity stripe */}
              <div className={`h-1 bg-gradient-to-r ${getSeverityColor(alert.severity)}`} />
              
              <div className="p-4">
                <div className="flex items-start gap-3">
                  <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${getSeverityColor(alert.severity)} flex items-center justify-center flex-shrink-0`}>
                    <Icon className="text-white" size={20} />
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between mb-1">
                      <h4 className="text-gray-900 text-sm">{alert.title}</h4>
                      <button
                        onClick={() => onDismiss(alert.id)}
                        className="text-gray-400 hover:text-gray-600 transition-colors"
                      >
                        <X size={16} />
                      </button>
                    </div>
                    
                    <p className="text-gray-600 text-xs mb-2">{alert.description}</p>
                    
                    <div className="flex items-center gap-4 text-xs text-gray-500 mb-3">
                      <div className="flex items-center gap-1">
                        <Clock size={12} />
                        <span>{alert.timestamp}</span>
                      </div>
                      {alert.location && (
                        <div className="flex items-center gap-1">
                          <MapPin size={12} />
                          <span>{alert.location}</span>
                        </div>
                      )}
                    </div>
                    
                    <button
                      onClick={() => onViewDetails(alert.id)}
                      className="w-full py-2 bg-gradient-to-r from-red-500 to-orange-500 text-white rounded-xl text-xs"
                    >
                      View Details & Secure Account
                    </button>
                  </div>
                </div>
              </div>
            </motion.div>
          );
        })}
      </AnimatePresence>
    </div>
  );
};
