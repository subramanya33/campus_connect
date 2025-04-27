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
  requiredCgpa: {
    type: Number,
    required: true,
    min: 0,
    max: 10 // CGPA typically on a 10-point scale
  },
  tenthPercentage: {
    type: Number,
    required: true,
    min: 0,
    max: 100
  },
  twelfthPercentage: {
    type: Number,
    required: true,
    min: 0,
    max: 100
  },
  diplomaPercentage: {
    type: Number,
    required: false, // Optional, as not all students have diploma
    min: 0,
    max: 100
  },
  skills: {
    type: [String], // Array of strings, e.g., ["Python", "Java", "SQL"]
    required: true,
    validate: {
      validator: function(arr) {
        return arr.length > 0; // Ensure at least one skill
      },
      message: 'At least one skill is required'
    }
  },
  backlogsAllowed: {
    type: Number,
    required: true,
    min: 0 // Number of allowed backlogs
  },
  placementStatus: {
    type: String,
    required: true,
    enum: ['upcoming', 'ongoing', 'completed'], // Restrict to specific values
    default: 'upcoming' // Default to upcoming
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