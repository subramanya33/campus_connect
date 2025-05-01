const mongoose = require('mongoose');

const resumeSchema = new mongoose.Schema({
  usn: { type: String, required: true, unique: true },
  format: { type: String, required: true },
  filePath: { type: String, required: true },
  updatedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Resume', resumeSchema);