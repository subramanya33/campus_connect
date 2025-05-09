const mongoose = require('mongoose');

const CompanySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  bannerImage: {
    type: String,
  },
  logo: {
    type: String,
  },
  sector: {
    type: String,
  },
  jobProfile: {
    type: String,
  },
  package: {
    type: Number,
  },
  requiredCgpa: {
    type: Number,
  },
  requiredPercentage: {
    type: Number,
    default: 80.0,
  },
  skills: {
    type: [String],
    default: [],
  },
  studentsApplied: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
  }],
  placementStatus: {
    type: String,
    enum: ['upcoming', 'ongoing', 'completed'],
    default: 'upcoming',
  },
});

module.exports = mongoose.model('Company', CompanySchema);