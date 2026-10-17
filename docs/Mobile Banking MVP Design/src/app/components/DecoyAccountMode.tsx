import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Eye, EyeOff, Shield, Lock, Unlock } from 'lucide-react';

interface DecoyAccountModeProps {
  onBack: () => void;
  realBalance: number;
}

export const DecoyAccountMode: React.FC<DecoyAccountModeProps> = ({ onBack, realBalance }) => {
  const [isDecoyActive, setIsDecoyActive] = React.useState(false);
  const [showFullAccess, setShowFullAccess] = React.useState(false);
  const [sessionTimeLeft, setSessionTimeLeft] = React.useState(600); // 10 minutes in seconds

  const decoyBalance = 1250.00;

  React.useEffect(() => {
    if (showFullAccess) {
      const timer = setInterval(() => {
        setSessionTimeLeft((prev) => {
          if (prev <= 1) {
            setShowFullAccess(false);
            return 600;
          }
          return prev - 1;
        });
      }, 1000);
      return () => clearInterval(timer);
    }
  }, [showFullAccess]);

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="min-h-screen bg-gray-50 overflow-y-auto pb-20">
      {/* Header */}
      <div className={`pt-12 pb-8 px-6 transition-colors ${
        isDecoyActive 
          ? 'bg-gradient-to-br from-orange-600 to-red-600' 
          : 'bg-gradient-to-br from-[#0033CC] to-[#001A66]'
      }`}>
        <div className="flex items-center gap-4 mb-6">
          <motion.button
            onClick={onBack}
            className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="text-white" size={20} />
          </motion.button>
          <div>
            <h1 className="text-white text-2xl">Decoy Account Mode</h1>
            <p className="text-cyan-200 text-sm">Safe view protection</p>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-orange-50 to-red-50 rounded-2xl p-4 border border-orange-200"
        >
          <div className="flex items-start gap-3">
            <Shield className="text-orange-600 flex-shrink-0 mt-0.5" size={20} />
            <div>
              <h3 className="text-orange-900 text-sm mb-2">What is Decoy Mode?</h3>
              <p className="text-orange-700 text-xs mb-2">
                In emergency situations, activate Decoy Mode to show a limited balance account.
                This protects you if someone forces you to open the app.
              </p>
              <p className="text-orange-700 text-xs">
                Full access requires multi-factor authentication (PIN + Biometrics + OTP).
              </p>
            </div>
          </div>
        </motion.div>

        {/* Toggle Decoy Mode */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className={`w-14 h-14 rounded-xl flex items-center justify-center ${
                isDecoyActive ? 'bg-orange-500' : 'bg-blue-100'
              }`}>
                {isDecoyActive ? (
                  <EyeOff className="text-white" size={28} />
                ) : (
                  <Eye className="text-blue-600" size={28} />
                )}
              </div>
              <div>
                <p className="text-gray-900 text-lg">
                  {isDecoyActive ? 'Decoy Active' : 'Normal Mode'}
                </p>
                <p className="text-gray-600 text-sm">
                  {isDecoyActive ? 'Showing limited view' : 'Full access enabled'}
                </p>
              </div>
            </div>
            <button
              onClick={() => setIsDecoyActive(!isDecoyActive)}
              className={`w-16 h-9 rounded-full transition-colors relative ${
                isDecoyActive ? 'bg-orange-500' : 'bg-gray-300'
              }`}
            >
              <motion.div
                className="w-7 h-7 bg-white rounded-full absolute top-1"
                animate={{ left: isDecoyActive ? '32px' : '4px' }}
                transition={{ type: 'spring', stiffness: 500, damping: 30 }}
              />
            </button>
          </div>

          {/* Balance Preview */}
          <div className="grid grid-cols-2 gap-3 mt-4">
            <div className={`p-4 rounded-xl border-2 ${
              isDecoyActive ? 'bg-orange-50 border-orange-300' : 'bg-gray-50 border-gray-200'
            }`}>
              <p className="text-gray-600 text-xs mb-1">Decoy Balance</p>
              <p className="text-gray-900 text-xl">S/ {decoyBalance.toFixed(2)}</p>
            </div>
            <div className={`p-4 rounded-xl border-2 ${
              !isDecoyActive ? 'bg-blue-50 border-blue-300' : 'bg-gray-50 border-gray-200'
            }`}>
              <p className="text-gray-600 text-xs mb-1">Real Balance</p>
              <p className="text-gray-900 text-xl">S/ {realBalance.toFixed(2)}</p>
            </div>
          </div>
        </motion.div>

        {/* Full Access Session */}
        {isDecoyActive && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="bg-white rounded-2xl p-6 shadow-sm"
          >
            <h3 className="text-gray-900 mb-4">Request Full Access</h3>
            
            {!showFullAccess ? (
              <div className="space-y-4">
                <p className="text-gray-600 text-sm mb-4">
                  To view your real account, you need to authenticate with all security factors:
                </p>
                
                <div className="space-y-3">
                  <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                    <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                      <Lock className="text-blue-600" size={16} />
                    </div>
                    <span className="text-gray-700 text-sm">6-digit PIN</span>
                  </div>
                  
                  <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                    <div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
                      <Lock className="text-purple-600" size={16} />
                    </div>
                    <span className="text-gray-700 text-sm">Fingerprint / Face ID</span>
                  </div>
                  
                  <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                    <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                      <Lock className="text-green-600" size={16} />
                    </div>
                    <span className="text-gray-700 text-sm">SMS Code (OTP)</span>
                  </div>
                </div>
                
                <button
                  onClick={() => setShowFullAccess(true)}
                  className="w-full py-4 bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white rounded-2xl mt-4"
                >
                  Authenticate & Access Full Account
                </button>
              </div>
            ) : (
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="space-y-4"
              >
                <div className="bg-green-50 rounded-xl p-4 border border-green-200">
                  <div className="flex items-center gap-3 mb-3">
                    <Unlock className="text-green-600" size={24} />
                    <div>
                      <p className="text-green-900 text-sm">Full Access Granted</p>
                      <p className="text-green-700 text-xs">Temporary session active</p>
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between p-3 bg-white rounded-lg">
                    <span className="text-gray-700 text-sm">Session expires in:</span>
                    <span className="text-green-600 text-lg tabular-nums">{formatTime(sessionTimeLeft)}</span>
                  </div>
                </div>
                
                <div className="bg-orange-50 rounded-xl p-4 border border-orange-200">
                  <p className="text-orange-700 text-xs">
                    ⚠️ Session will auto-lock after 2 minutes of inactivity or when timer expires.
                    All actions are being logged for security.
                  </p>
                </div>
                
                <button
                  onClick={() => {
                    setShowFullAccess(false);
                    setSessionTimeLeft(600);
                  }}
                  className="w-full py-3 bg-red-500 hover:bg-red-600 text-white rounded-xl transition-colors"
                >
                  Lock Full Access Now
                </button>
              </motion.div>
            )}
          </motion.div>
        )}

        {/* Security Tips */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-gradient-to-r from-cyan-50 to-blue-50 rounded-2xl p-4 border border-cyan-200"
        >
          <h3 className="text-blue-900 text-sm mb-2">Safety Tips</h3>
          <div className="space-y-2">
            <p className="text-blue-700 text-xs">• Activate before entering high-risk areas</p>
            <p className="text-blue-700 text-xs">• Set a believable decoy balance (not too low)</p>
            <p className="text-blue-700 text-xs">• Never reveal the existence of decoy mode</p>
            <p className="text-blue-700 text-xs">• All authentication attempts are logged</p>
          </div>
        </motion.div>
      </div>
    </div>
  );
};
