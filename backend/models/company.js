const mongoose = require('mongoose');

const companySchema = new mongoose.Schema({
  name: { type: String, required: true },
  sector: { type: String, required: true },
  location: { type: String, required: true },
  jobProfile: { type: String, required: true },
  category: { type: String, required: true },
  package: { type: Number, required: true },
  bannerImage: { type: String, required: true },
  logo: { type: String, required: true },
  requiredCgpa: { type: Number, required: true, min: 0, max: 10 },
  tenthPercentage: { type: Number, required: true, min: 0, max: 100 },
  twelfthPercentage: { type: Number, required: true, min: 0, max: 100 },
  diplomaPercentage: { type: Number, min: 0, max: 100 },
  skills: {
    type: [String],
    required: true,
    validate: {
      validator: arr => arr.length > 0,
      message: 'At least one skill is required'
    }
  },
  backlogsAllowed: { type: Number, required: true, min: 0 },
  placementStatus: {
    type: String,
    required: true,
    enum: ['upcoming', 'ongoing', 'completed'],
    default: 'upcoming'
  },
  studentsApplied: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }],
}, {
  timestamps: true
});

module.exports = mongoose.models.Company || mongoose.model('Company', companySchema);