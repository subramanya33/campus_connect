const express = require('express');
const jwt = require('jsonwebtoken');
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
