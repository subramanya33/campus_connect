const express = require('express');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');
const Student = require('../models/student');
const Counter = require('../models/Counter');
const router = express.Router();

const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

const getNextStudentId = async () => {
  const counter = await Counter.findByIdAndUpdate(
    'studentId',
    { $inc: { sequence: 1 } },
    { new: true, upsert: true }
  );
  console.log(`DEBUG: Generated studentId: STU${String(counter.sequence).padStart(3, '0')}`);
  return `STU${String(counter.sequence).padStart(3, '0')}`;
};

router.post('/register', async (req, res) => {
  const {
    firstName, middleName, lastName, usn, dob, tenthPercentage,
    twelfthPercentage, diplomaPercentage, currentCgpa, noOfBacklogs,
    phone, email, address, password
  } = req.body;

  console.log(`DEBUG: Register attempt for USN: ${usn}, Email: ${email}`);
  try {
    if (!firstName || !lastName || !usn || !dob || !tenthPercentage ||
        !currentCgpa || !noOfBacklogs || !phone || !email || !address || !password) {
      console.log(`DEBUG: Missing required fields in register request`);
      return res.status(400).json({ message: 'All required fields must be provided' });
    }

    const existing = await Student.findOne({ $or: [{ usn }, { email }] });
    if (existing) {
      console.log(`DEBUG: USN or email already exists: ${JSON.stringify(existing)}`);
      return res.status(400).json({ message: 'USN or email already exists' });
    }

    const studentId = await getNextStudentId();
    const hashedPassword = await bcrypt.hash(password, 10);

    const student = new Student({
      firstName,
      middleName,
      lastName,
      studentId,
      usn: usn.toUpperCase(),
      dob: new Date(dob),
      tenthPercentage,
      twelfthPercentage,
      diplomaPercentage,
      currentCgpa,
      noOfBacklogs,
      placedStatus: false,
      phone,
      email: email.toLowerCase(),
      address,
      password: hashedPassword,
      firstLogin: true,
      otp: null,
      placements: [],
    });

    await student.save();
    console.log(`DEBUG: Student registered: ${studentId}, USN: ${usn}`);
    res.status(201).json({ message: 'Student registered successfully', studentId: student._id });
  } catch (err) {
    console.error(`DEBUG: Error registering student: ${err.message}`);
    if (err.code === 11000) {
      return res.status(400).json({ message: `Duplicate key error: ${JSON.stringify(err.keyValue)}` });
    }
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/check-login-status', async (req, res) => {
  const { usn } = req.body;
  console.log(`DEBUG: Checking login status for USN: ${usn}`);

  try {
    const student = await Student.findOne({ usn: usn.toUpperCase() });
    if (!student) {
      console.log(`DEBUG: Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    console.log(`DEBUG: Found student: ${usn}, firstLogin: ${student.firstLogin}`);
    res.status(200).json({ firstLogin: student.firstLogin, studentId: student._id });
  } catch (err) {
    console.error(`DEBUG: Error checking login status: ${err.message}`);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/login', async (req, res) => {
  const { usn, password } = req.body;
  console.log(`DEBUG: Login attempt for USN: ${usn}, Password provided: ${password ? 'Yes' : 'No'}`);

  try {
    const student = await Student.findOne({ usn: usn.toUpperCase() });
    if (!student) {
      console.log(`DEBUG: Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    if (student.firstLogin) {
      const otp = generateOTP();
      student.otp = otp;
      await student.save();
      console.log(`DEBUG: Generated OTP: ${otp} for USN: ${usn}`);

      const transporter = nodemailer.createTransport({
        service: 'Gmail',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS,
        },
      });

      const mailOptions = {
        from: 'Campus Connect',
        to: student.email,
        subject: 'Set Your Password - OTP',
        text: `Hello ${student.firstName},\n\nYour OTP to set your password is: ${otp}\n\nThank you!`,
      };

      await transporter.sendMail(mailOptions);
      console.log(`DEBUG: OTP sent to ${student.email} for USN: ${usn}`);
      return res.status(200).json({ message: 'OTP sent to email', firstLogin: true, studentId: student._id });
    }

    const isMatch = await bcrypt.compare(password, student.password);
    if (!isMatch) {
      console.log(`DEBUG: Incorrect password for USN: ${usn}`);
      return res.status(400).json({ message: 'Incorrect password' });
    }

    student.firstLogin = false;
    await student.save();
    console.log(`DEBUG: Login successful, firstLogin set to false for USN: ${usn}`);

    res.status(200).json({ message: 'Login successful', studentId: student._id });
  } catch (err) {
    console.error(`DEBUG: Error logging in: ${err.message}`);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/forgot-password', async (req, res) => {
  const { usn, email } = req.body;
  console.log(`DEBUG: Forgot password request for USN: ${usn}, Email: ${email}`);

  try {
    const student = await Student.findOne({ usn: usn.toUpperCase() });
    if (!student) {
      console.log(`DEBUG: Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    const expectedEmail = `${usn.toLowerCase()}@mite.ac.in`;
    if (email.toLowerCase() !== expectedEmail) {
      console.log(`DEBUG: Invalid email. Expected: ${expectedEmail}, Received: ${email}`);
      return res.status(400).json({ message: `Email must be ${expectedEmail}` });
    }

    const otp = generateOTP();
    student.otp = otp;
    await student.save();
    console.log(`DEBUG: Generated OTP: ${otp} for USN: ${usn}`);

    const transporter = nodemailer.createTransport({
      service: 'Gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    const mailOptions = {
      from: 'Campus Connect',
      to: email,
      subject: student.firstLogin ? 'Set Your Password - OTP' : 'Forgot Password - OTP',
      text: `Hello ${student.firstName},\n\nYour OTP to ${student.firstLogin ? 'set' : 'reset'} your password is: ${otp}\n\nThank you!`,
    };

    await transporter.sendMail(mailOptions);
    console.log(`DEBUG: OTP sent to ${email} for USN: ${usn}`);
    res.status(200).json({ message: 'OTP sent to email' });
  } catch (err) {
    console.error(`DEBUG: Error requesting OTP: ${err.message}`);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/verify-otp', async (req, res) => {
  const { usn, otp } = req.body;
  console.log(`DEBUG: Verifying OTP for USN: ${usn}, OTP: ${otp}`);

  try {
    const student = await Student.findOne({ usn: usn.toUpperCase() });
    if (!student) {
      console.log(`DEBUG: Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    if (student.otp !== otp) {
      console.log(`DEBUG: Invalid OTP for USN: ${usn}. Expected: ${student.otp}, Received: ${otp}`);
      return res.status(400).json({ message: 'Invalid OTP' });
    }

    student.otp = null;
    await student.save();
    console.log(`DEBUG: OTP verified for USN: ${usn}`);

    res.status(200).json({ message: 'OTP verified successfully' });
  } catch (err) {
    console.error(`DEBUG: Error verifying OTP: ${err.message}`);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

router.post('/reset-password', async (req, res) => {
  const { usn, newPassword } = req.body;
  console.log(`DEBUG: Reset password request for USN: ${usn}`);

  try {
    const student = await Student.findOne({ usn: usn.toUpperCase() });
    if (!student) {
      console.log(`DEBUG: Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    student.password = await bcrypt.hash(newPassword, 10);
    student.firstLogin = false;
    await student.save();
    console.log(`DEBUG: Password reset and firstLogin set to false for USN: ${usn}`);

    res.status(200).json({ message: 'Password reset successfully' });
  } catch (err) {
    console.error(`DEBUG: Error resetting password: ${err.message}`);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;