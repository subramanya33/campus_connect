const express = require('express');
const router = express.Router();
const Resume = require('../models/Resume');
const { authenticate } = require('../middleware/authenticate');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

router.post('/', authenticate, async (req, res) => {
  try {
    const { usn, format, data } = req.body;

    if (!usn || !format || !data) {
      return res.status(400).json({ message: 'USN, format, and data are required' });
    }

    if (!['custom'].includes(format)) {
      return res.status(400).json({ message: 'Invalid resume format' });
    }

    let fileBuffer;
    try {
      fileBuffer = Buffer.from(data, 'base64');
      const fileHash = crypto.createHash('md5').update(fileBuffer).digest('hex');
      console.log('DEBUG: File buffer size:', fileBuffer.length, 'bytes');
      console.log('DEBUG: File content hash:', fileHash);
    } catch (error) {
      console.error('DEBUG: Error decoding base64:', error);
      return res.status(400).json({ message: 'Invalid base64 data' });
    }

    if (fileBuffer.slice(0, 4).toString() !== '%PDF') {
      return res.status(400).json({ message: 'Invalid PDF file' });
    }

    const timestamp = Date.now();
    const fileName = `${usn}_${timestamp}.pdf`;
    const filePath = path.join(__dirname, '..', 'uploads', 'resumes', fileName);
    const relativeFilePath = `/Uploads/resumes/${fileName}`; // Match case with your folder

    try {
      await fs.mkdir(path.dirname(filePath), { recursive: true });
      console.log('DEBUG: Directory ensured:', path.dirname(filePath));
    } catch (error) {
      console.error('DEBUG: Error creating directory:', error);
      return res.status(500).json({ message: 'Failed to create upload directory' });
    }

    const existingResume = await Resume.findOne({ usn });
    if (existingResume && existingResume.filePath) {
      const oldFilePath = path.join(__dirname, '..', existingResume.filePath);
      try {
        await fs.access(oldFilePath);
        console.log('DEBUG: Old file exists, deleting:', oldFilePath);
        await fs.unlink(oldFilePath);
        console.log('DEBUG: Old file deleted successfully');
      } catch (error) {
        if (error.code === 'ENOENT') {
          console.log('DEBUG: Old file not found, skipping deletion:', oldFilePath);
        } else {
          console.error('DEBUG: Error deleting old file:', error);
          return res.status(500).json({ message: 'Failed to delete old resume file' });
        }
      }
    }

    try {
      await fs.writeFile(filePath, fileBuffer);
      console.log('DEBUG: New file saved:', filePath);
      const stats = await fs.stat(filePath);
      console.log('DEBUG: Saved file size:', stats.size, 'bytes');
    } catch (error) {
      console.error('DEBUG: Error saving new file:', error);
      return res.status(500).json({ message: 'Failed to save new resume file' });
    }

    try {
      await fs.access(filePath);
      console.log('DEBUG: New file verified:', filePath);
    } catch (error) {
      console.error('DEBUG: Error verifying new file:', error);
      return res.status(500).json({ message: 'Failed to verify new resume file' });
    }

    const updatedResume = await Resume.findOneAndUpdate(
      { usn },
      {
        usn,
        format,
        filePath: relativeFilePath,
        updatedAt: new Date(),
      },
      {
        upsert: true,
        new: true,
        setDefaultsOnInsert: true,
      }
    );

    console.log('DEBUG: Updated resume document:', updatedResume);

    res.status(201).json({
      message: 'Resume saved successfully',
      resume: {
        id: updatedResume._id,
        usn: updatedResume.usn,
        format: updatedResume.format,
        filePath: relativeFilePath,
        updatedAt: updatedResume.updatedAt,
      },
    });
  } catch (error) {
    console.error('DEBUG: Error saving resume:', error);
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Resume already exists for this USN' });
    }
    res.status(500).json({ message: 'Server error' });
  }
});

router.get('/', authenticate, async (req, res) => {
  try {
    const resumes = await Resume.find({ usn: req.user.usn });
    console.log('DEBUG: Fetched resumes:', resumes);
    res.json(resumes);
  } catch (error) {
    console.error('DEBUG: Error fetching resumes:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const resume = await Resume.findOne({ _id: req.params.id, usn: req.user.usn });
    if (!resume) {
      return res.status(400).json({ message: 'Resume not found' });
    }

    const filePath = path.join(__dirname, '..', resume.filePath);
    try {
      await fs.access(filePath);
      console.log('DEBUG: Deleting resume file:', filePath);
      await fs.unlink(filePath);
    } catch (error) {
      if (error.code !== 'ENOENT') {
        console.error('DEBUG: Error deleting file:', error);
        return res.status(500).json({ message: 'Failed to delete resume file' });
      }
      console.log('DEBUG: File not found, skipping deletion:', filePath);
    }

    await Resume.deleteOne({ _id: req.params.id });
    res.json({ message: 'Resume deleted successfully' });
  } catch (error) {
    console.error('DEBUG: Error deleting resume:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;