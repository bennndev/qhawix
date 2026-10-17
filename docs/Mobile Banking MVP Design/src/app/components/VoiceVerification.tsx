import React from 'react';
import { motion } from 'motion/react';
import { Mic } from 'lucide-react';

interface VoiceVerificationProps {
  userName: string;
  amount: number;
  recipient: string;
  onComplete: (result: 'normal' | 'stress') => void;
}

export const VoiceVerification: React.FC<VoiceVerificationProps> = ({
  userName,
  amount,
  recipient,
  onComplete,
}) => {
  const [isListening, setIsListening] = React.useState(false);
  const [waveform, setWaveform] = React.useState<number[]>([]);

  React.useEffect(() => {
    // Start listening after delay
    const timer = setTimeout(() => {
      setIsListening(true);
      // Simulate waveform animation
      const interval = setInterval(() => {
        setWaveform(Array.from({ length: 20 }, () => Math.random()));
      }, 100);

      // Complete after 4 seconds - randomly decide stress or normal
      setTimeout(() => {
        clearInterval(interval);
        setIsListening(false);
        const result = Math.random() > 0.5 ? 'stress' : 'normal';
        setTimeout(() => onComplete(result), 500);
      }, 4000);

      return () => clearInterval(interval);
    }, 1000);

    return () => clearTimeout(timer);
  }, [onComplete]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#1a0a3e] via-[#2d1654] to-[#0033CC] flex flex-col items-center justify-center px-6 overflow-y-auto relative">
      {/* Animated particles */}
      <div className="absolute inset-0 overflow-hidden">
        {[...Array(20)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-2 h-2 bg-cyan-400 rounded-full"
            initial={{
              x: Math.random() * 390,
              y: Math.random() * 844,
              opacity: 0,
            }}
            animate={{
              y: [null, Math.random() * 844],
              opacity: [0, 0.6, 0],
            }}
            transition={{
              duration: 3 + Math.random() * 2,
              repeat: Infinity,
              delay: Math.random() * 2,
            }}
          />
        ))}
      </div>

      <div className="w-full max-w-sm z-10 flex flex-col items-center">
        {/* Title */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-12"
        >
          <h2 className="text-white text-2xl mb-4">Voice Verification</h2>
          <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20">
            <p className="text-cyan-100 text-lg leading-relaxed">
              Hi <span className="text-white">{userName}</span>, we detected an unusual transaction.
            </p>
            <p className="text-cyan-100 text-lg leading-relaxed mt-4">
              Did you authorize <span className="text-white">S/ {amount.toFixed(2)}</span> to <span className="text-white">{recipient}</span>?
            </p>
          </div>
        </motion.div>

        {/* Microphone */}
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.3, type: 'spring', stiffness: 200 }}
          className="relative mb-8"
        >
          {/* Pulsing rings */}
          {isListening && (
            <>
              <motion.div
                className="absolute inset-0 rounded-full bg-cyan-400"
                animate={{ scale: [1, 1.5, 1], opacity: [0.3, 0, 0.3] }}
                transition={{ duration: 2, repeat: Infinity }}
                style={{ width: 120, height: 120, left: -10, top: -10 }}
              />
              <motion.div
                className="absolute inset-0 rounded-full bg-cyan-400"
                animate={{ scale: [1, 1.8, 1], opacity: [0.2, 0, 0.2] }}
                transition={{ duration: 2, repeat: Infinity, delay: 0.5 }}
                style={{ width: 120, height: 120, left: -10, top: -10 }}
              />
            </>
          )}

          {/* Mic button */}
          <motion.div
            className="w-24 h-24 rounded-full bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] flex items-center justify-center shadow-2xl relative z-10"
            animate={isListening ? { scale: [1, 1.05, 1] } : {}}
            transition={{ duration: 1, repeat: isListening ? Infinity : 0 }}
          >
            <Mic className="text-white" size={40} />
          </motion.div>
        </motion.div>

        {/* Waveform */}
        {isListening && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="flex items-center gap-1 mb-8"
          >
            {waveform.map((height, i) => (
              <motion.div
                key={i}
                className="w-1 bg-cyan-400 rounded-full"
                animate={{ height: `${height * 40 + 10}px` }}
                transition={{ duration: 0.1 }}
              />
            ))}
          </motion.div>
        )}

        {/* Status */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="text-cyan-200 text-center"
        >
          {isListening ? 'Listening and analyzing your voice...' : 'Initializing voice verification...'}
        </motion.p>
      </div>
    </div>
  );
};
