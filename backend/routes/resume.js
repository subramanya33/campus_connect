const express = require('express');
const router = express.Router();
const Resume = require('../models/resume');
const { authenticate } = require('../middleware/authenticate');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

router.post('/custom', authenticate, async (req, res) => {
  try {
    const { usn, pdfData, originalFileName } = req.body;
    if (!usn || !pdfData || !originalFileName) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Validate base64 data
    if (!pdfData.startsWith('data:application/pdf;base64,')) {
      return res.status(400).json({ message: 'Invalid PDF data format' });
    }

    // Enforce 3-resume limit
    const resumeCount = await Resume.countDocuments({ usn });
    if (resumeCount >= 3) {
      return res.status(403).json({ message: 'Resume limit reached (3). Please delete an existing resume.' });
    }

    // Decode base64 data
    const base64Data = pdfData.replace(/^data:application\/pdf;base64,/, '');
    let buffer;
    try {
      buffer = Buffer.from(base64Data, 'base64');
    } catch (error) {
      console.error('Invalid base64 data:', error);
      return res.status(400).json({ message: 'Invalid base64 data' });
    }
    const contentHash = crypto.createHash('md5').update(buffer).digest('hex');

    // Check for duplicate content
    const existingResume = await Resume.findOne({ usn, contentHash });
    if (existingResume) {
      return res.status(400).json({ message: 'This resume content has already been uploaded' });
    }

    // Generate unique filename for storage
    const timestamp = Date.now();
    const sanitizedFileName = `${usn}_${timestamp}.pdf`;
    const filePath = `/uploads/resumes/${sanitizedFileName}`;
    const absolutePath = path.join(__dirname, '../public/uploads/resumes', sanitizedFileName);

    // Save file
    await fs.mkdir(path.dirname(absolutePath), { recursive: true });
    await fs.writeFile(absolutePath, buffer);

    // Verify file was saved
    try {
      await fs.access(absolutePath);
    } catch (error) {
      console.error('Failed to save file:', error);
      return res.status(500).json({ message: 'Failed to save file on server' });
    }

    // Save resume to MongoDB
    const resume = new Resume({
      usn,
      filePath,
      originalFileName,
      contentHash,
      format: 'custom',
      isActive: true,
    });

    await resume.save();
    res.status(201).json({ message: 'Resume saved successfully', resume });
  } catch (error) {
    console.error('Error saving resume:', error);
    res.status(500).json({ message: `Server error: ${error.message}` });
  }
});

router.put('/:id/active', authenticate, async (req, res) => {
  try {
    const resumeId = req.params.id;
    const user = req.user;

    // Find resume
    const resume = await Resume.findOne({ _id: resumeId, usn: user.usn });
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }

    // Update isActive without triggering full validation
    await Resume.updateMany({ usn: user.usn, isActive: true }, { $set: { isActive: false } });
    await Resume.updateOne({ _id: resumeId }, { $set: { isActive: true } });

    const updatedResume = await Resume.findById(resumeId);
    res.status(200).json({ message: 'Resume set as active', resume: updatedResume });
  } catch (error) {
    console.error('Error setting active resume:', error);
    res.status(500).json({ message: `Server error: ${error.message}` });
  }
});

router.get('/', authenticate, async (req, res) => {
  try {
    const resumes = await Resume.find({ usn: req.user.usn }).sort({ updatedAt: -1 });
    res.status(200).json(resumes);
  } catch (error) {
    console.error('Error fetching resumes:', error);
    res.status(500).json({ message: `Server error: ${error.message}` });
  }
});

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const resumeId = req.params.id;
    const resume = await Resume.findOne({ _id: resumeId, usn: req.user.usn });
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }

    // Delete file from filesystem if it exists
    const absolutePath = path.join(__dirname, '../public', resume.filePath);
    try {
      await fs.access(absolutePath);
      await fs.unlink(absolutePath);
    } catch (err) {
      console.warn('File not found or error deleting file:', err);
    }

    // Delete from MongoDB
    await Resume.deleteOne({ _id: resumeId });
    res.status(200).json({ message: 'Resume deleted successfully' });
  } catch (error) {
    console.error('Error deleting resume:', error);
    res.status(500).json({ message: `Server error: ${error.message}` });
  }
});

module.exports = router;