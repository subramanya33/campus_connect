const express = require('express');
const jwt = require('jsonwebtoken');
const Placement = require('../models/Placement');
const Company = require('../models/company');
const Student = require('../models/student');
const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

// Authentication middleware
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log(`DEBUG: Missing or invalid Authorization header`);
      return res.status(401).json({ message: 'Authentication required' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);

    const student = await Student.findOne({ 
      usn: decoded.usn,
      _id: decoded.studentId
    });

    if (!student) {
      console.log(`DEBUG: Invalid token for USN: ${decoded.usn}`);
      return res.status(401).json({ message: 'Invalid session' });
    }

    req.student = student;
    next();
  } catch (error) {
    console.error(`DEBUG: Error in authentication: ${error.message}`);
    res.status(401).json({ message: 'Invalid or expired token' });
  }
};

// Placement endpoints
router.get('/featured', authenticate, async (req, res) => {
  try {
    const placements = await Placement.find({ placementDate: { $gte: new Date('2025-05-01'), $lte: new Date('2025-05-31') } })
      .populate('companyId', 'name package bannerImage logo')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: p.companyId.bannerImage,
      logo: p.companyId.logo,
      status: 'Featured',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    console.log('DEBUG: Fetching featured placements');
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching featured placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/ongoing', authenticate, async (req, res) => {
  try {
    const placements = await Placement.find({ placementDate: { $gte: new Date('2025-05-01'), $lte: new Date('2025-05-31') } })
      .populate('companyId', 'name package bannerImage logo')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: p.companyId.bannerImage,
      logo: p.companyId.logo,
      status: 'Ongoing',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    console.log('DEBUG: Fetching ongoing drives');
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching ongoing placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/upcoming', authenticate, async (req, res) => {
  try {
    const placements = await Placement.find({ placementDate: { $gte: new Date('2025-06-01') } })
      .populate('companyId', 'name package bannerImage logo')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: p.companyId.bannerImage,
      logo: p.companyId.logo,
      status: 'Upcoming',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    console.log('DEBUG: Fetching upcoming drives');
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching upcoming placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/completed', authenticate, async (req, res) => {
  try {
    const placements = await Placement.find({ placementDate: { $lt: new Date('2025-05-01') } })
      .populate('companyId', 'name package bannerImage logo')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: p.companyId.bannerImage,
      logo: p.companyId.logo,
      status: 'Completed',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    console.log('DEBUG: Fetching completed drives');
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching completed placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;