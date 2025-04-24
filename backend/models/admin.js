const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Define the Admin schema
const adminSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true  // Ensures the username is unique
  },
  email: {
    type: String,
    required: true,
    unique: true  // Ensures the email is unique
  },
  password: {
    type: String,
    required: true
  },
  role: {  // The role can help determine the level of access (e.g., Admin, SuperAdmin, etc.)
    type: String,
    required: true,
    default: 'Admin'  // Default to "Admin" if not specified
  }
}, {
  timestamps: true
});

// Hash the password before saving the admin
adminSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();  // Only hash if the password is modified

  // Generate a salt and hash the password
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare hashed password with plain password
adminSchema.methods.comparePassword = async function(plainPassword) {
  return await bcrypt.compare(plainPassword, this.password);
};

module.exports = mongoose.model('Admin', adminSchema);
