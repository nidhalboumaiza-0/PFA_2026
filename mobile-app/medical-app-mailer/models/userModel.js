const crypto = require("crypto");
const mongoose = require("mongoose");
const validator = require("validator");
const bcrypt = require("bcryptjs");

const userSchema = mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Veuillez fournir votre prénom !"],
      trim: true,
    },
    lastName: {
      type: String,
      required: [true, "Veuillez fournir votre nom de famille !"],
      trim: true,
    },
    email: {
      type: String,
      required: [true, "Veuillez fournir votre email !"],
      unique: true,
      lowercase: true,
      validate: [
        validator.isEmail,
        "Veuillez fournir un email valide !",
      ],
    },
    password: {
      type: String,
      required: [true, "Veuillez fournir votre mot de passe !"],
      minlength: 8,
      select: false,
    },
    passwordConfirm: {
      type: String,
      required: [true, "Veuillez confirmer votre mot de passe !"],
      validate: {
        validator: function (el) {
          return this.password === el;
        },
        message: "Les mots de passe ne correspondent pas !",
      },
    },
    role: {
      type: String,
      enum: ["patient", "medecin", "admin"],
      required: [true, "Veuillez fournir votre rôle !"],
    },
    gender: {
      type: String,
      enum: ["Homme", "Femme"],
      required: [true, "Veuillez fournir votre genre !"],
    },
    phoneNumber: {
      type: String,
      required: [
        true,
        "Veuillez fournir votre numéro de téléphone !",
      ],
      unique: true,
    },
    dateOfBirth: {
      type: Date,
    },
    address: {
      street: String,
      city: String,
      state: String,
      zipCode: String,
      country: String,
    },
    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number],
        default: [0, 0],
      },
    },
    profilePicture: {
      type: String,
      default: `default${Math.floor(Math.random() * 4) + 1}.jpg`,
    },
    accountStatus: {
      type: Boolean,
      default: false,
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
    lastActive: {
      type: Date,
      default: Date.now,
    },
    oneSignalPlayerId: {
      type: String,
    },
    verificationCode: {
      type: String,
      select: false,
    },
    validationCodeExpiresAt: {
      type: Date,
      select: false,
    },
    passwordResetCode: {
      type: String,
      select: false,
    },
    passwordResetExpires: {
      type: Date,
      select: false,
    },
    refreshToken: {
      type: String,
      select: false,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
    discriminatorKey: "userType",
  }
);

// Index for geospatial queries
userSchema.index({ location: "2dsphere" });

// Middlewares
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  this.password = await bcrypt.hash(this.password, 12);
  this.passwordConfirm = undefined;
  next();
});

// Methods
userSchema.methods.correctPassword = async function (
  candidatePassword,
  userPassword
) {
  return await bcrypt.compare(candidatePassword, userPassword);
};

userSchema.methods.createPasswordResetCode = function () {
  const code = Math.floor(1000 + Math.random() * 9000).toString();
  this.passwordResetCode = crypto
    .createHash("sha256")
    .update(code)
    .digest("hex");
  this.passwordResetExpires = Date.now() + 30 * 60 * 1000;
  return code;
};

userSchema.methods.createVerificationCode = function () {
  const code = Math.floor(1000 + Math.random() * 9000).toString();
  this.verificationCode = crypto
    .createHash("sha256")
    .update(code)
    .digest("hex");
  this.validationCodeExpiresAt = Date.now() + 30 * 60 * 1000;
  return code;
};

// Virtual property for full name
userSchema.virtual("fullName").get(function () {
  return `${this.name} ${this.lastName}`;
});

const User = mongoose.model("User", userSchema);
module.exports = User;
