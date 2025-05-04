const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  firstName: { type: String, required: true },
  middleName: { type: String },
  lastName: { type: String, required: true },
  studentId: { type: String, required: true, unique: true },
  usn: { type: String, required: true, unique: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  currentCgpa: { type: Number, required: true, min: 0, max: 10 },
  tenthPercentage: { type: Number, required: true, min: 0, max: 100 },
  twelfthPercentage: { type: Number, min: 0, max: 100 },
  diplomaPercentage: { type: Number, min: 0, max: 100 },
  noOfBacklogs: { type: Number, required: true, min: 0 },
  phone: { type: String, required: true },
  address: { type: String, required: true },
  dob: { type: Date, required: true },
  firstLogin: { type: Boolean, default: true },
  otp: { type: String },
  placedStatus: { type: Boolean, default: false },
  placements: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Placement' }],
  profilePic: { type: String, default: '/Uploads/profile_pics/default.jpg' }
}, {
  timestamps: true
});

module.exports = mongoose.models.Student || mongoose.model('Student', studentSchema);