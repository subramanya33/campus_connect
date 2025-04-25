// backend/utils/otp.js
const generateOTP = () => {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    console.log(`DEBUG: Generated OTP: ${otp}`);
    return otp;
  };
  
  module.exports = { generateOTP };