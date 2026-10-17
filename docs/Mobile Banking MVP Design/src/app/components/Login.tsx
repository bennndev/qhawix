import React from 'react';
import { motion } from 'motion/react';
import { Fingerprint } from 'lucide-react';

interface LoginProps {
  onLogin: (method: 'fingerprint' | 'pin') => void;
  onSDKActivate: () => void;
}

export const Login: React.FC<LoginProps> = ({ onLogin, onSDKActivate }) => {
  const [tapCount, setTapCount] = React.useState(0);
  const [lastTap, setLastTap] = React.useState(0);
  const [showGlow, setShowGlow] = React.useState(false);

  const handleFingerprint = () => {
    const now = Date.now();
    if (now - lastTap < 500) {
      const newCount = tapCount + 1;
      setTapCount(newCount);
      if (newCount >= 3) {
        setShowGlow(true);
        setTimeout(() => setShowGlow(false), 300);
        onSDKActivate();
        setTapCount(0);
      }
    } else {
      setTapCount(1);
    }
    setLastTap(now);
    
    // Normal login after delay
    setTimeout(() => onLogin('fingerprint'), 400);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0033CC] to-[#001A66] flex flex-col items-center justify-center px-6 relative overflow-hidden">
      {/* Background decorative elements */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-20 left-10 w-64 h-64 bg-cyan-400 rounded-full blur-3xl" />
        <div className="absolute bottom-20 right-10 w-64 h-64 bg-purple-400 rounded-full blur-3xl" />
      </div>

      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="text-center z-10 mb-12"
      >
        {/* Logo */}
        <div className="w-24 h-24 mx-auto mb-6 bg-white rounded-3xl flex items-center justify-center shadow-2xl">
          <div className="text-5xl">🏦</div>
        </div>

        <h1 className="text-white text-3xl mb-2">Banco Seguro IA</h1>
        <p className="text-cyan-200 text-lg">Welcome back.</p>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5, delay: 0.2 }}
        className="w-full max-w-sm space-y-4 z-10"
      >
        {/* Fingerprint Button */}
        <motion.button
          onClick={handleFingerprint}
          className="w-full py-4 rounded-2xl bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white flex items-center justify-center gap-3 shadow-lg relative overflow-hidden"
          whileTap={{ scale: 0.98 }}
        >
          {showGlow && (
            <motion.div
              className="absolute inset-0 bg-cyan-300"
              initial={{ opacity: 0.6 }}
              animate={{ opacity: 0 }}
              transition={{ duration: 0.3 }}
            />
          )}
          <Fingerprint size={24} />
          <span>Use Fingerprint</span>
        </motion.button>

        {/* PIN Button */}
        <motion.button
          onClick={() => onLogin('pin')}
          className="w-full py-4 rounded-2xl bg-transparent border-2 border-white text-white flex items-center justify-center gap-3"
          whileTap={{ scale: 0.98 }}
        >
          <span>Enter with PIN</span>
        </motion.button>
      </motion.div>

      {/* Footer */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5, delay: 0.4 }}
        className="absolute bottom-8 text-center z-10"
      >
        <p className="text-cyan-200 text-sm">Protected by AURA Guardian AI</p>
      </motion.div>
    </div>
  );
};
