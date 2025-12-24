const mongoose = require("mongoose");

const specialitySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Le nom de la spécialité est requis"],
      unique: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    icon: {
      type: String,
      default: "default-speciality.png",
    },
    active: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

const Speciality = mongoose.model("Speciality", specialitySchema);

module.exports = Speciality;
