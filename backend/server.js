const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' })); // ✅ Set once with size limit
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
const studentRoutes = require('./routes/student');
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const placementRoutes = require('./routes/placement');
const questionBankRoutes = require('./routes/questionbank');  
const resumeRoutes = require('./routes/resume');

// ✅ No need for body-parser — express has built-in support
// const bodyParser = require('body-parser'); ❌ Remove this

// API Endpoints
app.use('/api/resumes', resumeRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/auth', authRoutes);
app.use('/api', profileRoutes);
app.use('/api/placements', placementRoutes);
app.use('/api/questionbank', questionBankRoutes);

// MongoDB Connection
mongoose
  .connect('mongodb://localhost:27017/Campus_connect', {
    useNewUrlParser: true,
  })
  .then(() => console.log('DEBUG: Connected to MongoDB'))
  .catch((err) => console.error('DEBUG: MongoDB connection error:', err));

// Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`DEBUG: Server running on http://0.0.0.0:${PORT}`);
});
