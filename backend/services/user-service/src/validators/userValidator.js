import Joi from 'joi';

/**
 * Patient profile validation
 */
const patientProfileSchema = Joi.object({
  firstName: Joi.string().min(2).max(50).trim(),
  lastName: Joi.string().min(2).max(50).trim(),
  dateOfBirth: Joi.date().max('now'),
  gender: Joi.string().valid('male', 'female', 'other'),
  phone: Joi.string().pattern(/^[\d\s\+\-\(\)]+$/).message('Please provide a valid phone number'),
  address: Joi.object({
    street: Joi.string().allow('', null),
    city: Joi.string().allow('', null),
    state: Joi.string().allow('', null),
    zipCode: Joi.string().allow('', null),
    country: Joi.string().allow('', null),
    coordinates: Joi.object({
      type: Joi.string().valid('Point').default('Point'),
      coordinates: Joi.array().items(Joi.number()).length(2) // [longitude, latitude]
    })
  }),
  bloodType: Joi.string().valid('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', null),
  allergies: Joi.array().items(Joi.string()),
  chronicDiseases: Joi.array().items(Joi.string()),
  emergencyContact: Joi.object({
    name: Joi.string().allow('', null),
    relationship: Joi.string().allow('', null),
    phone: Joi.string().pattern(/^[\d\s\+\-\(\)]+$/).allow('', null)
  }),
  insuranceInfo: Joi.object({
    provider: Joi.string().allow('', null),
    policyNumber: Joi.string().allow('', null),
    expiryDate: Joi.date().allow(null)
  })
});

/**
 * Doctor profile validation
 */
const doctorProfileSchema = Joi.object({
  firstName: Joi.string().min(2).max(50).trim(),
  lastName: Joi.string().min(2).max(50).trim(),
  specialty: Joi.string().min(2).max(100).trim(),
  subSpecialty: Joi.string().max(100).trim().allow('', null),
  phone: Joi.string().pattern(/^[\d\s\+\-\(\)]+$/).message('Please provide a valid phone number'),
  licenseNumber: Joi.string().trim(),
  yearsOfExperience: Joi.number().min(0).max(70),
  education: Joi.array().items(Joi.object({
    degree: Joi.string().allow('', null),
    institution: Joi.string().allow('', null),
    year: Joi.number().min(1950).max(new Date().getFullYear())
  })),
  languages: Joi.array().items(Joi.string()),
  clinicName: Joi.string().max(200).trim().allow('', null),
  clinicAddress: Joi.object({
    street: Joi.string().allow('', null),
    city: Joi.string().required(),
    state: Joi.string().allow('', null),
    zipCode: Joi.string().allow('', null),
    country: Joi.string().required(),
    coordinates: Joi.object({
      type: Joi.string().valid('Point').default('Point'),
      coordinates: Joi.array().items(Joi.number()).length(2) // [longitude, latitude]
    }).allow(null)
  }),
  about: Joi.string().max(1000).allow('', null),
  consultationFee: Joi.number().min(0),
  acceptsInsurance: Joi.boolean(),
  workingHours: Joi.array().items(Joi.object({
    day: Joi.string().valid('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
    isAvailable: Joi.boolean(),
    slots: Joi.array().items(Joi.object({
      startTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).message('Time must be in HH:MM format'),
      endTime: Joi.string().pattern(/^([01]\d|2[0-3]):([0-5]\d)$/).message('Time must be in HH:MM format')
    }))
  }))
});

/**
 * Validate request data
 */
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => detail.message);
      return res.status(400).json({
        message: 'Validation error',
        errors
      });
    }
    
    next();
  };
};

export const validatePatientProfile = validate(patientProfileSchema);
export const validateDoctorProfile = validate(doctorProfileSchema);
