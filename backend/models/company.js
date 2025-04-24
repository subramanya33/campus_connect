const mongoose = require('mongoose');

// Define the Company schema
const companySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  sector: {
    type: String,
    required: true
  },
  location: {
    type: String,
    required: true
  },
  jobProfile: {
    type: String,
    required: true
  },
  category: {
    type: String,
    required: true
  },
  package: {
    type: Number,
    required: true
  },
  studentsApplied: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student' // Corrected from 'students' to 'Student'
  }],
}, {
  timestamps: true
});

// Virtual field to calculate number of students applied
companySchema.virtual('studentsAppliedCount').get(function() {
  return this.studentsApplied.length;
});

module.exports = mongoose.model('Company', companySchema);