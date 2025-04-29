const express = require('express');
const router = express.Router();
const Resume = require('../models/Resume');
const { authenticate } = require('../middleware/authenticate');
const fs = require('fs');
const path = require('path');

// Save resume
router.post('/', authenticate, async (req, res) => {
  try {
    const { usn, format, data } = req.body;

    // Validate input
    if (!usn || !format || !data) {
      return res.status(400).json({ message: 'USN, format, and data are required' });
    }
    if (req.user.usn !== usn) {
      return res.status(403).json({ message: 'Unauthorized: USN mismatch' });
    }

    // Validate base64 data
    try {
      Buffer.from(data, 'base64');
    } catch (error) {
      return res.status(400).json({ message: 'Invalid base64 data' });
    }

    // Create file name and path
    const fileName = `${usn}_${Date.now()}.pdf`;
    const filePath = path.join(__dirname, '../uploads/resumes', fileName);
    const relativeFilePath = `/uploads/resumes/${fileName}`;

    // Save PDF file
    try {
      fs.writeFileSync(filePath, Buffer.from(data, 'base64'));
    } catch (error) {
      console.error('Error saving PDF file:', error);
      return res.status(500).json({ message: 'Failed to save resume file' });
    }

    // Save resume in database
    const resume = new Resume({
      usn,
      format,
      filePath: relativeFilePath,
    });
    await resume.save();

    res.status(201).json({
      message: 'Resume saved successfully',
      resume: {
        id: resume._id,
        usn: resume.usn,
        format: resume.format,
        filePath: resume.filePath,
        updatedAt: resume.updatedAt,
      },
    });
  } catch (error) {
    console.error('Error saving resume:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all resumes for the authenticated user
router.get('/', authenticate, async (req, res) => {
  try {
    const resumes = await Resume.find({ usn: req.user.usn });
    if (!resumes || resumes.length === 0) {
      return res.status(404).json({ message: 'No resumes found' });
    }

    // Filter out resumes without filePath
    const validResumes = resumes.filter((resume) => resume.filePath);

    res.json(
      validResumes.map((resume) => ({
        id: resume._id,
        usn: resume.usn,
        format: resume.format,
        filePath: resume.filePath,
        updatedAt: resume.updatedAt,
      }))
    );
  } catch (error) {
    console.error('Error fetching resumes:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete a resume
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const resume = await Resume.findById(req.params.id);
    if (!resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }
    if (resume.usn !== req.user.usn) {
      return res.status(403).json({ message: 'Unauthorized: Cannot delete this resume' });
    }

    // Delete the PDF file
    if (resume.filePath) {
      const filePath = path.join(__dirname, '../', resume.filePath);
      try {
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      } catch (error) {
        console.error('Error deleting PDF file:', error);
        // Proceed with deletion even if file deletion fails
      }
    }

    // Delete resume from database
    await resume.deleteOne();

    res.json({ message: 'Resume deleted successfully' });
  } catch (error) {
    console.error('Error deleting resume:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;