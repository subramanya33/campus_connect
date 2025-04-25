const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const router = express.Router();

router.get('/profile', authenticate, async (req, res) => {
  try {
    const student = req.student;
    res.status(200).json({
      studentId: student.studentId,
      usn: student.usn,
      firstName: student.firstName,
      middleName: student.middleName || '',
      lastName: student.lastName,
      fullName: `${student.firstName}${student.middleName ? ' ' + student.middleName : ''} ${student.lastName}`,
      email: student.email,
      phone: student.phone,
      address: student.address,
      dob: student.dob,
      tenthPercentage: student.tenthPercentage,
      twelfthPercentage: student.twelfthPercentage || null,
      diplomaPercentage: student.diplomaPercentage || null,
      currentCgpa: student.currentCgpa,
      noOfBacklogs: student.noOfBacklogs,
      placedStatus: student.placedStatus,
      placements: student.placements, // Array of Placement ObjectIds
    });
  } catch (error) {
    console.error(`DEBUG: Error fetching profile: ${error.message}`);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;