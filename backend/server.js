// backend/server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));

mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/Campus_connect', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('DEBUG: Connected to MongoDB'))
  .catch((error) => console.error('DEBUG: MongoDB connection error:', error));

// Routes
const authRoutes = require('./routes/auth');
const placementRoutes = require('./routes/placement');
const profileRoutes = require('./routes/profile');
const studentRoutes = require('./routes/student');

app.use('/api/students', authRoutes);
app.use('/api/placements', placementRoutes);
app.use('/api/students', profileRoutes);
app.use('/api/students', studentRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`DEBUG: Server running on http://0.0.0.0:${PORT}`);
});