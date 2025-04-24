const express = require('express');
const router = express.Router();

// Mock data (replace with MongoDB queries)
const featuredPlacements = [
  { id: '1', bannerImage: 'http://localhost:3000/assets/uploads/placement_banners/google.jpg', company: 'Google' },
  { id: '2', bannerImage: 'http://localhost:3000/uploads/placement_banners/amazon.jpg', company: 'Amazon' },
];

const ongoingDrives = [
  { id: '1', name: 'Google', logo: 'http://localhost:3000/assets/uploads/logos/google.png', driveDate: '2025-05-01', status: 'Ongoing' },
  { id: '2', name: 'Microsoft', logo: 'http://localhost:3000/assets/uploads/logos/microsoft.png', driveDate: '2025-05-03', status: 'Ongoing' },
];

const upcomingDrives = [
  { id: '3', name: 'Amazon', logo: 'http://localhost:3000/assets/uploads/logos/amazon.png', driveDate: '2025-06-01', status: 'Upcoming' },
];

const completedDrives = [
  { id: '4', name: 'Infosys', logo: 'http://localhost:3000/assets/uploads/logos/infosys.png', driveDate: '2025-04-01', status: 'Completed' },
];

router.get('/featured', async (req, res) => {
  console.log('DEBUG: Fetching featured placements');
  res.status(200).json(featuredPlacements);
});

router.get('/ongoing', async (req, res) => {
  console.log('DEBUG: Fetching ongoing drives');
  res.status(200).json(ongoingDrives);
});

router.get('/upcoming', async (req, res) => {
  console.log('DEBUG: Fetching upcoming drives');
  res.status(200).json(upcomingDrives);
});

router.get('/completed', async (req, res) => {
  console.log('DEBUG: Fetching completed drives');
  res.status(200).json(completedDrives);
});

module.exports = router;