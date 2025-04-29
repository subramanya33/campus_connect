const mongoose = require('mongoose');

const resumeSchema = new mongoose.Schema({
  usn: { type: String, required: true },
  format: { type: String, required: true },
  filePath: { type: String }, // Not required for legacy compatibility
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Resume', resumeSchema);