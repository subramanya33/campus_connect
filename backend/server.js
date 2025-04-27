const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
const studentRoutes = require('./routes/student');
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const placementRoutes = require('./routes/placement');

app.use('/api/students', studentRoutes);
app.use('/api/students', authRoutes);
app.use('/api/students', profileRoutes);
app.use('/api/placements', placementRoutes);

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