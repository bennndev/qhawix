import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, TrendingUp, PiggyBank, Building, AlertCircle } from 'lucide-react';
import { OwlIcon } from './OwlIcon';

interface HighBalanceProtectionProps {
  onBack: () => void;
  balance: number;
}

export const HighBalanceProtection: React.FC<HighBalanceProtectionProps> = ({ onBack, balance }) => {
  const [autoTransferEnabled, setAutoTransferEnabled] = React.useState(false);
  const [threshold, setThreshold] = React.useState(10000);

  const safeBalance = 5000;
  const excessAmount = Math.max(0, balance - threshold);

  const transferOptions = [
    {
      id: 'savings',
      icon: PiggyBank,
      title: 'Savings Account',
      description: 'High-yield secure savings',
      rate: '4.5% APY',
      color: 'from-green-500 to-emerald-500',
    },
    {
      id: 'investment',
      icon: TrendingUp,
      title: 'Low-Risk Investment',
      description: 'Government bonds portfolio',
      rate: '5.2% APY',
      color: 'from-blue-500 to-cyan-500',
    },
    {
      id: 'other-bank',
      icon: Building,
      title: 'Secondary Account',
      description: 'BCP account ••••2847',
      rate: 'Instant transfer',
      color: 'from-purple-500 to-pink-500',
    },
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
            <h1 className="text-white text-2xl">High-Balance Protection</h1>
            <p className="text-cyan-200 text-sm">Smart fund management</p>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Current Status Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-start justify-between mb-4">
            <div>
              <p className="text-gray-600 text-sm mb-1">Current Balance</p>
              <p className="text-gray-900 text-3xl">S/ {balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
              <TrendingUp className="text-blue-600" size={24} />
            </div>
          </div>

          {excessAmount > 0 && (
            <div className="bg-orange-50 rounded-xl p-4 border border-orange-200">
              <div className="flex items-start gap-3">
                <AlertCircle className="text-orange-600 flex-shrink-0 mt-0.5" size={20} />
                <div>
                  <p className="text-orange-900 text-sm mb-1">High Balance Detected</p>
                  <p className="text-orange-700 text-xs">
                    You have S/ {excessAmount.toLocaleString('en-US', { minimumFractionDigits: 2 })} above your security threshold.
                    Consider auto-transferring to a secure location.
                  </p>
                </div>
              </div>
            </div>
          )}
        </motion.div>

        {/* AURA Recommendation */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-gradient-to-r from-cyan-50 to-blue-50 rounded-2xl p-4 border border-cyan-200"
        >
          <div className="flex items-start gap-3">
            <OwlIcon state="listening" size={32} />
            <div>
              <p className="text-gray-900 text-sm mb-1">AURA Analysis</p>
              <p className="text-gray-700 text-xs mb-3">
                Based on your spending patterns, I recommend keeping S/ {safeBalance.toLocaleString()} in your main account
                and transferring the excess to a secure investment option.
              </p>
              {excessAmount > 0 && (
                <p className="text-blue-700 text-xs">
                  💡 You could earn ~S/ {((excessAmount * 0.052) / 12).toFixed(2)}/month with low-risk investment
                </p>
              )}
            </div>
          </div>
        </motion.div>

        {/* Threshold Setting */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Security Threshold</h3>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between mb-2">
                <span className="text-gray-600 text-sm">Maximum safe balance</span>
                <span className="text-gray-900">S/ {threshold.toLocaleString()}</span>
              </div>
              <input
                type="range"
                min="5000"
                max="50000"
                step="1000"
                value={threshold}
                onChange={(e) => setThreshold(parseInt(e.target.value))}
                className="w-full h-2 bg-gray-200 rounded-full appearance-none cursor-pointer"
                style={{
                  background: `linear-gradient(to right, #3A0CA3 0%, #48CAE4 ${((threshold - 5000) / 45000) * 100}%, #E5E7EB ${((threshold - 5000) / 45000) * 100}%, #E5E7EB 100%)`,
                }}
              />
            </div>
          </div>
        </motion.div>

        {/* Auto-Transfer Toggle */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-gray-900 mb-1">Auto-Transfer</h3>
              <p className="text-gray-600 text-sm">Automatically move excess funds</p>
            </div>
            <button
              onClick={() => setAutoTransferEnabled(!autoTransferEnabled)}
              className={`w-14 h-8 rounded-full transition-colors relative ${
                autoTransferEnabled ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
              }`}
            >
              <motion.div
                className="w-6 h-6 bg-white rounded-full absolute top-1"
                animate={{ left: autoTransferEnabled ? '28px' : '4px' }}
                transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              />
            </button>
          </div>

          {autoTransferEnabled && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="space-y-3"
            >
              <p className="text-gray-600 text-sm">Transfer excess to:</p>
              {transferOptions.map((option) => (
                <button
                  key={option.id}
                  className="w-full bg-gray-50 hover:bg-gray-100 rounded-xl p-4 transition-colors text-left"
                >
                  <div className="flex items-center gap-4">
                    <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${option.color} flex items-center justify-center flex-shrink-0`}>
                      <option.icon className="text-white" size={20} />
                    </div>
                    <div className="flex-1">
                      <p className="text-gray-900 text-sm mb-0.5">{option.title}</p>
                      <p className="text-gray-500 text-xs">{option.description}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-green-600 text-sm">{option.rate}</p>
                    </div>
                  </div>
                </button>
              ))}
            </motion.div>
          )}
        </motion.div>

        {/* Manual Transfer Button */}
        {excessAmount > 0 && (
          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="w-full py-4 bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white rounded-2xl shadow-lg"
            whileTap={{ scale: 0.98 }}
          >
            Transfer S/ {excessAmount.toLocaleString('en-US', { minimumFractionDigits: 2 })} Now
          </motion.button>
        )}
      </div>
    </div>
  );
};
