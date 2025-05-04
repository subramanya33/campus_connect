const mongoose = require('mongoose');

const roundSchema = new mongoose.Schema({
  placementId: { type: mongoose.Schema.Types.ObjectId, ref: 'Placement', required: true },
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
  roundNumber: { type: Number, required: true, min: 1 },
  roundName: { type: String, required: true },
  shortlistedStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }],
  status: {
    type: String,
    enum: ['pending', 'ongoing', 'completed'],
    default: 'pending'
  },
}, {
  timestamps: true
});

module.exports = mongoose.model('Round', roundSchema);