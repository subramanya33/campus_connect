const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  firstName: { type: String, required: true },
  middleName: { type: String },
  lastName: { type: String, required: true },
  studentId: { type: String, unique: true }, // Auto-generated
  usn: { type: String, required: true, unique: true },
  dob: { type: Date, required: true },
  tenthPercentage: { type: Number, required: true },
  twelfthPercentage: {
    type: Number,
    required: false,
    validate: {
      validator: function(value) {
        if (this.diplomaPercentage && value === null) return true;
        return !this.diplomaPercentage || value !== null;
      },
      message: '12th Percentage is required for students who do not have a diploma.'
    }
  },
  diplomaPercentage: {
    type: Number,
    required: false,
    validate: {
      validator: function(value) {
        if (!this.diplomaPercentage && value !== null) return false;
        return true;
      },
      message: 'Diploma percentage is required for students with a diploma.'
    }
  },
  currentCgpa: { type: Number, required: true },
  noOfBacklogs: { type: Number, required: true },
  placedStatus: { type: Boolean, default: false },
  phone: { type: String, required: true },
  email: { type: String, required: true, unique: true, match: [/\S+@\S+\.\S+/, 'Please enter a valid email address'] },
  address: { type: String, required: true },
  password: { type: String },
  firstLogin: { type: Boolean, default: true },
  otp: { type: String },
  placements: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Placement' }],
}, { timestamps: true });

module.exports = mongoose.model('students', studentSchema);