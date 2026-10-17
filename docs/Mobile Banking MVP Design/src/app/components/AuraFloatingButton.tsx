import React from 'react';
import { motion } from 'motion/react';
import { OwlIcon } from './OwlIcon';

interface AuraFloatingButtonProps {
  onClick: () => void;
  state?: 'idle' | 'listening' | 'scanning' | 'alert' | 'stealth';
  hasNotification?: boolean;
  onSecureMode?: () => void;
}

export const AuraFloatingButton: React.FC<AuraFloatingButtonProps> = ({ 
  onClick, 
  state = 'idle',
  hasNotification = false,
  onSecureMode 
}) => {
  const [tapCount, setTapCount] = React.useState(0);
  const tapTimeoutRef = React.useRef<NodeJS.Timeout>();

  const handleTap = () => {
    const newCount = tapCount + 1;
    setTapCount(newCount);

    // Clear existing timeout
    if (tapTimeoutRef.current) {
      clearTimeout(tapTimeoutRef.current);
    }

    // Check for triple-tap
    if (newCount === 3) {
      console.log('🦉 Triple-tap detected - AURA Guardian SDK Activated');
      // Visual feedback
      const button = document.getElementById('aura-floating-button');
      if (button) {
        button.style.animation = 'none';
        setTimeout(() => {
          button.style.animation = 'pulse 0.5s ease-in-out 3';
        }, 10);
      }
      setTapCount(0);
      return;
    }

    // Single tap opens chat
    if (newCount === 1) {
      tapTimeoutRef.current = setTimeout(() => {
        onClick();
        setTapCount(0);
      }, 400);
    }

    // Reset count after 500ms
    tapTimeoutRef.current = setTimeout(() => {
      setTapCount(0);
    }, 500);
  };

  React.useEffect(() => {
    return () => {
      if (tapTimeoutRef.current) {
        clearTimeout(tapTimeoutRef.current);
      }
    };
  }, []);

  return (
    <motion.button
      id="aura-floating-button"
      onClick={handleTap}
      className="fixed bottom-6 right-6 w-16 h-16 bg-gradient-to-br from-[#3A0CA3] to-[#48CAE4] rounded-full shadow-2xl flex items-center justify-center z-50 border-4 border-white"
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.95 }}
      animate={{
        boxShadow: [
          '0 10px 30px rgba(58, 12, 163, 0.3)',
          '0 10px 40px rgba(72, 202, 228, 0.4)',
          '0 10px 30px rgba(58, 12, 163, 0.3)',
        ],
      }}
      transition={{
        duration: 2,
        repeat: Infinity,
        ease: 'easeInOut',
      }}
    >
      <OwlIcon state={state} size={36} />
      
      {hasNotification && (
        <motion.div
          className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 rounded-full border-2 border-white flex items-center justify-center"
          animate={{ scale: [1, 1.2, 1] }}
          transition={{ duration: 1, repeat: Infinity }}
        >
          <span className="text-white text-xs">!</span>
        </motion.div>
      )}

      {/* Ripple effect on tap */}
      <motion.div
        className="absolute inset-0 rounded-full bg-cyan-400"
        initial={{ scale: 1, opacity: 0 }}
        animate={{ scale: tapCount > 0 ? 1.5 : 1, opacity: tapCount > 0 ? 0.5 : 0 }}
        transition={{ duration: 0.3 }}
      />

      {/* Secure Mode Quick Access - Long press hint */}
      {onSecureMode && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 10 }}
          className="absolute -top-16 right-0 bg-[#0033CC] text-white text-xs px-3 py-2 rounded-lg whitespace-nowrap shadow-lg"
          style={{ display: tapCount === 2 ? 'block' : 'none' }}
        >
          🔒 Una vez más para Modo Seguro
        </motion.div>
      )}
    </motion.button>
  );
};
