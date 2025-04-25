const Counter = require('../models/Counter');

const getNextStudentId = async () => {
  const counter = await Counter.findByIdAndUpdate(
    'studentId',
    { $inc: { sequence: 1 } },
    { new: true, upsert: true }
  );
  console.log(`DEBUG: Generated studentId: STU${String(counter.sequence).padStart(3, '0')}`);
  return `STU${String(counter.sequence).padStart(3, '0')}`;
};

module.exports = { getNextStudentId };