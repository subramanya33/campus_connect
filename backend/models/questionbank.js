const mongoose = require('mongoose');

const QuestionBankSchema = new mongoose.Schema({
  category: {
    type: String,
    required: true,
    enum: ['Aptitude Round', 'Technical Round', 'HR Round', 'Managerial Round', 'Group Discussion', 'Coding Round'],
  },
  companyId: { type: String, required: true },
  companyName: { type: String, required: true },
  questions: [
    {
      year: { type: String, required: true }, // e.g., "2023-24"
      question: { type: String, required: true },
      answer: { type: String, required: true },
    },
  ],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('QuestionBank', QuestionBankSchema);