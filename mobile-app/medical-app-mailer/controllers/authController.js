const { promisify } = require("util");
const jwt = require("jsonwebtoken");
const User = require("../models/userModel");
const Patient = require("../models/patientModel");
const Medecin = require("../models/medecinModel");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/appError");
const sendEmail = require("../utils/email");
const crypto = require("crypto");

// Helper function to sign JWT token
const signToken = (id) => {
  if (!id)
    throw new Error("User ID is required for token generation");
  return jwt.sign({ id: id.toString() }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE_IN,
  });
};

// Helper function to generate refresh token
const generateRefreshToken = (userId) => {
  if (!userId)
    throw new Error(
      "User ID is required for refresh token generation"
    );
  return jwt.sign(
    { id: userId.toString() },
    process.env.REFRESH_TOKEN_SECRET,
    {
      expiresIn: process.env.REFRESH_TOKEN_EXPIRE_IN,
    }
  );
};

// Helper function to create and send tokens
const createSendToken = async (user, statusCode, res) => {
  if (!user || !user._id) {
    console.error("Invalid user or missing _id:", user);
    throw new AppError("Utilisateur invalide ou ID manquant", 500);
  }

  console.log("User:", user);
  console.log("User ID:", user._id);

  const token = signToken(user._id);
  const refreshToken = generateRefreshToken(user._id);

  // Save refresh token
  user.refreshToken = refreshToken;
  await user.save({ validateBeforeSave: false });
  console.log("Refresh token saved:", refreshToken);

  // Remove sensitive fields
  user.password = undefined;
  user.verificationCode = undefined;
  user.passwordResetCode = undefined;
  user.refreshToken = undefined;

  res.status(statusCode).json({
    status: "success",
    token,
    refreshToken,
    data: { user },
  });
};

// Sign up controller
exports.signUp = catchAsync(async (req, res, next) => {
  const {
    email,
    password,
    passwordConfirm,
    name,
    lastName,
    phoneNumber,
    gender,
    dateOfBirth,
    role,
    antecedent,
    speciality,
    numLicence,
    appointmentDuration,
    bloodType,
    height,
    weight,
    allergies,
    chronicDiseases,
    emergencyContact,
  } = req.body;

  // Check required fields
  if (
    !email ||
    !password ||
    !passwordConfirm ||
    !name ||
    !lastName ||
    !phoneNumber ||
    !gender ||
    !role
  ) {
    return next(
      new AppError(
        "Veuillez remplir tous les champs obligatoires !",
        400
      )
    );
  }

  // Check if email or phone number already exists
  const existingUser = await User.findOne({
    $or: [{ email }, { phoneNumber }],
  });
  if (existingUser) {
    return next(
      new AppError(
        existingUser.email === email
          ? "Cet e-mail est déjà utilisé !"
          : "Ce numéro de téléphone est déjà utilisé !",
        400
      )
    );
  }

  // Prepare user data
  let userData = {
    name,
    lastName,
    email,
    password,
    passwordConfirm,
    phoneNumber,
    gender,
    dateOfBirth,
    role,
  };

  if (role === "patient") {
    if (!antecedent) {
      return next(
        new AppError(
          "Veuillez fournir vos antécédents médicaux !",
          400
        )
      );
    }
    userData = {
      ...userData,
      antecedent,
      bloodType: bloodType || "Unknown",
      height,
      weight,
      allergies: allergies || [],
      chronicDiseases: chronicDiseases || [],
      emergencyContact,
    };
  } else if (role === "medecin") {
    if (!speciality) {
      return next(
        new AppError("Veuillez fournir votre spécialité !", 400)
      );
    }
    userData = {
      ...userData,
      speciality,
      numLicence: numLicence || "",
      appointmentDuration: appointmentDuration || 30,
    };
  } else {
    return next(new AppError("Rôle non valide !", 400));
  }

  // Create user
  let newUser;
  try {
    newUser = await (role === "patient" ? Patient : Medecin).create(
      userData
    );
  } catch (err) {
    return next(
      new AppError(
        `Erreur lors de la création de l'utilisateur: ${err.message}`,
        400
      )
    );
  }

  // Generate verification code
  const verificationCode = newUser.createVerificationCode();
  await newUser.save({ validateBeforeSave: false });

  // Send verification email
  try {
    const message = `Bonjour,\n
    Merci de créer un compte sur notre plateforme.\n
    Pour activer votre compte, voici votre code de vérification: ${verificationCode}\n
    Ce code est valable pendant 30 minutes.`;

    await sendEmail({
      email: newUser.email,
      subject: "Activation de compte",
      message,
      code: verificationCode,
    });

    res.status(201).json({
      status: "success",
      message: "Votre code d'activation a été envoyé avec succès",
    });
  } catch (err) {
    await User.deleteOne({ _id: newUser._id });
    return next(
      new AppError(
        "Une erreur s'est produite lors de l'envoi de l'e-mail ! Merci d'essayer plus tard.",
        500
      )
    );
  }
});

// Verify account
exports.verifyAccount = catchAsync(async (req, res, next) => {
  const { email, verificationCode } = req.body;

  if (!email || !verificationCode) {
    return next(
      new AppError(
        "Veuillez fournir votre email et code de vérification",
        400
      )
    );
  }

  const hashedCode = crypto
    .createHash("sha256")
    .update(verificationCode)
    .digest("hex");
  const user = await User.findOne({
    email,
    verificationCode: hashedCode,
    validationCodeExpiresAt: { $gt: Date.now() },
  }).select("+verificationCode +validationCodeExpiresAt");

  if (!user) {
    return next(
      new AppError("Code de vérification invalide ou expiré", 400)
    );
  }

  user.accountStatus = true;
  user.verificationCode = undefined;
  user.validationCodeExpiresAt = undefined;
  await user.save({ validateBeforeSave: false });

  await createSendToken(user, 200, res);
});

// Login controller
exports.login = catchAsync(async (req, res, next) => {
  const { email, password } = req.body;

  console.log("Login attempt for email:", email);

  // Check if email and password exist
  if (!email || !password) {
    return next(
      new AppError(
        "Veuillez fournir votre email et mot de passe",
        400
      )
    );
  }

  // Check if user exists and password is correct
  const user = await User.findOne({ email }).select("+password");
  console.log("User found:", user ? user._id : "null");

  if (!user) {
    return next(new AppError("Email ou mot de passe incorrect", 401));
  }

  const isPasswordCorrect = await user.correctPassword(
    password,
    user.password
  );
  console.log("Password correct:", isPasswordCorrect);

  if (!isPasswordCorrect) {
    return next(new AppError("Email ou mot de passe incorrect", 401));
  }

  // Check if user account is activated
  if (!user.accountStatus) {
    return next(
      new AppError(
        "Votre compte n'est pas encore activé ! Veuillez l'activer pour vous connecter",
        401
      )
    );
  }

  console.log("Generating token for user:", user._id);
  await createSendToken(user, 200, res);
});

// Protect routes middleware
exports.protect = catchAsync(async (req, res, next) => {
  let token;
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith("Bearer")
  ) {
    token = req.headers.authorization.split(" ")[1];
  }

  if (!token) {
    return next(
      new AppError(
        "Vous n'êtes pas connecté ! Veuillez vous connecter pour accéder à cette route.",
        401
      )
    );
  }

  const decoded = await promisify(jwt.verify)(
    token,
    process.env.JWT_SECRET
  );
  const currentUser = await User.findById(decoded.id);
  if (!currentUser) {
    return next(new AppError("L'utilisateur n'existe plus !", 401));
  }

  req.user = currentUser;
  next();
});

// Restrict to certain roles
exports.restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(
        new AppError(
          "Vous n'avez pas la permission d'effectuer cette action",
          403
        )
      );
    }
    next();
  };
};

// Forgot password
exports.forgotPassword = catchAsync(async (req, res, next) => {
  const user = await User.findOne({ email: req.body.email });
  if (!user) {
    return next(
      new AppError(
        "Il n'y a pas d'utilisateur avec cette adresse e-mail",
        404
      )
    );
  }

  const resetCode = user.createPasswordResetCode();
  await user.save({ validateBeforeSave: false });

  try {
    const message = `Bonjour,\n
    Vous avez oublié votre mot de passe ?\n
    Voici votre code de réinitialisation : ${resetCode}\n
    Ce code est valable pendant 30 minutes.`;

    await sendEmail({
      email: user.email,
      subject:
        "Code de réinitialisation de mot de passe (Valable 30 minutes)",
      message,
      code: resetCode,
    });

    res.status(200).json({
      status: "success",
      message:
        "Votre code de réinitialisation a été envoyé avec succès",
    });
  } catch (err) {
    user.passwordResetCode = undefined;
    user.passwordResetExpires = undefined;
    await user.save({ validateBeforeSave: false });
    return next(
      new AppError(
        "Une erreur s'est produite lors de l'envoi de l'e-mail ! Merci d'essayer plus tard.",
        500
      )
    );
  }
});

// Verify reset code
exports.verifyResetCode = catchAsync(async (req, res, next) => {
  const { email, resetCode } = req.body;

  if (!email || !resetCode) {
    return next(
      new AppError(
        "Veuillez fournir votre email et code de réinitialisation",
        400
      )
    );
  }

  const hashedCode = crypto
    .createHash("sha256")
    .update(resetCode)
    .digest("hex");
  const user = await User.findOne({
    email,
    passwordResetCode: hashedCode,
    passwordResetExpires: { $gt: Date.now() },
  }).select("+passwordResetCode +passwordResetExpires");

  if (!user) {
    return next(
      new AppError("Code de réinitialisation invalide ou expiré", 400)
    );
  }

  res.status(200).json({
    status: "success",
    message: "Code de réinitialisation valide",
  });
});

// Reset password
exports.resetPassword = catchAsync(async (req, res, next) => {
  const { email, resetCode, password, passwordConfirm } = req.body;

  if (!email || !resetCode || !password || !passwordConfirm) {
    return next(
      new AppError(
        "Veuillez fournir toutes les informations nécessaires",
        400
      )
    );
  }

  const hashedCode = crypto
    .createHash("sha256")
    .update(resetCode)
    .digest("hex");
  const user = await User.findOne({
    email,
    passwordResetCode: hashedCode,
    passwordResetExpires: { $gt: Date.now() },
  }).select("+passwordResetCode +passwordResetExpires");

  if (!user) {
    return next(
      new AppError("Code de réinitialisation invalide ou expiré", 400)
    );
  }

  user.password = password;
  user.passwordConfirm = passwordConfirm;
  user.passwordResetCode = undefined;
  user.passwordResetExpires = undefined;
  await user.save();

  await createSendToken(user, 200, res);
});

// Update password
exports.updatePassword = catchAsync(async (req, res, next) => {
  const user = await User.findById(req.user.id).select("+password");

  if (
    !(await user.correctPassword(
      req.body.currentPassword,
      user.password
    ))
  ) {
    return next(
      new AppError("Votre mot de passe actuel est incorrect", 401)
    );
  }

  user.password = req.body.password;
  user.passwordConfirm = req.body.passwordConfirm;
  await user.save();

  await createSendToken(user, 200, res);
});

// Refresh token
exports.refreshToken = catchAsync(async (req, res, next) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return next(
      new AppError("Aucun jeton de rafraîchissement fourni", 400)
    );
  }

  try {
    const decoded = jwt.verify(
      refreshToken,
      process.env.REFRESH_TOKEN_SECRET
    );
    const user = await User.findById(decoded.id).select(
      "+refreshToken"
    );

    if (!user || user.refreshToken !== refreshToken) {
      return next(
        new AppError("Jeton de rafraîchissement invalide", 401)
      );
    }

    const newAccessToken = signToken(user._id);
    const newRefreshToken = generateRefreshToken(user._id);

    user.refreshToken = newRefreshToken;
    await user.save({ validateBeforeSave: false });

    res.status(200).json({
      status: "success",
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (err) {
    return next(
      new AppError(
        "Jeton de rafraîchissement invalide ou expiré",
        401
      )
    );
  }
});
