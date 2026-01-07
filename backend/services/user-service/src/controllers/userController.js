import Patient from '../models/Patient.js';
import Doctor from '../models/Doctor.js';
import { uploadToS3, deleteFromS3, getSignedUrl } from '../services/s3Service.js';
import { kafkaProducer, TOPICS, createEvent, cacheGet, cacheSet, cacheDelete, CACHE_KEYS, CACHE_TTL, sendError, sendSuccess } from '../../../../shared/index.js';
import axios from 'axios';

/**
 * Helper function to generate signed URL for profile photo
 * @param {String} photoUrl - S3 URL or key
 * @returns {Promise<String|null>} Signed URL or null if no photo
 */
const getSignedProfilePhotoUrl = async (photoUrl) => {
  if (!photoUrl) return null;

  try {
    // Extract S3 key from full URL if needed
    let fileKey = photoUrl;
    if (photoUrl.includes('amazonaws.com')) {
      const urlParts = photoUrl.split('.amazonaws.com/');
      fileKey = urlParts[1] || photoUrl;
    }

    // Generate signed URL that expires in 1 hour
    return await getSignedUrl(fileKey, 3600);
  } catch (error) {
    console.error('Error generating signed URL for profile photo:', error);
    return null;
  }
};

/**
 * Get current user profile
 * GET /api/v1/users/me
 */
export const getCurrentUser = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;

    let profile;
    if (role === 'patient') {
      profile = await Patient.findOne({ userId });
    } else if (role === 'doctor') {
      profile = await Doctor.findOne({ userId });
    } else {
      return sendError(res, 400, 'INVALID_ROLE',
        'Invalid user role. Please contact support.');
    }

    if (!profile) {
      return sendError(res, 404, 'PROFILE_NOT_FOUND',
        'Your profile was not found. Please complete your registration.');
    }

    // Convert profile to plain object and add signed URL for profile photo
    const profileData = profile.toObject();
    if (profileData.profilePhoto) {
      profileData.profilePhoto = await getSignedProfilePhotoUrl(profileData.profilePhoto);
    }

    res.status(200).json({
      user: {
        id: userId,
        email: req.user.email,
        role: req.user.role
      },
      profile: profileData
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update patient profile
 * PUT /api/v1/users/patient/profile
 */
export const updatePatientProfile = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;

    if (role !== 'patient') {
      return sendError(res, 403, 'FORBIDDEN',
        'Only patients can update patient profiles.');
    }

    const patient = await Patient.findOne({ userId });

    if (!patient) {
      return sendError(res, 404, 'PROFILE_NOT_FOUND',
        'Patient profile not found. Please complete your registration.');
    }

    // Update fields
    const allowedFields = [
      'firstName', 'lastName', 'dateOfBirth', 'gender', 'phone',
      'address', 'bloodType', 'allergies', 'chronicDiseases',
      'emergencyContact', 'insuranceInfo'
    ];

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        patient[field] = req.body[field];
      }
    });

    await patient.save();

    // Publish Kafka event (fire-and-forget - don't block the response)
    kafkaProducer.sendEvent(
      TOPICS.USER.PROFILE_UPDATED,
      createEvent('patient.profile_updated', {
        userId: userId.toString(),
        patientId: patient._id.toString()
      })
    ).catch(err => console.error('Kafka event failed (non-blocking):', err.message));

    res.status(200).json({
      message: 'Patient profile updated successfully',
      profile: patient
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update doctor profile
 * PUT /api/v1/users/doctor/profile
 */
export const updateDoctorProfile = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;

    if (role !== 'doctor') {
      return sendError(res, 403, 'FORBIDDEN',
        'Only doctors can update doctor profiles.');
    }

    const doctor = await Doctor.findOne({ userId });

    if (!doctor) {
      return sendError(res, 404, 'PROFILE_NOT_FOUND',
        'Doctor profile not found. Please complete your registration.');
    }

    // Track changes for Kafka event
    const changes = [];

    // Update fields
    const allowedFields = [
      'firstName', 'lastName', 'specialty', 'subSpecialty', 'phone',
      'licenseNumber', 'yearsOfExperience', 'education', 'languages',
      'clinicName', 'clinicAddress', 'about', 'consultationFee',
      'acceptsInsurance', 'workingHours'
    ];

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        // Handle clinicAddress coordinates conversion
        if (field === 'clinicAddress' && req.body.clinicAddress.coordinates) {
          const coords = req.body.clinicAddress.coordinates;

          // Check if it's already in GeoJSON format
          if (coords.type === 'Point' && Array.isArray(coords.coordinates)) {
            // Already GeoJSON - validate the coordinates
            const [lng, lat] = coords.coordinates;
            if (typeof lng === 'number' && typeof lat === 'number' && !isNaN(lng) && !isNaN(lat)) {
              // Valid GeoJSON - keep as is
              req.body.clinicAddress.coordinates = coords;
            } else {
              // Invalid coordinates - remove the coordinates field
              delete req.body.clinicAddress.coordinates;
            }
          } else if (typeof coords.latitude === 'number' && typeof coords.longitude === 'number') {
            // Convert from {latitude, longitude} to GeoJSON format
            req.body.clinicAddress.coordinates = {
              type: 'Point',
              coordinates: [coords.longitude, coords.latitude]
            };
          } else {
            // Invalid format - remove the coordinates field
            delete req.body.clinicAddress.coordinates;
          }
        }

        doctor[field] = req.body[field];
        changes.push(field);
      }
    });

    await doctor.save();

    // Invalidate the doctor cache
    await cacheDelete(CACHE_KEYS.DOCTOR_PROFILE(doctor._id.toString()));
    console.log(`🗑️ Cache invalidated: Doctor ${doctor._id}`);

    // Publish Kafka event (fire-and-forget - don't block the response)
    kafkaProducer.sendEvent(
      TOPICS.USER.PROFILE_UPDATED,
      createEvent('doctor.profile_updated', {
        userId: userId.toString(),
        doctorId: doctor._id.toString(),
        changes
      })
    ).catch(err => console.error('Kafka event failed (non-blocking):', err.message));

    res.status(200).json({
      message: 'Doctor profile updated successfully',
      profile: doctor
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Upload profile photo
 * POST /api/v1/users/upload-photo
 */
export const uploadProfilePhoto = async (req, res, next) => {
  try {
    if (!req.file) {
      return sendError(res, 400, 'NO_FILE',
        'No file uploaded. Please select a file to upload.');
    }

    const { id: userId, role } = req.user;

    // Upload to S3
    const photoUrl = await uploadToS3(req.file, 'profiles/');

    // Update profile
    let profile;
    let oldPhotoUrl;

    if (role === 'patient') {
      profile = await Patient.findOne({ userId });
      if (profile) {
        oldPhotoUrl = profile.profilePhoto;
        profile.profilePhoto = photoUrl;
        await profile.save();
      }
    } else if (role === 'doctor') {
      profile = await Doctor.findOne({ userId });
      if (profile) {
        oldPhotoUrl = profile.profilePhoto;
        profile.profilePhoto = photoUrl;
        await profile.save();
      }
    }

    // Delete old photo from S3
    if (oldPhotoUrl) {
      await deleteFromS3(oldPhotoUrl);
    }

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.USER.PHOTO_UPLOADED,
      createEvent('user.photo_uploaded', {
        userId: userId.toString(),
        photoUrl
      })
    );

    res.status(200).json({
      message: 'Profile photo uploaded successfully',
      photoUrl
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Search doctors
 * GET /api/v1/users/doctors/search
 * 
 * Uses Redis caching for search results (5 min TTL)
 */
export const searchDoctors = async (req, res, next) => {
  try {
    const {
      name,
      specialty,
      city,
      latitude,
      longitude,
      radius = 10, // km
      page = 1,
      limit = 20
    } = req.query;

    // Create cache key from search params
    const cacheKey = `doctor_search:${JSON.stringify({ name, specialty, city, latitude, longitude, radius, page, limit })}`;

    // Try cache first
    const cachedResult = await cacheGet(cacheKey);
    if (cachedResult) {
      console.log(`📦 Cache HIT: Doctor search`);
      return res.status(200).json({ ...cachedResult, fromCache: true });
    }

    const query = {
      isActive: true,
      isVerified: true
    };

    // Text search on name and clinic
    if (name) {
      query.$or = [
        { firstName: { $regex: name, $options: 'i' } },
        { lastName: { $regex: name, $options: 'i' } },
        { clinicName: { $regex: name, $options: 'i' } }
      ];
    }

    // Filter by specialty
    if (specialty) {
      query.specialty = { $regex: specialty, $options: 'i' };
    }

    // Filter by city
    if (city) {
      query['clinicAddress.city'] = { $regex: city, $options: 'i' };
    }

    // Geospatial search
    if (latitude && longitude) {
      const radiusInRadians = radius / 6378.1; // Earth's radius in km
      query['clinicAddress.coordinates'] = {
        $geoWithin: {
          $centerSphere: [[parseFloat(longitude), parseFloat(latitude)], radiusInRadians]
        }
      };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Execute query with distance calculation if location provided
    let doctors;
    if (latitude && longitude) {
      doctors = await Doctor.aggregate([
        {
          $geoNear: {
            near: {
              type: 'Point',
              coordinates: [parseFloat(longitude), parseFloat(latitude)]
            },
            distanceField: 'distance',
            maxDistance: parseFloat(radius) * 1000, // Convert km to meters
            spherical: true,
            query: {
              isActive: true,
              isVerified: true,
              ...(name && {
                $or: [
                  { firstName: { $regex: name, $options: 'i' } },
                  { lastName: { $regex: name, $options: 'i' } },
                  { clinicName: { $regex: name, $options: 'i' } }
                ]
              }),
              ...(specialty && { specialty: { $regex: specialty, $options: 'i' } }),
              ...(city && { 'clinicAddress.city': { $regex: city, $options: 'i' } })
            }
          }
        },
        { $skip: skip },
        { $limit: parseInt(limit) },
        {
          $addFields: {
            distance: { $divide: ['$distance', 1000] } // Convert meters to km
          }
        }
      ]);
    } else {
      doctors = await Doctor.find(query)
        .sort({ rating: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .select('-__v');
    }

    const totalDoctors = await Doctor.countDocuments(query);
    const totalPages = Math.ceil(totalDoctors / parseInt(limit));

    const result = {
      doctors,
      pagination: {
        currentPage: parseInt(page),
        totalPages,
        totalDoctors
      }
    };

    // Cache for 5 minutes
    await cacheSet(cacheKey, result, 300);
    console.log(`💾 Cache SET: Doctor search`);

    res.status(200).json(result);
  } catch (error) {
    next(error);
  }
};

/**
 * Get doctor by ID (public profile)
 * GET /api/v1/users/doctors/:doctorId
 * 
 * Uses Redis caching for frequently accessed doctor profiles
 */
export const getDoctorById = async (req, res, next) => {
  try {
    const { doctorId } = req.params;
    const cacheKey = CACHE_KEYS.DOCTOR_PROFILE(doctorId);

    // Try to get from cache first
    const cachedDoctor = await cacheGet(cacheKey);
    if (cachedDoctor) {
      console.log(`📦 Cache HIT: Doctor ${doctorId}`);
      // Generate fresh signed URL for cached profile photo
      if (cachedDoctor.profilePhoto) {
        cachedDoctor.profilePhoto = await getSignedProfilePhotoUrl(cachedDoctor.profilePhoto);
      }
      return res.status(200).json({
        doctor: cachedDoctor,
        fromCache: true
      });
    }

    console.log(`🔍 Cache MISS: Doctor ${doctorId} - fetching from DB`);
    const doctor = await Doctor.findById(doctorId).select('-__v');

    if (!doctor) {
      return sendError(res, 404, 'DOCTOR_NOT_FOUND',
        'The doctor you are looking for does not exist.');
    }

    if (!doctor.isActive || !doctor.isVerified) {
      return sendError(res, 404, 'DOCTOR_NOT_AVAILABLE',
        'This doctor profile is not currently available.');
    }

    // Convert to object and generate signed URL for profile photo
    const doctorData = doctor.toObject();
    const originalPhotoUrl = doctorData.profilePhoto; // Keep original for caching
    if (doctorData.profilePhoto) {
      doctorData.profilePhoto = await getSignedProfilePhotoUrl(doctorData.profilePhoto);
    }

    // Cache the doctor profile with ORIGINAL S3 URL (not signed URL)
    // This way we generate fresh signed URLs on each request
    const cacheData = { ...doctor.toObject() };
    await cacheSet(cacheKey, cacheData, CACHE_TTL.DOCTOR_PROFILE);

    res.status(200).json({
      doctor: doctorData,
      fromCache: false
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get nearby doctors (map view)
 * GET /api/v1/users/doctors/nearby
 */
export const getNearbyDoctors = async (req, res, next) => {
  try {
    const { latitude, longitude, radius = 5, specialty } = req.query;

    if (!latitude || !longitude) {
      return sendError(res, 400, 'LOCATION_REQUIRED',
        'Latitude and longitude are required to find nearby doctors.');
    }

    const query = {
      isActive: true,
      isVerified: true
    };

    if (specialty) {
      query.specialty = { $regex: specialty, $options: 'i' };
    }

    const doctors = await Doctor.aggregate([
      {
        $geoNear: {
          near: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)]
          },
          distanceField: 'distance',
          maxDistance: parseFloat(radius) * 1000, // Convert km to meters
          spherical: true,
          query
        }
      },
      {
        $project: {
          name: { $concat: ['Dr. ', '$firstName', ' ', '$lastName'] },
          specialty: 1,
          coordinates: '$clinicAddress.coordinates.coordinates',
          rating: 1,
          distance: { $divide: ['$distance', 1000] }, // Convert to km
          profilePhoto: 1,
          consultationFee: 1,
          clinicAddress: 1
        }
      },
      { $limit: 100 } // Limit for map view
    ]);

    res.status(200).json({
      doctors
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Verify doctor (Admin only)
 * PUT /api/v1/users/admin/verify-doctor/:doctorId
 */
export const verifyDoctor = async (req, res, next) => {
  try {
    const { doctorId } = req.params;

    const doctor = await Doctor.findById(doctorId);

    if (!doctor) {
      return sendError(res, 404, 'DOCTOR_NOT_FOUND',
        'The doctor you are looking for does not exist.');
    }

    doctor.isVerified = true;
    await doctor.save();

    // Publish Kafka event
    await kafkaProducer.sendEvent(
      TOPICS.USER.DOCTOR_VERIFIED,
      createEvent('doctor.verified', {
        doctorId: doctor._id.toString(),
        userId: doctor.userId.toString()
      })
    );

    res.status(200).json({
      message: 'Doctor verified successfully',
      doctor
    });
  } catch (error) {
    next(error);
  }
};
/**
 * Update OneSignal Player ID
 * PATCH /api/v1/users/updateOneSignalPlayerId
 */
export const updateOneSignalPlayerId = async (req, res, next) => {
  try {
    const { id: userId, role } = req.user;
    const { oneSignalPlayerId } = req.body;

    if (!oneSignalPlayerId) {
      return sendError(res, 400, 'VALIDATION_ERROR',
        'OneSignal Player ID is required.');
    }

    let profile;
    if (role === 'patient') {
      profile = await Patient.findOne({ userId });
    } else if (role === 'doctor') {
      profile = await Doctor.findOne({ userId });
    }

    if (!profile) {
      return sendError(res, 404, 'PROFILE_NOT_FOUND',
        'Profile not found. Please complete your registration.');
    }

    profile.oneSignalPlayerId = oneSignalPlayerId;
    await profile.save();

    res.status(200).json({
      message: 'OneSignal Player ID updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get user profile by profile ID (for internal service-to-service calls)
 * GET /api/v1/users/profile/:profileId
 * 
 * Checks both Patient and Doctor collections
 * Used by messaging-service to get participant info
 */
export const getProfileById = async (req, res, next) => {
  try {
    const { profileId } = req.params;

    // Try to find as Patient first
    let profile = await Patient.findById(profileId).select('-__v');
    let role = 'patient';

    // If not found, try Doctor
    if (!profile) {
      profile = await Doctor.findById(profileId).select('-__v');
      role = 'doctor';
    }

    if (!profile) {
      return sendError(res, 404, 'PROFILE_NOT_FOUND',
        'The profile you are looking for does not exist.');
    }

    // Build response with common fields + role-specific fields
    const responseData = {
      _id: profile._id,
      id: profile._id.toString(),
      firstName: profile.firstName,
      lastName: profile.lastName,
      fullName: `${profile.firstName} ${profile.lastName}`,
      name: `${profile.firstName} ${profile.lastName}`,
      phone: profile.phone,
      profilePhoto: profile.profilePhoto,
      role: role,
      userType: role,
      isActive: profile.isActive,
    };

    // Add role-specific fields
    if (role === 'doctor') {
      responseData.specialty = profile.specialty;
      responseData.title = profile.title;
    } else {
      responseData.gender = profile.gender;
      responseData.dateOfBirth = profile.dateOfBirth;
    }

    res.status(200).json({
      data: responseData
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get patient by ID (internal service-to-service call)
 * GET /api/v1/users/patients/:patientId
 * 
 * Only accessible by internal services (via X-Internal-Service header)
 */
export const getPatientById = async (req, res, next) => {
  try {
    const { patientId } = req.params;

    const patient = await Patient.findById(patientId).select('-__v');

    if (!patient) {
      return sendError(res, 404, 'PATIENT_NOT_FOUND',
        'The patient you are looking for does not exist.');
    }

    if (!patient.isActive) {
      return sendError(res, 404, 'PATIENT_NOT_ACTIVE',
        'The patient account is not active.');
    }

    // Return limited patient info for service calls
    res.status(200).json({
      patient: {
        _id: patient._id,
        firstName: patient.firstName,
        lastName: patient.lastName,
        phone: patient.phone,
        gender: patient.gender,
        dateOfBirth: patient.dateOfBirth,
        profilePhoto: patient.profilePhoto,
        bloodType: patient.bloodType,
        allergies: patient.allergies,
        chronicDiseases: patient.chronicDiseases
      }
    });
  } catch (error) {
    next(error);
  }
};
