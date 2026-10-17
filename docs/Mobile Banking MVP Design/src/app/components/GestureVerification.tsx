import React from 'react';
import { motion } from 'motion/react';
import { Camera } from 'lucide-react';
import { OwlIcon } from './OwlIcon';

interface GestureVerificationProps {
  onComplete: (result: 'valid' | 'abnormal') => void;
}

export const GestureVerification: React.FC<GestureVerificationProps> = ({ onComplete }) => {
  const [progress, setProgress] = React.useState(0);
  const [phase, setPhase] = React.useState<'instruction' | 'scanning'>('instruction');

  React.useEffect(() => {
    // Start scanning after showing instruction
    const timer = setTimeout(() => {
      setPhase('scanning');
      
      // Progress animation
      const interval = setInterval(() => {
        setProgress((prev) => {
          if (prev >= 100) {
            clearInterval(interval);
            // Randomly decide valid or abnormal
            const result = Math.random() > 0.6 ? 'abnormal' : 'valid';
            setTimeout(() => onComplete(result), 500);
            return 100;
          }
          return prev + 2;
        });
      }, 100);

      return () => clearInterval(interval);
    }, 2000);

    return () => clearTimeout(timer);
  }, [onComplete]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#1a0a3e] via-[#2d1654] to-[#48CAE4] flex flex-col items-center justify-center px-6 overflow-y-auto py-12">
      <div className="w-full max-w-sm flex flex-col items-center">
        {/* Title */}
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-white text-2xl mb-8 text-center"
        >
          Live Gesture Verification
        </motion.h2>

        {/* Camera Frame */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="w-full aspect-[3/4] bg-black/30 backdrop-blur-sm rounded-3xl border-2 border-cyan-400/50 overflow-hidden mb-6 relative"
        >
          {/* Camera placeholder */}
          <div className="absolute inset-0 flex items-center justify-center">
            <Camera className="text-white/30" size={64} />
          </div>

          {/* Scanning overlay */}
          {phase === 'scanning' && (
            <>
              {/* Corner brackets */}
              <div className="absolute top-4 left-4 w-12 h-12 border-t-4 border-l-4 border-cyan-400 rounded-tl-xl" />
              <div className="absolute top-4 right-4 w-12 h-12 border-t-4 border-r-4 border-cyan-400 rounded-tr-xl" />
              <div className="absolute bottom-4 left-4 w-12 h-12 border-b-4 border-l-4 border-cyan-400 rounded-bl-xl" />
              <div className="absolute bottom-4 right-4 w-12 h-12 border-b-4 border-r-4 border-cyan-400 rounded-br-xl" />

              {/* Scanning line */}
              <motion.div
                className="absolute left-0 right-0 h-1 bg-gradient-to-r from-transparent via-cyan-400 to-transparent"
                animate={{ top: ['10%', '90%', '10%'] }}
                transition={{ duration: 2, repeat: Infinity }}
              />

              {/* Detection points */}
              {[
                { x: '30%', y: '25%' },
                { x: '70%', y: '25%' },
                { x: '50%', y: '45%' },
                { x: '35%', y: '60%' },
                { x: '65%', y: '60%' },
              ].map((pos, i) => (
                <motion.div
                  key={i}
                  className="absolute w-2 h-2 bg-cyan-400 rounded-full"
                  style={{ left: pos.x, top: pos.y }}
                  animate={{ scale: [1, 1.5, 1], opacity: [1, 0.5, 1] }}
                  transition={{ duration: 1, repeat: Infinity, delay: i * 0.2 }}
                />
              ))}
            </>
          )}
        </motion.div>

        {/* Instruction Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="w-full bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20 mb-6"
        >
          {phase === 'instruction' ? (
            <p className="text-cyan-100 text-center leading-relaxed">
              Please move your phone slightly to the right and blink once to confirm presence.
            </p>
          ) : (
            <div className="space-y-3">
              <div className="flex items-center justify-center gap-3">
                <OwlIcon state="scanning" size={32} />
                <p className="text-white">Analyzing movement and facial response...</p>
              </div>

              {/* Progress Circle */}
              <div className="flex items-center justify-center">
                <div className="relative w-32 h-32">
                  <svg className="w-32 h-32 transform -rotate-90">
                    <circle
                      cx="64"
                      cy="64"
                      r="56"
                      stroke="rgba(255,255,255,0.2)"
                      strokeWidth="8"
                      fill="none"
                    />
                    <motion.circle
                      cx="64"
                      cy="64"
                      r="56"
                      stroke="url(#gradient)"
                      strokeWidth="8"
                      fill="none"
                      strokeLinecap="round"
                      initial={{ strokeDasharray: '0 352' }}
                      animate={{ strokeDasharray: `${(progress / 100) * 352} 352` }}
                      transition={{ duration: 0.1 }}
                    />
                    <defs>
                      <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" stopColor="#3A0CA3" />
                        <stop offset="100%" stopColor="#48CAE4" />
                      </linearGradient>
                    </defs>
                  </svg>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <span className="text-white text-2xl">{Math.round(progress)}%</span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </motion.div>

        {/* Security indicators */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="flex gap-2 flex-wrap justify-center"
        >
          {['Motion Tracking', 'Facial Recognition', 'Behavioral Analysis'].map((label, i) => (
            <div
              key={i}
              className="px-3 py-1 bg-cyan-400/20 rounded-full text-cyan-200 text-xs border border-cyan-400/30"
            >
              {label}
            </div>
          ))}
        </motion.div>
      </div>
    </div>
  );
};
