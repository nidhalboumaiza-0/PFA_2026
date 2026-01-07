import { mongoose, getConfig } from '../../../../shared/index.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters'],
    select: false // Don't return password by default
  },
  role: {
    type: String,
    enum: ['patient', 'doctor', 'admin'],
    required: [true, 'Role is required']
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  passwordResetToken: String,
  passwordResetExpires: Date,
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: Date,
  profileId: {
    type: mongoose.Schema.Types.ObjectId,
    refPath: 'role' // References either Patient or Doctor
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function (next) {
  // Only hash if password is modified
  if (!this.isModified('password')) {
    return next();
  }

  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare passwords
userSchema.methods.comparePassword = async function (candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw error;
  }
};

// Method to generate JWT access token
userSchema.methods.generateAccessToken = function () {
  return jwt.sign(
    {
      id: this._id,
      email: this.email,
      role: this.role,
      profileId: this.profileId,
      type: 'access'
    },
    getConfig('JWT_SECRET', 'your-super-secret-jwt-key-change-in-production'),
    { expiresIn: getConfig('JWT_EXPIRE', '1d') }
  );
};

// Method to generate JWT refresh token
userSchema.methods.generateRefreshToken = function () {
  return jwt.sign(
    {
      id: this._id,
      type: 'refresh'
    },
    getConfig('JWT_REFRESH_SECRET', 'your-super-secret-refresh-key'),
    { expiresIn: getConfig('JWT_REFRESH_EXPIRE', '30d') }
  );
};

/**
 * Generate email verification token
 */
userSchema.methods.generateEmailVerificationToken = function () {
  // Generate token that expires in 24 hours
  const token = jwt.sign(
    {
      id: this._id,
      purpose: 'email-verification'
    },
    getConfig('JWT_SECRET', 'your-super-secret-jwt-key-change-in-production'),
    { expiresIn: '24h' }
  );

  // Save token and expiry
  this.emailVerificationToken = token;
  this.emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

  return token;
};

/**
 * Generate password reset token
 */
userSchema.methods.generatePasswordResetToken = function () {
  // Generate random token
  const resetToken = crypto.randomBytes(32).toString('hex');

  // Hash token and save
  this.passwordResetToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  this.passwordResetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

  return resetToken; // Return unhashed token to send via email
};

// Method to get user info without sensitive data
userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  delete user.emailVerificationToken;
  delete user.emailVerificationExpires;
  delete user.passwordResetToken;
  delete user.passwordResetExpires;
  return user;
};

const User = mongoose.model('User', userSchema);

export default User;
