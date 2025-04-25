const mongoose = require('mongoose');

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
  bannerImage: {
    type: String,
    required: true // Store full URL, e.g., http://192.168.1.100:3000/uploads/placement_banners/google.jpg
  },
  logo: {
    type: String,
    required: true // Store full URL, e.g., http://192.168.1.100:3000/uploads/logos/google.png
  },
  studentsApplied: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student'
  }],
}, {
  timestamps: true
});

companySchema.virtual('studentsAppliedCount').get(function() {
  return this.studentsApplied.length;
});

module.exports = mongoose.model('Company', companySchema);