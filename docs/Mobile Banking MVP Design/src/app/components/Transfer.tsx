import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, User, DollarSign, MessageSquare } from 'lucide-react';

interface TransferProps {
  onBack: () => void;
  onConfirm: (data: { recipient: string; amount: number; concept: string }) => void;
}

export const Transfer: React.FC<TransferProps> = ({ onBack, onConfirm }) => {
  const [recipient, setRecipient] = React.useState('');
  const [amount, setAmount] = React.useState('');
  const [concept, setConcept] = React.useState('');

  const handleConfirm = () => {
    if (recipient && amount && parseFloat(amount) > 0) {
      onConfirm({
        recipient,
        amount: parseFloat(amount),
        concept: concept || 'Transfer',
      });
    }
  };

  return (
    <div className="min-h-screen bg-white overflow-y-auto">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#0033CC] to-[#001A66] pt-12 pb-8 px-6">
        <div className="flex items-center gap-4 mb-4">
          <motion.button
            onClick={onBack}
            className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="text-white" size={20} />
          </motion.button>
          <h1 className="text-white text-2xl">Transfer Money</h1>
        </div>
      </div>

      {/* Form */}
      <div className="px-6 py-8 space-y-6">
        {/* Recipient */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
        >
          <label className="text-gray-700 text-sm mb-2 block">Recipient</label>
          <div className="relative">
            <User className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
            <input
              type="text"
              value={recipient}
              onChange={(e) => setRecipient(e.target.value)}
              placeholder="Enter name or account number"
              className="w-full pl-12 pr-4 py-4 bg-gray-50 rounded-2xl border border-gray-200 focus:border-[#0033CC] focus:outline-none transition-colors"
            />
          </div>
        </motion.div>

        {/* Amount */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          <label className="text-gray-700 text-sm mb-2 block">Amount (S/)</label>
          <div className="relative">
            <DollarSign className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              className="w-full pl-12 pr-4 py-4 bg-gray-50 rounded-2xl border border-gray-200 focus:border-[#0033CC] focus:outline-none transition-colors text-2xl"
              step="0.01"
            />
          </div>
        </motion.div>

        {/* Quick amounts */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="flex gap-2"
        >
          {[50, 100, 500, 1000].map((value) => (
            <button
              key={value}
              onClick={() => setAmount(value.toString())}
              className="flex-1 py-2 bg-gray-100 rounded-xl text-gray-700 text-sm hover:bg-gray-200 transition-colors"
            >
              S/ {value}
            </button>
          ))}
        </motion.div>

        {/* Concept */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
        >
          <label className="text-gray-700 text-sm mb-2 block">Concept (Optional)</label>
          <div className="relative">
            <MessageSquare className="absolute left-4 top-4 text-gray-400" size={20} />
            <textarea
              value={concept}
              onChange={(e) => setConcept(e.target.value)}
              placeholder="What's this for?"
              className="w-full pl-12 pr-4 py-4 bg-gray-50 rounded-2xl border border-gray-200 focus:border-[#0033CC] focus:outline-none transition-colors resize-none"
              rows={3}
            />
          </div>
        </motion.div>

        {/* Summary */}
        {amount && parseFloat(amount) > 0 && (
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-gradient-to-r from-cyan-50 to-blue-50 rounded-2xl p-4 border border-cyan-200"
          >
            <p className="text-gray-600 text-sm mb-2">Transfer Summary</p>
            <div className="space-y-1">
              <div className="flex justify-between">
                <span className="text-gray-700 text-sm">Amount:</span>
                <span className="text-gray-900">S/ {parseFloat(amount).toFixed(2)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-700 text-sm">Fee:</span>
                <span className="text-gray-900">S/ 0.00</span>
              </div>
              <div className="h-px bg-gray-300 my-2" />
              <div className="flex justify-between">
                <span className="text-gray-900">Total:</span>
                <span className="text-gray-900">S/ {parseFloat(amount).toFixed(2)}</span>
              </div>
            </div>
          </motion.div>
        )}

        {/* Confirm Button */}
        <motion.button
          onClick={handleConfirm}
          disabled={!recipient || !amount || parseFloat(amount) <= 0}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="w-full py-4 rounded-2xl bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white disabled:opacity-50 disabled:cursor-not-allowed shadow-lg"
          whileTap={{ scale: 0.98 }}
        >
          Confirm Transfer
        </motion.button>
      </div>
    </div>
  );
};
