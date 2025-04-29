const jwt = require('jsonwebtoken');
const Student = require('../models/student');
const dotenv = require('dotenv');

dotenv.config();

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    console.log('DEBUG: Auth Header:', authHeader);
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log(`DEBUG: Missing or invalid Authorization header`);
      return res.status(401).json({ message: 'Authentication required' });
    }

    const token = authHeader.split(' ')[1];
    console.log('DEBUG: Token:', token);
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('DEBUG: Decoded Token:', decoded);

    const student = await Student.findOne({
      usn: decoded.usn,
      _id: decoded.studentId,
    });

    if (!student) {
      console.log(`DEBUG: Invalid token for USN: ${decoded.usn}`);
      return res.status(401).json({ message: 'Invalid session' });
    }

    req.student = student;
    req.user = { usn: student.usn, studentId: student._id, isAdmin: decoded.isAdmin || false };
    next();
  } catch (error) {
    console.error(`DEBUG: Error in authentication: ${error.message}`);
    res.status(401).json({ message: 'Invalid or expired token' });
  }
};

module.exports = { authenticate };