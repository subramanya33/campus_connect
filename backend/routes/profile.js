const express = require('express');
const router = express.Router();
const Student = require('../models/student');
const { authenticate } = require('../middleware/authenticate');

router.get('/', authenticate, async (req, res) => {
  try {
    console.log('DEBUG: Fetching profile for USN:', req.user.usn);
    const student = await Student.findOne({ usn: req.user.usn });
    if (!student) {
      console.log('DEBUG: Student not found for USN:', req.user.usn);
      return res.status(404).json({ message: 'Student profile not found' });
    }

    // Concatenate firstName, middleName, and lastName
    const fullNameParts = [
      student.firstName || '',
      student.middleName || '',
      student.lastName || ''
    ].filter(part => part.trim() !== '');
    const fullName = fullNameParts.join(' ').trim() || 'Unknown';

    const profile = {
      usn: student.usn,
      fullName: fullName,
      studentId: student.studentId,
      email: student.email,
      phone: student.phone,
      address: student.address,
      dob: student.dob,
      tenthPercentage: student.tenthPercentage,
      twelfthPercentage: student.twelfthPercentage,
      diplomaPercentage: student.diplomaPercentage,
      currentCgpa: student.currentCgpa,
      noOfBacklogs: student.noOfBacklogs,
      placedStatus: student.placedStatus,
      placements: student.placements || [],
    };

    console.log('DEBUG: Profile fetched:', profile);
    res.status(200).json(profile);
  } catch (error) {
    console.error('DEBUG: Error fetching profile:', error);
    res.status(500).json({ message: 'Error fetching profile', error: error.message });
  }
});

module.exports = router;