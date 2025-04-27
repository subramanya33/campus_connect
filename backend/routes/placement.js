const express = require('express');
const jwt = require('jsonwebtoken');
const Placement = require('../models/Placement');
const Company = require('../models/company');
const Student = require('../models/student');
const QuestionBank = require('../models/questionbank');
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
    const placements = await Placement.find({ placementDate: { $gte: new Date('2025-06-01') } })
      .populate('companyId', 'name package bannerImage logo')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: p.companyId ? p.companyId.bannerImage || '' : '',
      logo: p.companyId ? p.companyId.logo || '' : '',
      status: 'Featured',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    console.log(`DEBUG: Fetched ${formattedPlacements.length} featured placements`);
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching featured placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/ongoing', authenticate, async (req, res) => {
  try {
    const today = new Date();
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);
    const placements = await Placement.find({ 
      placementDate: { $gte: startOfMonth, $lte: endOfMonth } 
    })
      .populate('companyId', 'name package bannerImage logo')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: p.companyId ? p.companyId.bannerImage || '' : '',
      logo: p.companyId ? p.companyId.logo || '' : '',
      status: 'Ongoing',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    console.log(`DEBUG: Fetched ${formattedPlacements.length} ongoing placements`);
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching ongoing placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

router.get('/upcoming', authenticate, async (req, res) => {
  try {
    const placements = await Placement.find({
      placementDate: { $gte: new Date() },
    }).populate('companyId');
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: p.companyId ? p.companyId.bannerImage || '' : '',
      logo: p.companyId ? p.companyId.logo || '' : '',
      status: 'Upcoming',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    res.json(formattedPlacements);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
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
      bannerImage: p.companyId ? p.companyId.bannerImage || '' : '',
      logo: p.companyId ? p.companyId.logo || '' : '',
      status: 'Completed',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    console.log(`DEBUG: Fetched ${formattedPlacements.length} completed placements`);
    res.status(200).json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching completed placements:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Question Banks Route
router.get('/question-banks', authenticate, async (req, res) => {
  try {
    const questionBanks = await QuestionBank.aggregate([
      {
        $group: {
          _id: '$category',
          companies: {
            $push: {
              companyId: '$companyId',
              name: '$companyName',
              questions: '$questions',
            },
          },
        },
      },
      {
        $project: {
          category: '$_id',
          companies: 1,
          _id: 0,
        },
      },
      {
        $sort: { category: 1 },
      },
    ]);
    console.log(`DEBUG: Fetched ${questionBanks.length} question bank categories`);
    res.status(200).json(questionBanks);
  } catch (error) {
    console.error(`DEBUG: Error fetching question banks: ${error.message}`);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;