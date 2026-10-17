import React from 'react';
import { motion } from 'motion/react';
import { BalanceCard } from './BalanceCard';
import { ArrowUpRight, Receipt, CreditCard, Shield } from 'lucide-react';
import { OwlIcon } from './OwlIcon';

interface DashboardProps {
  onTransfer: () => void;
  onSecurity: () => void;
  balance: number;
  sdkActive: boolean;
  onSecureMode?: () => void;
}

export const Dashboard: React.FC<DashboardProps> = ({ onTransfer, onSecurity, balance, sdkActive, onSecureMode }) => {
  const quickActions = [
    { icon: ArrowUpRight, label: 'Transferir', color: 'from-purple-500 to-pink-500', action: onTransfer },
    { icon: Receipt, label: 'Pagar', color: 'from-blue-500 to-cyan-500', action: () => {} },
    { icon: CreditCard, label: 'Tarjetas', color: 'from-green-500 to-emerald-500', action: () => {} },
    { icon: Shield, label: 'Seguridad', color: 'from-orange-500 to-red-500', action: onSecurity },
  ];

  return (
    <div className="min-h-screen bg-gray-50 overflow-y-auto pb-20">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#0033CC] to-[#001A66] pt-12 pb-32 px-6 rounded-b-3xl relative">
        <div className="flex justify-between items-center mb-8">
          <div>
            <p className="text-cyan-200 text-sm">Bienvenido de nuevo,</p>
            <h1 className="text-white text-2xl">Jorge Pino</h1>
          </div>
          <div className="flex items-center gap-2">
            {onSecureMode && (
              <motion.button
                whileTap={{ scale: 0.95 }}
                onClick={onSecureMode}
                className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
                title="Modo Seguro"
              >
                <Shield className="text-cyan-200" size={20} />
              </motion.button>
            )}
            <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm">
              <span className="text-white text-xl">👤</span>
            </div>
          </div>
        </div>

        {/* Stealth owl indicator */}
        {sdkActive && (
          <div className="absolute top-4 right-4">
            <OwlIcon state="stealth" size={32} />
          </div>
        )}
      </div>

      {/* Balance Card - Overlapping */}
      <div className="px-6 -mt-24 relative z-10">
        <BalanceCard balance={balance} />

        {/* Quick Actions */}
        <div className="mb-6">
          <h3 className="text-gray-900 text-lg mb-4">Acciones Rápidas</h3>
          <div className="grid grid-cols-4 gap-4">
            {quickActions.map((action, index) => (
              <motion.button
                key={action.label}
                onClick={action.action}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className="flex flex-col items-center gap-2"
                whileTap={{ scale: 0.95 }}
              >
                <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${action.color} flex items-center justify-center text-white shadow-lg`}>
                  <action.icon size={28} />
                </div>
                <span className="text-xs text-gray-700">{action.label}</span>
              </motion.button>
            ))}
          </div>
        </div>

        {/* Recent Transactions */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-gray-900 text-lg">Actividad Reciente</h3>
            <button className="text-[#0033CC] text-sm">Ver todo</button>
          </div>

          <div className="space-y-3">
            {[
              { name: 'Spotify Premium', amount: -15.90, date: 'Nov 10', icon: '🎵' },
              { name: 'Salary Deposit', amount: 3500.00, date: 'Nov 5', icon: '💼' },
              { name: 'Grocery Store', amount: -125.40, date: 'Nov 3', icon: '🛒' },
            ].map((transaction, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 + 0.3 }}
                className="bg-white rounded-2xl p-4 flex items-center justify-between shadow-sm"
              >
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-gray-100 rounded-xl flex items-center justify-center text-xl">
                    {transaction.icon}
                  </div>
                  <div>
                    <p className="text-gray-900">{transaction.name}</p>
                    <p className="text-gray-500 text-sm">{transaction.date}</p>
                  </div>
                </div>
                <p className={`${transaction.amount > 0 ? 'text-green-600' : 'text-gray-900'}`}>
                  {transaction.amount > 0 ? '+' : ''}S/ {Math.abs(transaction.amount).toFixed(2)}
                </p>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Security Notice */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="bg-gradient-to-r from-cyan-50 to-blue-50 rounded-2xl p-4 border border-cyan-200"
        >
          <div className="flex items-center gap-3">
            <Shield className="text-[#0033CC]" size={24} />
            <div>
              <p className="text-gray-900 text-sm">Protected by AURA Guardian</p>
              <p className="text-gray-600 text-xs">Invisible Security. Adaptive Protection.</p>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};
