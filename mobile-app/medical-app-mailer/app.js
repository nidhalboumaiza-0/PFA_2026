const cors = require("cors");
const express = require("express");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");
const AppError = require("./utils/appError");
const globalErrorHandler = require("./controllers/errorController");
const xss = require("xss-clean");
const mongoSanitize = require("express-mongo-sanitize");
const helmet = require("helmet");
const bodyParser = require("body-parser");
const path = require("path");
const app = express();

//------------ROUTES----------------
const userRoutes = require("./routes/userRoutes");
const appointmentRoutes = require("./routes/appointmentRoutes");
const conversationRoutes = require("./routes/conversationRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const dashboardRoutes = require("./routes/dashboardRoutes");
const prescriptionRoutes = require("./routes/prescriptionRoutes");
const ratingRoutes = require("./routes/ratingRoutes");
const specialityRoutes = require("./routes/specialityRoutes");
const medicalRecordRoutes = require("./routes/medicalRecordRoutes");
const dossierMedicalRoutes = require("./routes/dossierMedicalRoutes");

//------------------------------
// Implement CORS
app.use("/images", express.static(path.join(__dirname, "./images")));

app.use(cors({ origin: "*" }));
app.use(helmet());
app.use(xss());
app.use(mongoSanitize());
app.use(morgan("dev"));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// 1) GLOBAL MIDDLEWARES
const limiter = rateLimit({
  max: 100,
  windowMs: 60 * 60 * 1000,
  message:
    "Too many requests from this IP, please try again in an hour!",
});
app.use("/api", limiter);

// Development logging
if (process.env.NODE_ENV === "development") {
  app.use(morgan("dev"));
}

// Request time middleware
app.use((req, res, next) => {
  req.requestTime = new Date().toISOString();
  next();
});

// Add this line to serve static files from the uploads directory
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// 3) ROUTES
app.use("/api/v1/users", userRoutes);
app.use("/api/v1/appointments", appointmentRoutes);
app.use("/api/v1/conversations", conversationRoutes);
app.use("/api/v1/notifications", notificationRoutes);
app.use("/api/v1/dashboard", dashboardRoutes);
app.use("/api/v1/prescriptions", prescriptionRoutes);
app.use("/api/v1/ratings", ratingRoutes);
app.use("/api/v1/specialities", specialityRoutes);
app.use("/api/v1/medical-records", medicalRecordRoutes);
app.use("/api/v1/dossier-medical", dossierMedicalRoutes);

// Handle undefined routes
app.all("*", (req, res, next) => {
  next(
    new AppError(`Can't find ${req.originalUrl} on this server!`, 404)
  );
});

// Global error handler
app.use(globalErrorHandler);

module.exports = app;
