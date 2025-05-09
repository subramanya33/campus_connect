const express = require('express');
const jwt = require('jsonwebtoken');
const Placement = require('../models/Placement');
const Company = require('../models/company');
const Student = require('../models/student');
const Round = require('../models/Round');
const Application = require('../models/Application');

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
    const decoded = jwt.verify(token, JWT_SECRET, { clockTolerance: 86400 });

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

// Helper function to format placement data
const formatPlacement = (p) => {
  const today = new Date();
  let status = 'upcoming';
  if (p.placementDate < today) {
    status = 'completed';
  } else if (p.placementDate.toDateString() === today.toDateString()) {
    status = 'ongoing';
  }

  return {
    _id: p._id.toString(),
    company: p.companyId ? p.companyId.name : p.companyName,
    bannerImage: p.companyId ? p.companyId.bannerImage || '' : '',
    logo: p.companyId ? p.companyId.logo || '' : '',
    status,
    driveDate: p.placementDate.toISOString().split('T')[0],
    sector: p.companyId ? p.companyId.sector || 'N/A' : 'N/A',
    jobProfile: p.companyId ? p.companyId.jobProfile || 'N/A' : 'N/A',
    package: p.companyId ? p.companyId.package || 0 : 0,
    requiredCgpa: p.companyId ? p.companyId.requiredCgpa || 0 : 0,
    requiredPercentage: p.companyId ? p.companyId.requiredPercentage || 80.0 : 80.0,
    skills: p.companyId ? p.companyId.skills || [] : [],
  };
};

// Fetch Featured Placements
router.get('/featured', authenticate, async (req, res) => {
  try {
    const today = new Date();
    const threeMonthsLater = new Date(today);
    threeMonthsLater.setMonth(today.getMonth() + 3);
    
    const placements = await Placement.find({ 
      placementDate: { $gte: today, $lte: threeMonthsLater } 
    })
      .populate('companyId')
      .lean();
    const formattedPlacements = placements.map(formatPlacement);
    console.log(`DEBUG: Fetched ${formattedPlacements.length} featured placements`);
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching featured placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Fetch Ongoing Placements
router.get('/ongoing', authenticate, async (req, res) => {
  try {
    const today = new Date();
    const startOfDay = new Date(today.setHours(0, 0, 0, 0));
    const endOfDay = new Date(today.setHours(23, 59, 59, 999));
    
    const placements = await Placement.find({ 
      placementDate: { $gte: startOfDay, $lte: endOfDay } 
    })
      .populate('companyId')
      .lean();
    const formattedPlacements = placements.map(formatPlacement);
    console.log(`DEBUG: Fetched ${formattedPlacements.length} ongoing placements`);
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching ongoing placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Fetch Upcoming Placements
router.get('/upcoming', authenticate, async (req, res) => {
  try {
    const today = new Date();
    const placements = await Placement.find({
      placementDate: { $gt: today },
    })
      .populate('companyId')
      .lean();
    const formattedPlacements = placements.map(formatPlacement);
    console.log(`DEBUG: Fetched ${formattedPlacements.length} upcoming placements`);
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching upcoming placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Fetch Completed Placements
router.get('/completed', authenticate, async (req, res) => {
  try {
    const today = new Date();
    const placements = await Placement.find({ 
      placementDate: { $lt: today } 
    })
      .populate('companyId')
      .lean();
    const formattedPlacements = placements.map(formatPlacement);
    console.log(`DEBUG: Fetched ${formattedPlacements.length} completed placements`);
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching completed placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Fetch Round Status for Ongoing Drives
router.get('/:placementId/round-status', authenticate, async (req, res) => {
  try {
    const studentId = req.student._id;
    const rounds = await Round.find({ placementId: req.params.placementId })
      .sort({ roundNumber: -1 })
      .limit(1);
    if (!rounds.length) {
      return res.status(404).json({ message: 'No rounds found' });
    }
    const currentRound = rounds[0];
    const isShortlisted = currentRound.shortlistedStudents.includes(studentId);
    res.json({
      currentRound: currentRound.roundName,
      isShortlisted,
    });
    console.log(`DEBUG: Fetched round status for placement ${req.params.placementId}`);
  } catch (error) {
    console.error('Error fetching round status:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Check Application Status for Upcoming Drives
router.get('/:placementId/application-status', authenticate, async (req, res) => {
  try {
    const studentId = req.student._id;
    const placement = await Placement.findById(req.params.placementId);
    if (!placement) {
      return res.status(404).json({ message: 'Placement not found' });
    }
    const application = await Application.findOne({
      placementId: req.params.placementId,
      studentId,
    });
    const hasApplied = !!application;
    res.json({ hasApplied });
    console.log(`DEBUG: Checked application status for placement ${req.params.placementId}: hasApplied=${hasApplied}`);
  } catch (error) {
    console.error('Error checking application status:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Fetch Shortlist Results for Completed Drives
router.get('/:placementId/shortlist-results', authenticate, async (req, res) => {
  try {
    const rounds = await Round.find({ placementId: req.params.placementId })
      .populate('shortlistedStudents', 'firstName lastName usn');
    const shortlistedStudents = rounds.reduce((acc, round) => {
      return [...acc, ...round.shortlistedStudents.map(s => ({
        firstName: s.firstName,
        lastName: s.lastName,
        usn: s.usn
      }))];
    }, []);
    res.json(shortlistedStudents);
    console.log(`DEBUG: Fetched shortlist results for placement ${req.params.placementId}`);
  } catch (error) {
    console.error('Error fetching shortlist results:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;