const mongoose = require('mongoose');

const resumeSchema = new mongoose.Schema(
  {
    usn: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    format: {
      type: String,
      required: true,
      enum: ['custom', 'template1', 'template2'],
      default: 'custom',
    },
    filePath: {
      type: String,
      required: true,
    },
    contentHash: {
      type: String,
      required: true,
    },
    originalFileName: {
      type: String,
      required: true,
      trim: true,
    },
    isActive: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Ensure only one resume is active per usn
resumeSchema.pre('save', async function (next) {
  if (this.isActive) {
    await this.constructor.updateMany(
      { usn: this.usn, _id: { $ne: this._id }, isActive: true },
      { $set: { isActive: false } }
    );
  }
  next();
});

module.exports = mongoose.model('Resume', resumeSchema);