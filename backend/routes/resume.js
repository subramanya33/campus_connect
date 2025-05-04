const express = require('express');
const router = express.Router();
const Resume = require('../models/Resume');
const {authenticate} = require('../middleware/authenticate');
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

const uploadDir = path.join(__dirname, '../public/uploads/resumes');
const MAX_RESUMES = 3;
const MAX_FILE_SIZE = 7.5 * 1024 * 1024; // 7.5MB

// Ensure upload directory exists
async function ensureUploadDir() {
  try {
    await fs.mkdir(uploadDir, { recursive: true });
    console.log(`DEBUG: Ensured directory exists: ${uploadDir}`);
  } catch (err) {
    console.error(`DEBUG: Error creating upload directory: ${err.message}`);
  }
}
ensureUploadDir();

router.post('/custom', authenticate, async (req, res) => {
  try {
    const { usn, pdfData, originalFileName } = req.body;
    console.log(`DEBUG: Received resume upload request: usn=${usn}, originalFileName=${originalFileName}, pdfDataLength=${pdfData?.length || 0}`);

    if (!usn || !pdfData || !originalFileName) {
      console.log('DEBUG: Missing required fields');
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const resumeCount = await Resume.countDocuments({ usn });
    if (resumeCount >= MAX_RESUMES) {
      console.log(`DEBUG: Resume limit reached for USN: ${usn}`);
      return res.status(403).json({ message: 'Resume limit reached (3). Please delete an existing resume.' });
    }

    let base64Data = pdfData;
    if (pdfData.startsWith('data:application/pdf;base64,')) {
      base64Data = pdfData.replace('data:application/pdf;base64,', '');
    }

    let buffer;
    try {
      buffer = Buffer.from(base64Data, 'base64');
    } catch (error) {
      console.error(`DEBUG: Invalid base64 data: ${error.message}`);
      return res.status(400).json({ message: 'Invalid base64 data' });
    }

    if (buffer.length > MAX_FILE_SIZE) {
      console.log(`DEBUG: File too large: ${buffer.length} bytes`);
      return res.status(413).json({ message: 'File size exceeds 7.5MB limit' });
    }

    const contentHash = crypto.createHash('md5').update(buffer).digest('hex');
    const existingResume = await Resume.findOne({ usn, contentHash });
    if (existingResume) {
      console.log(`DEBUG: Duplicate resume detected: ${contentHash}`);
      return res.status(400).json({ message: 'This resume content has already been uploaded' });
    }

    const timestamp = Date.now();
    const fileName = `${usn}_${timestamp}.pdf`;
    const filePath = `/uploads/resumes/${fileName}`;
    const absolutePath = path.join(uploadDir, fileName);

    try {
      await fs.writeFile(absolutePath, buffer);
      await fs.access(absolutePath);
      console.log(`DEBUG: Resume saved to: ${absolutePath}`);
    } catch (error) {
      console.error(`DEBUG: Failed to save resume file: ${error.message}`);
      return res.status(500).json({ message: 'Failed to save file on server' });
    }

    const resume = new Resume({
      usn,
      format: 'custom',
      filePath,
      contentHash,
      originalFileName,
      isActive: resumeCount === 0,
    });

    await resume.save();
    console.log(`DEBUG: Resume stored in DB: ${resume._id}`);

    res.status(201).json({ message: 'Resume saved successfully', resume });
  } catch (error) {
    console.error(`DEBUG: Error saving resume: ${error.message}`);
    res.status(500).json({ message: `Server error: ${error.message}` });
  }
});


router.put('/:id/active', authenticate, async (req, res) => {
  try {
    const resumeId = req.params.id;
    const usn = req.user.usn;
    console.log(`DEBUG: Setting active resume: ${resumeId} for USN: ${usn}`);

    const resume = await Resume.findOne({ _id: resumeId, usn });
    if (!resume) {
      console.log(`DEBUG: Resume not found: ${resumeId}`);
      return res.status(404).json({ message: 'Resume not found' });
    }

    await Resume.updateMany({ usn, isActive: true }, { $set: { isActive: false } });
    await Resume.updateOne({ _id: resumeId }, { $set: { isActive: true } });
    console.log(`DEBUG: Resume set active: ${resumeId}`);

    const updatedResume = await Resume.findById(resumeId);
    res.status(200).json({ message: 'Resume set as active', resume: updatedResume });
  } catch (error) {
    console.error(`DEBUG: Error setting active resume: ${error.message}`);
    res.status(500).json({ message: `Server error: ${error.message}` });
  }
});

router.get('/', authenticate, async (req, res) => {
  try {
    const usn = req.user.usn;
    console.log(`DEBUG: Fetching resumes for USN: ${usn}`);
    const resumes = await Resume.find({ usn }).sort({ updatedAt: -1 }).lean();
    console.log(`DEBUG: Found ${resumes.length} resumes`);
    res.status(200).json(resumes);
  } catch (error) {
    console.error(`DEBUG: Error fetching resumes: ${error.message}`);
    res.status(500).json({ message: `Server error: ${error.message}` });
  }
});

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const resumeId = req.params.id;
    const usn = req.user.usn;
    console.log(`DEBUG: Deleting resume: ${resumeId} for USN: ${usn}`);

    const resume = await Resume.findOne({ _id: resumeId, usn });
    if (!resume) {
      console.log(`DEBUG: Resume not found: ${resumeId}`);
      return res.status(404).json({ message: 'Resume not found' });
    }

    const absolutePath = path.join(__dirname, '../public', resume.filePath);
    try {
      await fs.access(absolutePath);
      await fs.unlink(absolutePath);
      console.log(`DEBUG: Deleted resume file: ${absolutePath}`);
    } catch (err) {
      console.warn(`DEBUG: File not found or error deleting file: ${err.message}`);
    }

    await Resume.deleteOne({ _id: resumeId });
    console.log(`DEBUG: Resume deleted from DB: ${resumeId}`);

    if (resume.isActive) {
      const remainingResumes = await Resume.find({ usn }).sort({ updatedAt: -1 }).limit(1);
      if (remainingResumes.length > 0) {
        await Resume.updateOne({ _id: remainingResumes[0]._id }, { $set: { isActive: true } });
        console.log(`DEBUG: Set new active resume: ${remainingResumes[0]._id}`);
      }
    }

    res.status(200).json({ message: 'Resume deleted successfully' });
  } catch (error) {
    console.error(`DEBUG: Error deleting resume: ${error.message}`);
    res.status(500).json({ message: `Server error: ${error.message}` });
  }
});

module.exports = router;