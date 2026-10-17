import React from 'react';
import { motion } from 'motion/react';
import { Eye, EyeOff } from 'lucide-react';

interface BalanceCardProps {
  balance: number;
}

export const BalanceCard: React.FC<BalanceCardProps> = ({ balance }) => {
  const [showBalance, setShowBalance] = React.useState(true);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="relative overflow-hidden rounded-3xl p-6 mb-6"
      style={{
        background: 'linear-gradient(135deg, rgba(58, 12, 163, 0.9) 0%, rgba(72, 202, 228, 0.9) 100%)',
        backdropFilter: 'blur(10px)',
        boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
      }}
    >
      {/* Decorative elements */}
      <div className="absolute top-0 right-0 w-32 h-32 bg-white opacity-10 rounded-full -mr-16 -mt-16" />
      <div className="absolute bottom-0 left-0 w-24 h-24 bg-white opacity-10 rounded-full -ml-12 -mb-12" />

      <div className="relative z-10">
        <div className="flex justify-between items-start mb-4">
          <div>
            <p className="text-cyan-100 text-sm mb-1">Available Balance</p>
            <div className="flex items-center gap-2">
              {showBalance ? (
                <h2 className="text-white text-3xl">S/ {balance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</h2>
              ) : (
                <h2 className="text-white text-3xl">S/ ••••••</h2>
              )}
            </div>
          </div>
          <motion.button
            onClick={() => setShowBalance(!showBalance)}
            className="text-white p-2"
            whileTap={{ scale: 0.9 }}
          >
            {showBalance ? <Eye size={20} /> : <EyeOff size={20} />}
          </motion.button>
        </div>

        <div className="flex justify-between text-cyan-100 text-sm">
          <span>Account: •••• 4532</span>
          <span>Jorge Pino</span>
        </div>
      </div>
    </motion.div>
  );
};
