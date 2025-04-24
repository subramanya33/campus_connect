// routes/student.js
const express = require('express');
const bcrypt = require('bcryptjs');
const Student = require('../models/student');
const nodemailer = require('nodemailer');
const router = express.Router();

// Helper to generate 6-digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// Login Route
router.post('/login', async (req, res) => {
  const { usn, password } = req.body;

  try {
    const student = await Student.findOne({ usn });
    if (!student) return res.status(404).json({ message: 'Student not found' });

    const isMatch = await bcrypt.compare(password, student.password);
    if (!isMatch) return res.status(400).json({ message: 'Incorrect password' });

    if (student.firstLogin) {
      const otp = generateOTP();
      student.otp = otp;
      await student.save();

      // send email
      const transporter = nodemailer.createTransport({
        service: 'Gmail',
        auth: {
          user: 'your-email@gmail.com',
          pass: 'your-app-password'
        }
      });

      const mailOptions = {
        from: 'Campus Connect',
        to: student.email,
        subject: 'Reset Your Password - OTP',
        text: `Hello ${student.firstName},\n\nYour OTP to reset your password is: ${otp}\n\nThank you!`
      };

      await transporter.sendMail(mailOptions);

      return res.status(200).json({ message: 'OTP sent to email', firstLogin: true, studentId: student._id });
    }

    // success - student already reset password
    res.status(200).json({ message: 'Login successful', studentId: student._id });
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});
