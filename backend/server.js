const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const Student = require('./models/Student'); // Assuming Student.js exists
const Placement = require('./models/Placement');
const Company = require('./models/Company');

const app = express();
app.use(cors());
app.use(express.json());

// Serve static files (profile pics, placement banners, logos)
app.use('/uploads', express.static(path.join(__dirname, 'Uploads')));

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/Campus_connect').then(() => {
  console.log('Connected to MongoDB');
}).catch((error) => {
  console.error('MongoDB connection error:', error);
});

// Initialize sample data
const initializeData = async () => {
  try {
    // Sample student
    const studentCount = await Student.countDocuments();
    if (studentCount === 0) {
      const student = await Student.create({
        usn: '4MT21AI058',
        fullName: 'Subbu Krishna',
        email: '4mt21ai058@mite.ac.in',
        password: 'newpassword123',
        firstLogin: false,
      });
      console.log('Sample student created:', student.usn);
    }

    // Sample companies
    const companyCount = await Company.countDocuments();
    if (companyCount === 0) {
      const companies = await Company.insertMany([
        {
          name: 'Google',
          sector: 'Technology',
          location: 'Bangalore',
          jobProfile: 'Software Engineer',
          category: 'Technical',
          package: 3000000,
          studentsApplied: [],
        },
        {
          name: 'Microsoft',
          sector: 'Technology',
          location: 'Hyderabad',
          jobProfile: 'Cloud Engineer',
          category: 'Technical',
          package: 2800000,
          studentsApplied: [],
        },
        {
          name: 'Amazon',
          sector: 'E-commerce',
          location: 'Bangalore',
          jobProfile: 'DevOps Engineer',
          category: 'Technical',
          package: 3200000,
          studentsApplied: [],
        },
        {
          name: 'Tesla',
          sector: 'Automotive',
          location: 'Mumbai',
          jobProfile: 'AI Engineer',
          category: 'Technical',
          package: 3500000,
          studentsApplied: [],
        },
      ]);
      console.log('Sample companies created:', companies.length);

      // Sample placements
      const student = await Student.findOne({ usn: '4MT21AI058' });
      if (student) {
        const placements = await Placement.insertMany([
          {
            studentId: student._id,
            studentName: student.fullName,
            companyId: companies[0]._id,
            companyName: companies[0].name,
            packageOffered: companies[0].package,
            placementDate: new Date('2025-05-10'),
          },
          {
            studentId: student._id,
            studentName: student.fullName,
            companyId: companies[1]._id,
            companyName: companies[1].name,
            packageOffered: companies[1].package,
            placementDate: new Date('2025-04-25'),
          },
        ]);
        console.log('Sample placements created:', placements.length);
      }
    }
  } catch (error) {
    console.error('Error initializing data:', error);
  }
};
initializeData();

// Login Endpoint
app.post('/api/students/login', async (req, res) => {
  try {
    const { usn, password } = req.body;
    if (!usn || !password) {
      return res.status(400).json({ message: 'USN and password are required' });
    }

    console.log(`Login attempt - USN: ${usn}, Password: ${password}`);
    const student = await Student.findOne({ usn: usn.trim().toUpperCase() });
    if (!student) {
      console.log(`Student not found for USN: ${usn}`);
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (student.password !== password) {
      console.log(`Password mismatch for USN: ${usn}`);
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    res.json({
      message: 'Login successful',
      studentId: student._id,
      firstLogin: student.firstLogin,
    });
  } catch (error) {
    console.error('Error in login:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Check Login Status Endpoint
app.post('/api/students/check-login-status', async (req, res) => {
  try {
    const { usn } = req.body;
    if (!usn) {
      return res.status(400).json({ message: 'USN is required' });
    }

    console.log(`Checking login status for USN: ${usn}`);
    const student = await Student.findOne({ usn: usn.trim().toUpperCase() });
    if (!student) {
      console.log(`Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    res.json({ firstLogin: student.firstLogin });
  } catch (error) {
    console.error('Error in check-login-status:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Request OTP Endpoint
app.post('/api/students/forgot-password', async (req, res) => {
  try {
    const { usn, email } = req.body;
    if (!usn || !email) {
      return res.status(400).json({ message: 'USN and email are required' });
    }

    console.log(`Forgot password - USN: ${usn}, Email: ${email}`);
    const student = await Student.findOne({ 
      usn: usn.trim().toUpperCase(),
      email: email.trim().toLowerCase(),
    });
    if (!student) {
      console.log(`Student not found for USN: ${usn}, Email: ${email}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    student.otp = otp;
    await student.save();

    console.log(`OTP for ${usn}: ${otp}`);
    res.json({ message: 'OTP sent successfully' });
  } catch (error) {
    console.error('Error in forgot-password:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Verify OTP Endpoint
app.post('/api/students/verify-otp', async (req, res) => {
  try {
    const { usn, otp } = req.body;
    if (!usn || !otp) {
      return res.status(400).json({ message: 'USN and OTP are required' });
    }

    console.log(`Verifying OTP for USN: ${usn}, OTP: ${otp}`);
    const student = await Student.findOne({ usn: usn.trim().toUpperCase() });
    if (!student) {
      console.log(`Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    if (student.otp !== otp) {
      console.log(`Invalid OTP for USN: ${usn}`);
      return res.status(401).json({ message: 'Invalid OTP' });
    }

    student.otp = null;
    await student.save();
    res.json({ message: 'OTP verified successfully' });
  } catch (error) {
    console.error('Error in verify-otp:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Reset Password Endpoint
app.post('/api/students/reset-password', async (req, res) => {
  try {
    const { usn, newPassword } = req.body;
    if (!usn || !newPassword) {
      return res.status(400).json({ message: 'USN and new password are required' });
    }

    console.log(`Resetting password for USN: ${usn}`);
    const student = await Student.findOne({ usn: usn.trim().toUpperCase() });
    if (!student) {
      console.log(`Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    student.password = newPassword;
    student.firstLogin = false;
    await student.save();

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Error in reset-password:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Profile Endpoint
app.get('/api/students/profile', async (req, res) => {
  try {
    const { usn } = req.query;
    if (!usn) {
      return res.status(400).json({ message: 'USN is required' });
    }

    console.log(`Fetching profile for USN: ${usn}`);
    const student = await Student.findOne({ usn: usn.trim().toUpperCase() });
    if (!student) {
      console.log(`Student not found for USN: ${usn}`);
      return res.status(404).json({ message: 'Student not found' });
    }

    res.json({
      usn: student.usn,
      fullName: student.fullName,
      email: student.email,
    });
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Placement Endpoints
app.get('/api/placements/featured', async (req, res) => {
  try {
    const placements = await Placement.find()
      .populate('companyId', 'name package')
      .lean();
    // Mock status for compatibility with Flutter app
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: `http://localhost:3000/uploads/placement_banners/${p.companyName.toLowerCase()}.jpg`,
      logo: `http://localhost:3000/uploads/logos/${p.companyName.toLowerCase()}.png`,
      status: 'Featured', // Hardcoded for now
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    res.json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching featured placements:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/placements/ongoing', async (req, res) => {
  try {
    const placements = await Placement.find()
      .populate('companyId', 'name package')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: `http://localhost:3000/uploads/placement_banners/${p.companyName.toLowerCase()}.jpg`,
      logo: `http://localhost:3000/uploads/logos/${p.companyName.toLowerCase()}.png`,
      status: 'Ongoing',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    res.json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching ongoing placements:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/placements/upcoming', async (req, res) => {
  try {
    const placements = await Placement.find()
      .populate('companyId', 'name package')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: `http://localhost:3000/uploads/placement_banners/${p.companyName.toLowerCase()}.jpg`,
      logo: `http://localhost:3000/uploads/logos/${p.companyName.toLowerCase()}.png`,
      status: 'Upcoming',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    res.json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching upcoming placements:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/placements/completed', async (req, res) => {
  try {
    const placements = await Placement.find()
      .populate('companyId', 'name package')
      .lean();
    const formattedPlacements = placements.map(p => ({
      id: p._id.toString(),
      company: p.companyName,
      bannerImage: `http://localhost:3000/uploads/placement_banners/${p.companyName.toLowerCase()}.jpg`,
      logo: `http://localhost:3000/uploads/logos/${p.companyName.toLowerCase()}.png`,
      status: 'Completed',
      driveDate: p.placementDate.toISOString().split('T')[0],
    }));
    res.json(formattedPlacements);
  } catch (error) {
    console.error('Error fetching completed placements:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Start server
app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});