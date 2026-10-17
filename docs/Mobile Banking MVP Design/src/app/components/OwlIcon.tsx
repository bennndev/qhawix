import React from 'react';
import { motion } from 'motion/react';

interface OwlIconProps {
  state?: 'idle' | 'listening' | 'scanning' | 'alert' | 'stealth';
  size?: number;
  onTripleTap?: () => void;
}

export const OwlIcon: React.FC<OwlIconProps> = ({ state = 'idle', size = 40, onTripleTap }) => {
  const [tapCount, setTapCount] = React.useState(0);
  const [lastTap, setLastTap] = React.useState(0);

  const handleTap = () => {
    const now = Date.now();
    if (now - lastTap < 500) {
      const newCount = tapCount + 1;
      setTapCount(newCount);
      if (newCount >= 3 && onTripleTap) {
        onTripleTap();
        setTapCount(0);
      }
    } else {
      setTapCount(1);
    }
    setLastTap(now);
  };

  const getColors = () => {
    switch (state) {
      case 'listening':
        return { fill: '#48CAE4', glow: '#48CAE4' };
      case 'scanning':
        return { fill: '#3A0CA3', glow: '#48CAE4' };
      case 'alert':
        return { fill: '#EF4444', glow: '#EF4444' };
      case 'stealth':
        return { fill: '#FFFFFF', glow: 'none' };
      default:
        return { fill: '#FFFFFF', glow: 'none' };
    }
  };

  const colors = getColors();
  const opacity = state === 'stealth' ? 0.1 : 1;

  return (
    <motion.div
      onClick={handleTap}
      className="cursor-pointer relative inline-flex items-center justify-center"
      animate={
        state === 'listening'
          ? { scale: [1, 1.1, 1] }
          : state === 'alert'
          ? { x: [-2, 2, -2, 2, 0] }
          : {}
      }
      transition={{ duration: 0.5, repeat: state === 'listening' ? Infinity : 0 }}
      style={{ opacity }}
    >
      {state === 'scanning' && (
        <motion.div
          className="absolute rounded-full"
          style={{
            width: size * 1.8,
            height: size * 1.8,
            border: `2px solid ${colors.glow}`,
            opacity: 0.6,
          }}
          animate={{ scale: [1, 1.4], opacity: [0.6, 0] }}
          transition={{ duration: 1.5, repeat: Infinity }}
        />
      )}
      
      {(state === 'listening' || state === 'scanning') && (
        <motion.div
          className="absolute rounded-full"
          style={{
            width: size * 1.5,
            height: size * 1.5,
            background: `radial-gradient(circle, ${colors.glow}40, transparent)`,
          }}
          animate={{ opacity: [0.3, 0.6, 0.3] }}
          transition={{ duration: 2, repeat: Infinity }}
        />
      )}

      <svg
        width={size}
        height={size}
        viewBox="0 0 100 100"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        {/* Owl body */}
        <ellipse cx="50" cy="60" rx="30" ry="35" fill={colors.fill} stroke="#000000" strokeWidth="2" />
        
        {/* Owl eyes */}
        <circle cx="40" cy="50" r="10" fill="#FFFFFF" stroke="#000000" strokeWidth="2" />
        <circle cx="60" cy="50" r="10" fill="#FFFFFF" stroke="#000000" strokeWidth="2" />
        
        {/* Pupils */}
        <motion.circle
          cx="40"
          cy="50"
          r="5"
          fill="#000000"
          animate={state === 'listening' ? { scale: [1, 0.8, 1] } : {}}
          transition={{ duration: 0.3, repeat: state === 'listening' ? Infinity : 0, repeatDelay: 2 }}
        />
        <motion.circle
          cx="60"
          cy="50"
          r="5"
          fill="#000000"
          animate={state === 'listening' ? { scale: [1, 0.8, 1] } : {}}
          transition={{ duration: 0.3, repeat: state === 'listening' ? Infinity : 0, repeatDelay: 2 }}
        />
        
        {/* Beak */}
        <path d="M50 55 L45 65 L55 65 Z" fill="#FFA500" stroke="#000000" strokeWidth="1.5" />
        
        {/* Ear tufts */}
        <path d="M25 30 L30 20 L35 30" fill={colors.fill} stroke="#000000" strokeWidth="2" />
        <path d="M75 30 L70 20 L65 30" fill={colors.fill} stroke="#000000" strokeWidth="2" />
      </svg>
    </motion.div>
  );
};
