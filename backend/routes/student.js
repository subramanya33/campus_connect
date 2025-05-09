const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const Student = require('../models/student');
const Placement = require('../models/Placement');
const Company = require('../models/company');
const Application = require('../models/Application');
const router = express.Router();

// Update student profile
router.put('/me', authenticate, async (req, res) => {
  const updates = req.body;
  try {
    const student = await Student.findByIdAndUpdate(req.student._id, updates, { new: true });
    res.json({ message: 'Profile updated', student });
  } catch (error) {
    console.error(`DEBUG: Error updating profile: ${error.message}`);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Apply for a placement
router.post('/apply/:placementId', authenticate, async (req, res) => {
  try {
    const placement = await Placement.findById(req.params.placementId);
    if (!placement) {
      return res.status(404).json({ message: 'Placement not found' });
    }
    const company = await Company.findById(placement.companyId);
    if (!company) {
      return res.status(404).json({ message: 'Company not found' });
    }
    if (company.placementStatus !== 'upcoming') {
      return res.status(400).json({ message: 'Cannot apply to non-upcoming drives' });
    }
    const student = req.student;
    const existingApplication = await Application.findOne({
      placementId: req.params.placementId,
      studentId: student._id,
    });
    if (existingApplication || student.placements.includes(placement._id)) {
      return res.status(400).json({ message: 'Already applied' });
    }

    const { resumeId } = req.body;
    const applicationData = {
      placementId: placement._id,
      companyId: placement.companyId,
      studentId: student._id,
    };
    if (resumeId) {
      applicationData.resumeId = resumeId;
    }

    const application = new Application(applicationData);
    await application.save();

    student.placements.push(placement._id);
    placement.appliedStudents.push(student._id);
    company.studentsApplied.push(student._id);
    await student.save();
    await placement.save();
    await company.save();

    console.log(`DEBUG: Student ${student._id} applied for placement ${req.params.placementId} with resumeId: ${resumeId || 'none'}`);
    res.json({ message: 'Applied successfully' });
  } catch (error) {
    console.error(`DEBUG: Error applying for placement: ${error.message}`);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// View applied placements
router.get('/me/placements', authenticate, async (req, res) => {
  try {
    const student = await Student.findById(req.student._id).populate('placements');
    res.json(student.placements);
  } catch (error) {
    console.error(`DEBUG: Error fetching placements: ${error.message}`);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;