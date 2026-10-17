import React from 'react';
import { motion } from 'motion/react';
import { OwlIcon } from './OwlIcon';
import { Delete } from 'lucide-react';

interface PinEntryProps {
  onComplete: (pin: string) => void;
  onSDKActivate: () => void;
}

export const PinEntry: React.FC<PinEntryProps> = ({ onComplete, onSDKActivate }) => {
  const [pin, setPin] = React.useState('');
  const [shake, setShake] = React.useState(false);

  const handleNumber = (num: string) => {
    if (pin.length < 6) {
      const newPin = pin + num;
      setPin(newPin);
      if (newPin.length === 6) {
        setTimeout(() => onComplete(newPin), 300);
      }
    }
  };

  const handleDelete = () => {
    setPin(pin.slice(0, -1));
  };

  const keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['owl', '0', 'delete']
  ];

  return (
    <div className="min-h-screen bg-white flex flex-col items-center justify-center px-6 py-8 overflow-y-auto">
      <div className="w-full max-w-sm flex flex-col items-center">
        {/* Title */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-12"
        >
          <h2 className="text-2xl text-gray-900 mb-2">Enter your PIN</h2>
          <p className="text-gray-500">Please enter your 6-digit PIN</p>
        </motion.div>

        {/* PIN Dots */}
        <motion.div
          className="flex gap-4 mb-16"
          animate={shake ? { x: [-10, 10, -10, 10, 0] } : {}}
          transition={{ duration: 0.4 }}
        >
          {[...Array(6)].map((_, i) => (
            <div
              key={i}
              className={`w-4 h-4 rounded-full border-2 transition-all ${
                i < pin.length
                  ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] border-transparent'
                  : 'border-gray-300'
              }`}
            />
          ))}
        </motion.div>

        {/* Keypad */}
        <div className="w-full space-y-3">
          {keys.map((row, rowIndex) => (
            <div key={rowIndex} className="flex gap-3 justify-center">
              {row.map((key) => {
                if (key === 'owl') {
                  return (
                    <div
                      key={key}
                      className="w-20 h-20 rounded-2xl flex items-center justify-center"
                    >
                      <OwlIcon state="idle" size={40} onTripleTap={onSDKActivate} />
                    </div>
                  );
                }
                if (key === 'delete') {
                  return (
                    <motion.button
                      key={key}
                      onClick={handleDelete}
                      className="w-20 h-20 rounded-2xl bg-gray-100 flex items-center justify-center text-gray-700"
                      whileTap={{ scale: 0.95 }}
                    >
                      <Delete size={24} />
                    </motion.button>
                  );
                }
                return (
                  <motion.button
                    key={key}
                    onClick={() => handleNumber(key)}
                    className="w-20 h-20 rounded-2xl bg-gray-100 flex items-center justify-center text-2xl text-gray-900 hover:bg-gray-200"
                    whileTap={{ scale: 0.95 }}
                  >
                    {key}
                  </motion.button>
                );
              })}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
