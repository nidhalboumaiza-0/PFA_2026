import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

// Alias for ObjectId
const ObjectId = mongoose.Types.ObjectId;

// ============================================================
// COMPREHENSIVE SEED DATA - Step by Step
// Respects all entity relationships and schema constraints
// ============================================================

const MONGO_URI_BASE = process.env.MONGO_URI || 'mongodb://admin:password@localhost:27017';

const DB_NAMES = {
    AUTH: 'esante_auth',
    USER: 'esante_users',
    RDV: 'esante_rdv',
    MEDICAL: 'esante_medical_records',
    MESSAGING: 'esante_messaging',
    NOTIFICATION: 'esante_notifications',
    REFERRAL: 'esante_referrals'
};

// Create database connections
const createConnection = (dbName) => {
    return mongoose.createConnection(`${MONGO_URI_BASE}/${dbName}?authSource=admin`);
};

// ============================================================
// STEP 1: Generate IDs upfront (for cross-referencing)
// ============================================================

// We generate all IDs first so we can reference them across entities
const IDS = {
    // Auth User IDs (authId)
    authUsers: {
        admin: new mongoose.Types.ObjectId(),
        doctor1: new mongoose.Types.ObjectId(),
        doctor2: new mongoose.Types.ObjectId(),
        doctor3: new mongoose.Types.ObjectId(),
        doctor4: new mongoose.Types.ObjectId(),
        patient1: new mongoose.Types.ObjectId(),
        patient2: new mongoose.Types.ObjectId(),
        patient3: new mongoose.Types.ObjectId(),
        patient4: new mongoose.Types.ObjectId()
    },
    // Profile IDs (profileId) - for doctors and patients
    profiles: {
        doctor1: new mongoose.Types.ObjectId(),
        doctor2: new mongoose.Types.ObjectId(),
        doctor3: new mongoose.Types.ObjectId(),
        doctor4: new mongoose.Types.ObjectId(),
        patient1: new mongoose.Types.ObjectId(),
        patient2: new mongoose.Types.ObjectId(),
        patient3: new mongoose.Types.ObjectId(),
        patient4: new mongoose.Types.ObjectId()
    },
    // Appointment IDs
    appointments: {
        apt1: new mongoose.Types.ObjectId(),  // patient1 with doctor1 - COMPLETED
        apt2: new mongoose.Types.ObjectId(),  // patient1 with doctor2 - COMPLETED
        apt3: new mongoose.Types.ObjectId(),  // patient2 with doctor1 - COMPLETED
        apt4: new mongoose.Types.ObjectId(),  // patient2 with doctor3 - CONFIRMED (upcoming)
        apt5: new mongoose.Types.ObjectId(),  // patient3 with doctor2 - COMPLETED
        apt6: new mongoose.Types.ObjectId(),  // patient3 with doctor4 - PENDING
        apt7: new mongoose.Types.ObjectId(),  // patient1 with doctor3 - CONFIRMED (upcoming)
        apt8: new mongoose.Types.ObjectId()   // patient4 with doctor1 - COMPLETED
    },
    // Consultation IDs (only for completed appointments)
    consultations: {
        cons1: new mongoose.Types.ObjectId(),  // for apt1
        cons2: new mongoose.Types.ObjectId(),  // for apt2
        cons3: new mongoose.Types.ObjectId(),  // for apt3
        cons4: new mongoose.Types.ObjectId(),  // for apt5
        cons5: new mongoose.Types.ObjectId()   // for apt8
    },
    // Prescription IDs
    prescriptions: {
        presc1: new mongoose.Types.ObjectId(),  // for cons1
        presc2: new mongoose.Types.ObjectId(),  // for cons2
        presc3: new mongoose.Types.ObjectId(),  // for cons3
        presc4: new mongoose.Types.ObjectId()   // for cons5
    },
    // Medical Document IDs
    documents: {
        doc1: new mongoose.Types.ObjectId(),  // patient1 lab result
        doc2: new mongoose.Types.ObjectId(),  // patient1 imaging
        doc3: new mongoose.Types.ObjectId(),  // patient2 medical report
        doc4: new mongoose.Types.ObjectId(),  // patient3 lab result
        doc5: new mongoose.Types.ObjectId()   // patient4 insurance doc
    },
    // Referral IDs
    referrals: {
        ref1: new mongoose.Types.ObjectId(),  // doctor1 -> doctor2 for patient1
        ref2: new mongoose.Types.ObjectId(),  // doctor2 -> doctor3 for patient3
        ref3: new mongoose.Types.ObjectId()   // doctor1 -> doctor4 for patient2
    },
    // Conversation IDs
    conversations: {
        conv1: new mongoose.Types.ObjectId(),  // patient1 <-> doctor1
        conv2: new mongoose.Types.ObjectId(),  // patient1 <-> doctor2
        conv3: new mongoose.Types.ObjectId(),  // patient2 <-> doctor1
        conv4: new mongoose.Types.ObjectId(),  // patient3 <-> doctor2
        conv5: new mongoose.Types.ObjectId(),  // patient4 <-> doctor1
        conv6: new mongoose.Types.ObjectId()   // doctor1 <-> doctor2 (doctor-doctor)
    },
    // Message IDs
    messages: {
        msg1: new mongoose.Types.ObjectId(),
        msg2: new mongoose.Types.ObjectId(),
        msg3: new mongoose.Types.ObjectId(),
        msg4: new mongoose.Types.ObjectId(),
        msg5: new mongoose.Types.ObjectId(),
        msg6: new mongoose.Types.ObjectId()
    },
    // TimeSlot IDs
    timeSlots: []  // Will be generated dynamically
};

// ============================================================
// STEP 2: AUTH USERS (esante_auth.users)
// ============================================================

const createAuthUsers = async (passwordHash) => {
    return [
        // Admin
        {
            _id: IDS.authUsers.admin,
            email: 'admin@esante.tn',
            password: passwordHash,
            role: 'admin',
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(),
            createdAt: new Date('2024-01-01'),
            updatedAt: new Date()
        },
        // Doctors
        {
            _id: IDS.authUsers.doctor1,
            email: 'ahmed.benali@esante.tn',
            password: passwordHash,
            role: 'doctor',
            profileId: IDS.profiles.doctor1,  // Links to Doctor profile
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
            createdAt: new Date('2024-01-15'),
            updatedAt: new Date()
        },
        {
            _id: IDS.authUsers.doctor2,
            email: 'fatma.trabelsi@esante.tn',
            password: passwordHash,
            role: 'doctor',
            profileId: IDS.profiles.doctor2,
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
            createdAt: new Date('2024-02-01'),
            updatedAt: new Date()
        },
        {
            _id: IDS.authUsers.doctor3,
            email: 'youssef.hammami@esante.tn',
            password: passwordHash,
            role: 'doctor',
            profileId: IDS.profiles.doctor3,
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(Date.now() - 5 * 60 * 60 * 1000),
            createdAt: new Date('2024-02-15'),
            updatedAt: new Date()
        },
        {
            _id: IDS.authUsers.doctor4,
            email: 'khadija.sassi@esante.tn',
            password: passwordHash,
            role: 'doctor',
            profileId: IDS.profiles.doctor4,
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(Date.now() - 48 * 60 * 60 * 1000),
            createdAt: new Date('2024-03-01'),
            updatedAt: new Date()
        },
        // Patients
        {
            _id: IDS.authUsers.patient1,
            email: 'mohamed.belhaj@gmail.com',
            password: passwordHash,
            role: 'patient',
            profileId: IDS.profiles.patient1,  // Links to Patient profile
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(Date.now() - 1 * 60 * 60 * 1000), // 1 hour ago
            createdAt: new Date('2024-03-15'),
            updatedAt: new Date()
        },
        {
            _id: IDS.authUsers.patient2,
            email: 'leila.jebali@gmail.com',
            password: passwordHash,
            role: 'patient',
            profileId: IDS.profiles.patient2,
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(Date.now() - 3 * 60 * 60 * 1000),
            createdAt: new Date('2024-04-01'),
            updatedAt: new Date()
        },
        {
            _id: IDS.authUsers.patient3,
            email: 'karim.nasri@gmail.com',
            password: passwordHash,
            role: 'patient',
            profileId: IDS.profiles.patient3,
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(Date.now() - 12 * 60 * 60 * 1000),
            createdAt: new Date('2024-04-15'),
            updatedAt: new Date()
        },
        {
            _id: IDS.authUsers.patient4,
            email: 'sara.khemiri@gmail.com',
            password: passwordHash,
            role: 'patient',
            profileId: IDS.profiles.patient4,
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(Date.now() - 6 * 60 * 60 * 1000),
            createdAt: new Date('2024-05-01'),
            updatedAt: new Date()
        }
    ];
};

// ============================================================
// STEP 3: DOCTOR PROFILES (esante_users.doctors)
// ============================================================

// Base coordinates for Android Emulator (Mountain View, CA)
const BASE_COORDS = { lng: -122.0840, lat: 37.4220 };

const getNearbyCoords = (index) => {
    const offsets = [
        [0.005, 0.003],   // ~500m away
        [-0.008, 0.006],  // ~1km away
        [0.012, -0.004],  // ~1.5km away
        [-0.003, -0.009]  // ~1km away
    ];
    const [lngOff, latOff] = offsets[index % offsets.length];
    return [BASE_COORDS.lng + lngOff, BASE_COORDS.lat + latOff];
};

const defaultWorkingHours = [
    { day: 'Monday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '18:00' }] },
    { day: 'Tuesday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '18:00' }] },
    { day: 'Wednesday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '18:00' }] },
    { day: 'Thursday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '18:00' }] },
    { day: 'Friday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '17:00' }] },
    { day: 'Saturday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '13:00' }] },
    { day: 'Sunday', isAvailable: false, slots: [] }
];

const createDoctorProfiles = () => {
    return [
        {
            _id: IDS.profiles.doctor1,
            userId: IDS.authUsers.doctor1,  // Links back to Auth User
            firstName: 'Ahmed',
            lastName: 'Ben Ali',
            specialty: 'General Practice',
            subSpecialty: 'Family Medicine',
            phone: '+216 71 123 456',
            profilePhoto: null,
            licenseNumber: 'TN-MG-2015-001',
            yearsOfExperience: 12,
            education: [
                { degree: 'Doctor of Medicine', institution: 'Faculty of Medicine of Tunis', year: 2012 },
                { degree: 'Residency in General Medicine', institution: 'Charles Nicolle Hospital', year: 2015 }
            ],
            languages: ['French', 'Arabic', 'English'],
            clinicName: 'Ben Ali Medical Office',
            clinicAddress: {
                street: '45 Avenue Habib Bourguiba',
                city: 'Tunis',
                state: 'Tunis',
                zipCode: '1000',
                country: 'Tunisia',
                coordinates: {
                    type: 'Point',
                    coordinates: getNearbyCoords(0)
                }
            },
            about: 'Experienced general practitioner with over 12 years of practice. Specialized in family medicine and prevention.',
            consultationFee: 60,
            acceptsInsurance: true,
            rating: 4.8,
            totalReviews: 156,
            workingHours: defaultWorkingHours,
            isVerified: true,
            isActive: true,
            createdAt: new Date('2024-01-15'),
            updatedAt: new Date()
        },
        {
            _id: IDS.profiles.doctor2,
            userId: IDS.authUsers.doctor2,
            firstName: 'Fatma',
            lastName: 'Trabelsi',
            specialty: 'Cardiology',
            subSpecialty: 'Echocardiography',
            phone: '+216 71 234 567',
            profilePhoto: null,
            licenseNumber: 'TN-CD-2010-042',
            yearsOfExperience: 18,
            education: [
                { degree: 'Doctor of Medicine', institution: 'Faculty of Medicine of Sousse', year: 2006 },
                { degree: 'Cardiology Specialization', institution: 'La Rabta Hospital', year: 2010 }
            ],
            languages: ['French', 'Arabic', 'English'],
            clinicName: 'Trabelsi Cardiology Center',
            clinicAddress: {
                street: '123 Rue de Marseille, Les Berges du Lac',
                city: 'Tunis',
                state: 'Tunis',
                zipCode: '1053',
                country: 'Tunisia',
                coordinates: {
                    type: 'Point',
                    coordinates: getNearbyCoords(1)
                }
            },
            about: 'Board-certified cardiologist with expertise in echocardiography and cardiovascular diseases.',
            consultationFee: 100,
            acceptsInsurance: true,
            rating: 4.9,
            totalReviews: 234,
            workingHours: defaultWorkingHours,
            isVerified: true,
            isActive: true,
            createdAt: new Date('2024-02-01'),
            updatedAt: new Date()
        },
        {
            _id: IDS.profiles.doctor3,
            userId: IDS.authUsers.doctor3,
            firstName: 'Youssef',
            lastName: 'Hammami',
            specialty: 'Dermatology',
            subSpecialty: 'Aesthetic Dermatology',
            phone: '+216 71 345 678',
            profilePhoto: null,
            licenseNumber: 'TN-DM-2013-089',
            yearsOfExperience: 14,
            education: [
                { degree: 'Doctor of Medicine', institution: 'Faculty of Medicine of Tunis', year: 2009 },
                { degree: 'Dermatology Diploma', institution: 'Habib Thameur Hospital', year: 2013 }
            ],
            languages: ['French', 'Arabic', 'English'],
            clinicName: 'Hammami Dermatology Clinic',
            clinicAddress: {
                street: '78 Avenue de la Liberté, Belvédère',
                city: 'Tunis',
                state: 'Tunis',
                zipCode: '1002',
                country: 'Tunisia',
                coordinates: {
                    type: 'Point',
                    coordinates: getNearbyCoords(2)
                }
            },
            about: 'Dermatologist specialized in skin disease treatment and aesthetic dermatology.',
            consultationFee: 80,
            acceptsInsurance: true,
            rating: 4.7,
            totalReviews: 189,
            workingHours: defaultWorkingHours,
            isVerified: true,
            isActive: true,
            createdAt: new Date('2024-02-15'),
            updatedAt: new Date()
        },
        {
            _id: IDS.profiles.doctor4,
            userId: IDS.authUsers.doctor4,
            firstName: 'Khadija',
            lastName: 'Sassi',
            specialty: 'Pediatrics',
            subSpecialty: 'Neonatology',
            phone: '+216 71 456 789',
            profilePhoto: null,
            licenseNumber: 'TN-PD-2011-156',
            yearsOfExperience: 16,
            education: [
                { degree: 'Doctor of Medicine', institution: 'Faculty of Medicine of Monastir', year: 2007 },
                { degree: 'Pediatrics Specialization', institution: "Children's Hospital of Tunis", year: 2011 }
            ],
            languages: ['French', 'Arabic'],
            clinicName: 'Sassi Pediatric Office',
            clinicAddress: {
                street: '34 Rue Alain Savary, El Menzah',
                city: 'Tunis',
                state: 'Tunis',
                zipCode: '1004',
                country: 'Tunisia',
                coordinates: {
                    type: 'Point',
                    coordinates: getNearbyCoords(3)
                }
            },
            about: "Dedicated pediatrician passionate about children's health. Specialized in neonatology.",
            consultationFee: 70,
            acceptsInsurance: true,
            rating: 4.9,
            totalReviews: 312,
            workingHours: defaultWorkingHours,
            isVerified: true,
            isActive: true,
            createdAt: new Date('2024-03-01'),
            updatedAt: new Date()
        }
    ];
};

// ============================================================
// STEP 4: PATIENT PROFILES (esante_users.patients)
// ============================================================

const createPatientProfiles = () => {
    return [
        {
            _id: IDS.profiles.patient1,
            userId: IDS.authUsers.patient1,  // Links back to Auth User
            firstName: 'Mohamed',
            lastName: 'Belhaj',
            dateOfBirth: new Date('1985-03-15'),
            gender: 'male',
            phone: '+216 20 111 111',
            profilePhoto: null,
            address: {
                street: '23 Rue Ibn Khaldoun',
                city: 'Tunis',
                state: 'Tunis',
                zipCode: '1000',
                country: 'Tunisia',
                coordinates: {
                    type: 'Point',
                    coordinates: [BASE_COORDS.lng + 0.002, BASE_COORDS.lat + 0.001]
                }
            },
            bloodType: 'A+',
            allergies: ['Penicillin'],
            chronicDiseases: ['Hypertension'],
            emergencyContact: {
                name: 'Sonia Belhaj',
                relationship: 'Wife',
                phone: '+216 20 111 222'
            },
            insuranceInfo: {
                provider: 'CNAM',
                policyNumber: 'CNAM-2023-789456',
                expiryDate: new Date('2026-12-31')
            },
            isActive: true,
            createdAt: new Date('2024-03-15'),
            updatedAt: new Date()
        },
        {
            _id: IDS.profiles.patient2,
            userId: IDS.authUsers.patient2,
            firstName: 'Leila',
            lastName: 'Jebali',
            dateOfBirth: new Date('1990-07-22'),
            gender: 'female',
            phone: '+216 22 222 222',
            profilePhoto: null,
            address: {
                street: '67 Avenue de Carthage',
                city: 'Tunis',
                state: 'Tunis',
                zipCode: '1000',
                country: 'Tunisia',
                coordinates: {
                    type: 'Point',
                    coordinates: [BASE_COORDS.lng - 0.003, BASE_COORDS.lat + 0.004]
                }
            },
            bloodType: 'O+',
            allergies: [],
            chronicDiseases: [],
            emergencyContact: {
                name: 'Karim Jebali',
                relationship: 'Brother',
                phone: '+216 22 222 333'
            },
            insuranceInfo: {
                provider: 'CNRPS',
                policyNumber: 'CNRPS-2024-123456',
                expiryDate: new Date('2027-06-30')
            },
            isActive: true,
            createdAt: new Date('2024-04-01'),
            updatedAt: new Date()
        },
        {
            _id: IDS.profiles.patient3,
            userId: IDS.authUsers.patient3,
            firstName: 'Karim',
            lastName: 'Nasri',
            dateOfBirth: new Date('1978-11-08'),
            gender: 'male',
            phone: '+216 23 333 333',
            profilePhoto: null,
            address: {
                street: '89 Rue de Bizerte, Bab Saadoun',
                city: 'Tunis',
                state: 'Tunis',
                zipCode: '1005',
                country: 'Tunisia',
                coordinates: {
                    type: 'Point',
                    coordinates: [BASE_COORDS.lng + 0.007, BASE_COORDS.lat - 0.002]
                }
            },
            bloodType: 'B+',
            allergies: ['Aspirin', 'Seafood'],
            chronicDiseases: ['Diabetes Type 2', 'High Cholesterol'],
            emergencyContact: {
                name: 'Amina Nasri',
                relationship: 'Wife',
                phone: '+216 23 333 444'
            },
            insuranceInfo: {
                provider: 'STAR Assurance',
                policyNumber: 'STAR-2023-567890',
                expiryDate: new Date('2026-08-15')
            },
            isActive: true,
            createdAt: new Date('2024-04-15'),
            updatedAt: new Date()
        },
        {
            _id: IDS.profiles.patient4,
            userId: IDS.authUsers.patient4,
            firstName: 'Sara',
            lastName: 'Khemiri',
            dateOfBirth: new Date('1995-02-14'),
            gender: 'female',
            phone: '+216 24 444 444',
            profilePhoto: null,
            address: {
                street: '15 Rue Farhat Hached, El Manar',
                city: 'Tunis',
                state: 'Tunis',
                zipCode: '2092',
                country: 'Tunisia',
                coordinates: {
                    type: 'Point',
                    coordinates: [BASE_COORDS.lng - 0.005, BASE_COORDS.lat - 0.003]
                }
            },
            bloodType: 'AB+',
            allergies: ['Peanuts'],
            chronicDiseases: [],
            emergencyContact: {
                name: 'Hassan Khemiri',
                relationship: 'Father',
                phone: '+216 24 444 555'
            },
            insuranceInfo: {
                provider: 'GAT Assurance',
                policyNumber: 'GAT-2024-345678',
                expiryDate: new Date('2027-03-20')
            },
            isActive: true,
            createdAt: new Date('2024-05-01'),
            updatedAt: new Date()
        }
    ];
};

// ============================================================
// MAIN SEED FUNCTION - STEP 1: Users & Profiles
// ============================================================

const seedStep1 = async () => {
    console.log('🌱 STEP 1: Creating Auth Users and Profiles...\n');

    const authConn = createConnection(DB_NAMES.AUTH);
    const userConn = createConnection(DB_NAMES.USER);

    await Promise.all([
        new Promise(resolve => authConn.on('connected', resolve)),
        new Promise(resolve => userConn.on('connected', resolve))
    ]);
    console.log('✅ Connected to databases\n');

    try {
        // Clear existing data
        console.log('🧹 Clearing existing auth and user data...');
        await authConn.dropDatabase();
        await userConn.dropDatabase();

        // Hash password
        const passwordHash = await bcrypt.hash('password123', 10);

        // Create Auth Users
        const authUsers = await createAuthUsers(passwordHash);
        await authConn.collection('users').insertMany(authUsers);
        console.log(`✅ Created ${authUsers.length} auth users`);

        // Create Doctor Profiles
        const doctors = createDoctorProfiles();
        await userConn.collection('doctors').insertMany(doctors);
        console.log(`✅ Created ${doctors.length} doctor profiles`);

        // Create Patient Profiles
        const patients = createPatientProfiles();
        await userConn.collection('patients').insertMany(patients);
        console.log(`✅ Created ${patients.length} patient profiles`);

        // Create indexes
        await userConn.collection('doctors').createIndex({ 'clinicAddress.coordinates': '2dsphere' });
        await userConn.collection('patients').createIndex({ 'address.coordinates': '2dsphere' });
        await userConn.collection('doctors').createIndex({ firstName: 'text', lastName: 'text', clinicName: 'text', specialty: 'text' });
        console.log('✅ Created geospatial and text indexes\n');

        // Print summary
        console.log('═══════════════════════════════════════════════════════════');
        console.log('📋 STEP 1 COMPLETE - Users & Profiles Created');
        console.log('═══════════════════════════════════════════════════════════\n');

        console.log('🔐 AUTH USERS (Password: password123):');
        console.log('─────────────────────────────────────────');
        console.log(`   Admin:    admin@esante.tn`);
        console.log('');
        console.log('   Doctors:');
        doctors.forEach((doc, i) => {
            const user = authUsers.find(u => u.profileId?.toString() === doc._id.toString());
            console.log(`     ${i + 1}. Dr. ${doc.firstName} ${doc.lastName} (${doc.specialty})`);
            console.log(`        Email: ${user.email}`);
            console.log(`        AuthID: ${user._id}`);
            console.log(`        ProfileID: ${doc._id}`);
        });
        console.log('');
        console.log('   Patients:');
        patients.forEach((pat, i) => {
            const user = authUsers.find(u => u.profileId?.toString() === pat._id.toString());
            console.log(`     ${i + 1}. ${pat.firstName} ${pat.lastName}`);
            console.log(`        Email: ${user.email}`);
            console.log(`        AuthID: ${user._id}`);
            console.log(`        ProfileID: ${pat._id}`);
        });

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('📌 ID MAPPING (for next steps):');
        console.log('═══════════════════════════════════════════════════════════');
        console.log('\nDoctors (use profileId for appointments/consultations):');
        console.log(`   doctor1 (Ahmed Ben Ali):     ${IDS.profiles.doctor1}`);
        console.log(`   doctor2 (Fatma Trabelsi):    ${IDS.profiles.doctor2}`);
        console.log(`   doctor3 (Youssef Hammami):   ${IDS.profiles.doctor3}`);
        console.log(`   doctor4 (Khadija Sassi):     ${IDS.profiles.doctor4}`);
        console.log('\nPatients (use profileId for appointments/consultations):');
        console.log(`   patient1 (Mohamed Belhaj):   ${IDS.profiles.patient1}`);
        console.log(`   patient2 (Leila Jebali):     ${IDS.profiles.patient2}`);
        console.log(`   patient3 (Karim Nasri):      ${IDS.profiles.patient3}`);
        console.log(`   patient4 (Sara Khemiri):     ${IDS.profiles.patient4}`);

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('👉 Type "continue" to proceed to STEP 2: TimeSlots & Appointments');
        console.log('═══════════════════════════════════════════════════════════\n');

    } catch (error) {
        console.error('❌ Step 1 Failed:', error);
    } finally {
        await authConn.close();
        await userConn.close();
    }
};

// ============================================================
// STEP 5: TIME SLOTS (esante_rdv.timeslots)
// ============================================================

const createTimeSlots = (doctors) => {
    const timeSlots = [];
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    // Generate slots from working hours
    const generateSlotsForDay = (workingHours, dayName) => {
        const daySchedule = workingHours.find(wh => wh.day === dayName);
        if (!daySchedule || !daySchedule.isAvailable) return [];

        const slots = [];
        for (const period of daySchedule.slots) {
            const [startHour, startMin] = period.startTime.split(':').map(Number);
            const [endHour, endMin] = period.endTime.split(':').map(Number);

            let currentHour = startHour;
            let currentMin = startMin;

            while (currentHour < endHour || (currentHour === endHour && currentMin < endMin)) {
                slots.push({
                    time: `${String(currentHour).padStart(2, '0')}:${String(currentMin).padStart(2, '0')}`,
                    isBooked: false,
                    appointmentId: null
                });
                currentMin += 30;
                if (currentMin >= 60) {
                    currentMin = 0;
                    currentHour++;
                }
            }
        }
        return slots;
    };

    // Create time slots for next 30 days for each doctor
    for (const doctor of doctors) {
        for (let dayOffset = -30; dayOffset < 30; dayOffset++) {  // Past 30 days + next 30 days
            const date = new Date();
            date.setDate(date.getDate() + dayOffset);
            date.setHours(0, 0, 0, 0);

            const dayName = dayNames[date.getDay()];
            const slots = generateSlotsForDay(doctor.workingHours || defaultWorkingHours, dayName);

            if (slots.length > 0) {
                timeSlots.push({
                    _id: new mongoose.Types.ObjectId(),
                    doctorId: doctor._id,
                    date: date,
                    slots: slots,
                    isAvailable: true,
                    createdAt: new Date(),
                    updatedAt: new Date()
                });
            }
        }
    }

    return timeSlots;
};

// ============================================================
// STEP 6: APPOINTMENTS (esante_rdv.appointments)
// ============================================================

const createAppointments = () => {
    const now = new Date();
    
    // Helper to create date
    const daysAgo = (days) => {
        const d = new Date(now);
        d.setDate(d.getDate() - days);
        d.setHours(9, 0, 0, 0);
        return d;
    };
    
    const daysFromNow = (days) => {
        const d = new Date(now);
        d.setDate(d.getDate() + days);
        d.setHours(10, 0, 0, 0);
        return d;
    };

    return [
        // APT1: Patient1 (Mohamed) with Doctor1 (Ahmed) - COMPLETED 15 days ago
        {
            _id: IDS.appointments.apt1,
            patientId: IDS.profiles.patient1,
            doctorId: IDS.profiles.doctor1,
            appointmentDate: daysAgo(15),
            appointmentTime: '09:00',
            duration: 30,
            status: 'completed',
            reason: 'General checkup and blood pressure monitoring',
            notes: 'Patient has history of hypertension',
            isReferral: false,
            confirmedAt: daysAgo(17),
            completedAt: daysAgo(15),
            reminderSent: true,
            reminderSentAt: daysAgo(16),
            createdAt: daysAgo(20),
            updatedAt: daysAgo(15)
        },
        // APT2: Patient1 (Mohamed) with Doctor2 (Fatma - Cardio) - COMPLETED 10 days ago (REFERRED)
        {
            _id: IDS.appointments.apt2,
            patientId: IDS.profiles.patient1,
            doctorId: IDS.profiles.doctor2,
            appointmentDate: daysAgo(10),
            appointmentTime: '14:00',
            duration: 45,
            status: 'completed',
            reason: 'Cardiovascular examination - referred by Dr. Ben Ali',
            notes: 'Referral for heart checkup due to hypertension',
            isReferral: true,
            referredBy: IDS.profiles.doctor1,
            referralId: IDS.referrals.ref1,
            confirmedAt: daysAgo(12),
            completedAt: daysAgo(10),
            reminderSent: true,
            reminderSentAt: daysAgo(11),
            createdAt: daysAgo(14),
            updatedAt: daysAgo(10)
        },
        // APT3: Patient2 (Leila) with Doctor1 (Ahmed) - COMPLETED 8 days ago
        {
            _id: IDS.appointments.apt3,
            patientId: IDS.profiles.patient2,
            doctorId: IDS.profiles.doctor1,
            appointmentDate: daysAgo(8),
            appointmentTime: '10:30',
            duration: 30,
            status: 'completed',
            reason: 'Annual health checkup',
            notes: 'Routine examination, no prior conditions',
            isReferral: false,
            confirmedAt: daysAgo(10),
            completedAt: daysAgo(8),
            reminderSent: true,
            reminderSentAt: daysAgo(9),
            createdAt: daysAgo(15),
            updatedAt: daysAgo(8)
        },
        // APT4: Patient2 (Leila) with Doctor3 (Youssef - Derma) - CONFIRMED in 3 days
        {
            _id: IDS.appointments.apt4,
            patientId: IDS.profiles.patient2,
            doctorId: IDS.profiles.doctor3,
            appointmentDate: daysFromNow(3),
            appointmentTime: '11:00',
            duration: 30,
            status: 'confirmed',
            reason: 'Skin consultation for recurring rash',
            notes: 'First visit to dermatologist',
            isReferral: false,
            confirmedAt: daysAgo(2),
            reminderSent: false,
            createdAt: daysAgo(5),
            updatedAt: daysAgo(2)
        },
        // APT5: Patient3 (Karim) with Doctor2 (Fatma - Cardio) - COMPLETED 5 days ago
        {
            _id: IDS.appointments.apt5,
            patientId: IDS.profiles.patient3,
            doctorId: IDS.profiles.doctor2,
            appointmentDate: daysAgo(5),
            appointmentTime: '15:00',
            duration: 45,
            status: 'completed',
            reason: 'Cardiac followup for diabetes patient',
            notes: 'Patient has Type 2 diabetes and high cholesterol',
            isReferral: false,
            confirmedAt: daysAgo(7),
            completedAt: daysAgo(5),
            reminderSent: true,
            reminderSentAt: daysAgo(6),
            createdAt: daysAgo(12),
            updatedAt: daysAgo(5)
        },
        // APT6: Patient3 (Karim) with Doctor4 (Khadija - Pediatrics) - PENDING (for his child)
        {
            _id: IDS.appointments.apt6,
            patientId: IDS.profiles.patient3,
            doctorId: IDS.profiles.doctor4,
            appointmentDate: daysFromNow(5),
            appointmentTime: '09:30',
            duration: 30,
            status: 'pending',
            reason: 'Pediatric consultation for child vaccination',
            notes: 'Scheduled for 6-month vaccination',
            isReferral: false,
            reminderSent: false,
            createdAt: daysAgo(1),
            updatedAt: daysAgo(1)
        },
        // APT7: Patient1 (Mohamed) with Doctor3 (Youssef - Derma) - CONFIRMED in 7 days
        {
            _id: IDS.appointments.apt7,
            patientId: IDS.profiles.patient1,
            doctorId: IDS.profiles.doctor3,
            appointmentDate: daysFromNow(7),
            appointmentTime: '14:30',
            duration: 30,
            status: 'confirmed',
            reason: 'Skin checkup - mole examination',
            notes: 'Patient noticed changes in existing mole',
            isReferral: false,
            confirmedAt: daysAgo(1),
            reminderSent: false,
            createdAt: daysAgo(3),
            updatedAt: daysAgo(1)
        },
        // APT8: Patient4 (Sara) with Doctor1 (Ahmed) - COMPLETED 3 days ago
        {
            _id: IDS.appointments.apt8,
            patientId: IDS.profiles.patient4,
            doctorId: IDS.profiles.doctor1,
            appointmentDate: daysAgo(3),
            appointmentTime: '16:00',
            duration: 30,
            status: 'completed',
            reason: 'Flu symptoms and fever',
            notes: 'Seasonal flu, prescribed rest and medication',
            isReferral: false,
            confirmedAt: daysAgo(5),
            completedAt: daysAgo(3),
            reminderSent: true,
            reminderSentAt: daysAgo(4),
            createdAt: daysAgo(6),
            updatedAt: daysAgo(3)
        }
    ];
};

// ============================================================
// MAIN SEED FUNCTION - STEP 2: TimeSlots & Appointments
// ============================================================

const seedStep2 = async () => {
    console.log('🌱 STEP 2: Creating TimeSlots and Appointments...\n');

    const userConn = createConnection(DB_NAMES.USER);
    const rdvConn = createConnection(DB_NAMES.RDV);

    await Promise.all([
        new Promise(resolve => userConn.on('connected', resolve)),
        new Promise(resolve => rdvConn.on('connected', resolve))
    ]);
    console.log('✅ Connected to databases\n');

    try {
        // Clear existing RDV data
        console.log('🧹 Clearing existing RDV data...');
        await rdvConn.dropDatabase();

        // Get doctors for timeslot generation
        const doctors = await userConn.collection('doctors').find({}).toArray();
        console.log(`📋 Found ${doctors.length} doctors for timeslot generation`);

        // Create TimeSlots
        const timeSlots = createTimeSlots(doctors);
        await rdvConn.collection('timeslots').insertMany(timeSlots);
        console.log(`✅ Created ${timeSlots.length} timeslot entries (60 days × ${doctors.length} doctors)`);

        // Create Appointments
        const appointments = createAppointments();
        await rdvConn.collection('appointments').insertMany(appointments);
        console.log(`✅ Created ${appointments.length} appointments`);

        // Update TimeSlots to mark booked slots
        console.log('📝 Updating timeslots to mark booked appointments...');
        for (const apt of appointments) {
            const slotDate = new Date(apt.appointmentDate);
            slotDate.setHours(0, 0, 0, 0);
            
            await rdvConn.collection('timeslots').updateOne(
                {
                    doctorId: apt.doctorId,
                    date: slotDate
                },
                {
                    $set: {
                        'slots.$[slot].isBooked': true,
                        'slots.$[slot].appointmentId': apt._id
                    }
                },
                {
                    arrayFilters: [{ 'slot.time': apt.appointmentTime }]
                }
            );
        }
        console.log('✅ Updated timeslots with booked appointments');

        // Create indexes
        await rdvConn.collection('appointments').createIndex({ patientId: 1, status: 1 });
        await rdvConn.collection('appointments').createIndex({ doctorId: 1, status: 1 });
        await rdvConn.collection('appointments').createIndex({ appointmentDate: 1 });
        await rdvConn.collection('timeslots').createIndex({ doctorId: 1, date: 1 }, { unique: true });
        console.log('✅ Created indexes\n');

        // Print summary
        console.log('═══════════════════════════════════════════════════════════');
        console.log('📋 STEP 2 COMPLETE - TimeSlots & Appointments Created');
        console.log('═══════════════════════════════════════════════════════════\n');

        console.log('📅 APPOINTMENTS SUMMARY:');
        console.log('─────────────────────────────────────────');
        
        const statusGroups = {
            completed: appointments.filter(a => a.status === 'completed'),
            confirmed: appointments.filter(a => a.status === 'confirmed'),
            pending: appointments.filter(a => a.status === 'pending')
        };

        console.log(`\n   ✅ COMPLETED (${statusGroups.completed.length}):`);
        statusGroups.completed.forEach(apt => {
            console.log(`      - APT ${apt._id.toString().slice(-6)}: Patient→Doctor on ${apt.appointmentDate.toLocaleDateString()}`);
        });

        console.log(`\n   📋 CONFIRMED (${statusGroups.confirmed.length}):`);
        statusGroups.confirmed.forEach(apt => {
            console.log(`      - APT ${apt._id.toString().slice(-6)}: Patient→Doctor on ${apt.appointmentDate.toLocaleDateString()}`);
        });

        console.log(`\n   ⏳ PENDING (${statusGroups.pending.length}):`);
        statusGroups.pending.forEach(apt => {
            console.log(`      - APT ${apt._id.toString().slice(-6)}: Patient→Doctor on ${apt.appointmentDate.toLocaleDateString()}`);
        });

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('📌 APPOINTMENT ID MAPPING (for consultations):');
        console.log('═══════════════════════════════════════════════════════════');
        console.log(`   apt1 (COMPLETED - Patient1→Doctor1): ${IDS.appointments.apt1}`);
        console.log(`   apt2 (COMPLETED - Patient1→Doctor2): ${IDS.appointments.apt2}`);
        console.log(`   apt3 (COMPLETED - Patient2→Doctor1): ${IDS.appointments.apt3}`);
        console.log(`   apt5 (COMPLETED - Patient3→Doctor2): ${IDS.appointments.apt5}`);
        console.log(`   apt8 (COMPLETED - Patient4→Doctor1): ${IDS.appointments.apt8}`);

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('👉 Type "continue" to proceed to STEP 3: Consultations & Prescriptions');
        console.log('═══════════════════════════════════════════════════════════\n');

    } catch (error) {
        console.error('❌ Step 2 Failed:', error);
    } finally {
        await userConn.close();
        await rdvConn.close();
    }
};

// Export IDs for use in subsequent steps
export { IDS, DB_NAMES, createConnection };

// ============================================================
// CHOOSE WHICH STEP TO RUN
// ============================================================
const STEP = process.env.SEED_STEP || 'all';

// Function to run all steps sequentially
async function runAllSteps() {
    console.log('🚀 Running ALL seed steps sequentially...\n');
    
    try {
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        await seedStep1();
        console.log('\n✅ Step 1 completed\n');
        
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        await seedStep2();
        console.log('\n✅ Step 2 completed\n');
        
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        await seedStep3();
        console.log('\n✅ Step 3 completed\n');
        
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        await seedStep4();
        console.log('\n✅ Step 4 completed\n');
        
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        await seedStep5();
        console.log('\n✅ Step 5 completed\n');
        
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        await seedStep6();
        console.log('\n✅ Step 6 completed\n');
        
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log('🎉 ALL SEED STEPS COMPLETED SUCCESSFULLY!');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error running seed steps:', error);
        process.exit(1);
    }
}

if (STEP === 'all') {
    runAllSteps();
} else if (STEP === '1') {
    seedStep1();
} else if (STEP === '2') {
    seedStep2();
} else if (STEP === '3') {
    seedStep3();
} else if (STEP === '4') {
    seedStep4();
} else if (STEP === '5') {
    seedStep5();
} else if (STEP === '6') {
    seedStep6();
}

// ============================================================
// STEP 7: CONSULTATIONS (esante_medical_records.consultations)
// Only for COMPLETED appointments
// ============================================================

const createConsultations = () => {
    const now = new Date();
    
    const daysAgo = (days) => {
        const d = new Date(now);
        d.setDate(d.getDate() - days);
        return d;
    };

    return [
        // CONS1: For APT1 - Patient1 (Mohamed) with Doctor1 (Ahmed) - General checkup
        {
            _id: IDS.consultations.cons1,
            appointmentId: IDS.appointments.apt1,
            patientId: IDS.profiles.patient1,
            doctorId: IDS.profiles.doctor1,
            consultationDate: daysAgo(15),
            consultationType: 'in-person',
            chiefComplaint: 'Routine checkup for hypertension management and general health assessment',
            medicalNote: {
                symptoms: ['mild headache', 'occasional dizziness', 'fatigue'],
                diagnosis: 'Essential hypertension - controlled. Mild tension headache.',
                physicalExamination: 'General appearance: Alert and oriented. Heart: Regular rhythm, no murmurs. Lungs: Clear bilaterally. Abdomen: Soft, non-tender.',
                vitalSigns: {
                    temperature: 36.8,
                    bloodPressure: '140/90',
                    heartRate: 78,
                    respiratoryRate: 16,
                    oxygenSaturation: 98,
                    weight: 82,
                    height: 175
                },
                labResults: 'Previous labs from 3 months ago: HbA1c 5.8%, Cholesterol 210 mg/dL, Creatinine 0.9 mg/dL',
                additionalNotes: 'Patient compliant with current medication. Advised to reduce salt intake and increase physical activity.'
            },
            prescriptionId: IDS.prescriptions.presc1,
            documentIds: [IDS.documents.doc1],
            requiresFollowUp: true,
            followUpDate: daysAgo(15 - 30), // 30 days after consultation (so 15 days from now)
            followUpNotes: 'Follow up in 1 month to reassess blood pressure control',
            isFromReferral: false,
            status: 'completed',
            createdBy: IDS.profiles.doctor1,
            lastModifiedBy: IDS.profiles.doctor1,
            createdAt: daysAgo(15),
            updatedAt: daysAgo(15)
        },
        // CONS2: For APT2 - Patient1 (Mohamed) with Doctor2 (Fatma - Cardio) - Referral
        {
            _id: IDS.consultations.cons2,
            appointmentId: IDS.appointments.apt2,
            patientId: IDS.profiles.patient1,
            doctorId: IDS.profiles.doctor2,
            consultationDate: daysAgo(10),
            consultationType: 'referral',
            chiefComplaint: 'Referred by Dr. Ben Ali for cardiovascular assessment due to hypertension history',
            medicalNote: {
                symptoms: ['palpitations (occasional)', 'shortness of breath on exertion'],
                diagnosis: 'Hypertensive heart disease - Stage I. No evidence of LVH on echo. Mild diastolic dysfunction.',
                physicalExamination: 'Heart: S1, S2 normal. No S3/S4. No murmurs. JVP not elevated. Peripheral pulses normal.',
                vitalSigns: {
                    temperature: 36.6,
                    bloodPressure: '138/88',
                    heartRate: 72,
                    respiratoryRate: 14,
                    oxygenSaturation: 99,
                    weight: 82,
                    height: 175
                },
                labResults: 'ECG: Normal sinus rhythm. Echocardiogram: EF 60%, mild diastolic dysfunction, no LVH.',
                additionalNotes: 'Recommend continuation of current antihypertensive therapy. Consider adding low-dose aspirin. Lifestyle modifications emphasized.'
            },
            prescriptionId: IDS.prescriptions.presc2,
            documentIds: [IDS.documents.doc2],
            requiresFollowUp: true,
            followUpDate: daysAgo(10 - 90), // 3 months later
            followUpNotes: 'Repeat echo in 6 months. Follow up in 3 months.',
            isFromReferral: true,
            referralId: IDS.referrals.ref1,
            status: 'completed',
            createdBy: IDS.profiles.doctor2,
            lastModifiedBy: IDS.profiles.doctor2,
            createdAt: daysAgo(10),
            updatedAt: daysAgo(10)
        },
        // CONS3: For APT3 - Patient2 (Leila) with Doctor1 (Ahmed) - Annual checkup
        {
            _id: IDS.consultations.cons3,
            appointmentId: IDS.appointments.apt3,
            patientId: IDS.profiles.patient2,
            doctorId: IDS.profiles.doctor1,
            consultationDate: daysAgo(8),
            consultationType: 'in-person',
            chiefComplaint: 'Annual health checkup - no specific complaints',
            medicalNote: {
                symptoms: [],
                diagnosis: 'Healthy adult. No acute findings.',
                physicalExamination: 'General: Well-appearing female. HEENT: Normal. Heart: RRR, no murmurs. Lungs: CTA bilaterally. Abdomen: Soft, NT, ND.',
                vitalSigns: {
                    temperature: 36.5,
                    bloodPressure: '118/75',
                    heartRate: 68,
                    respiratoryRate: 14,
                    oxygenSaturation: 99,
                    weight: 58,
                    height: 165
                },
                labResults: 'Routine labs ordered: CBC, CMP, Lipid panel, TSH',
                additionalNotes: 'Patient in excellent health. Encouraged to maintain current lifestyle. Vaccinations up to date.'
            },
            prescriptionId: IDS.prescriptions.presc3,
            documentIds: [],
            requiresFollowUp: false,
            isFromReferral: false,
            status: 'completed',
            createdBy: IDS.profiles.doctor1,
            lastModifiedBy: IDS.profiles.doctor1,
            createdAt: daysAgo(8),
            updatedAt: daysAgo(8)
        },
        // CONS4: For APT5 - Patient3 (Karim) with Doctor2 (Fatma - Cardio)
        {
            _id: IDS.consultations.cons4,
            appointmentId: IDS.appointments.apt5,
            patientId: IDS.profiles.patient3,
            doctorId: IDS.profiles.doctor2,
            consultationDate: daysAgo(5),
            consultationType: 'in-person',
            chiefComplaint: 'Cardiac evaluation for diabetic patient with high cholesterol',
            medicalNote: {
                symptoms: ['occasional chest discomfort', 'fatigue', 'reduced exercise tolerance'],
                diagnosis: 'Type 2 Diabetes with cardiovascular risk factors. Dyslipidemia. No evidence of CAD on stress test.',
                physicalExamination: 'Heart: RRR, no murmurs. Carotid bruits absent. Peripheral pulses 2+ bilaterally. No edema.',
                vitalSigns: {
                    temperature: 36.7,
                    bloodPressure: '145/92',
                    heartRate: 82,
                    respiratoryRate: 16,
                    oxygenSaturation: 97,
                    weight: 95,
                    height: 178
                },
                labResults: 'HbA1c: 7.2%, LDL: 145 mg/dL, HDL: 38 mg/dL, Triglycerides: 220 mg/dL. Stress test: Negative for ischemia.',
                additionalNotes: 'Intensify statin therapy. Emphasize dietary modifications. Consider adding SGLT2 inhibitor for cardioprotection.'
            },
            prescriptionId: null, // Prescription managed by endocrinologist
            documentIds: [IDS.documents.doc3],
            requiresFollowUp: true,
            followUpDate: daysAgo(5 - 60), // 2 months later
            followUpNotes: 'Repeat lipid panel in 6 weeks. Follow up in 2 months.',
            isFromReferral: false,
            status: 'completed',
            createdBy: IDS.profiles.doctor2,
            lastModifiedBy: IDS.profiles.doctor2,
            createdAt: daysAgo(5),
            updatedAt: daysAgo(5)
        },
        // CONS5: For APT8 - Patient4 (Sara) with Doctor1 (Ahmed) - Flu
        {
            _id: IDS.consultations.cons5,
            appointmentId: IDS.appointments.apt8,
            patientId: IDS.profiles.patient4,
            doctorId: IDS.profiles.doctor1,
            consultationDate: daysAgo(3),
            consultationType: 'in-person',
            chiefComplaint: 'Fever, body aches, sore throat for 2 days',
            medicalNote: {
                symptoms: ['fever 38.5°C', 'myalgia', 'sore throat', 'nasal congestion', 'mild cough'],
                diagnosis: 'Acute viral upper respiratory infection (Influenza-like illness)',
                physicalExamination: 'General: Appears mildly ill. HEENT: Pharyngeal erythema, no exudates. Neck: No lymphadenopathy. Lungs: Clear. Ears: TMs normal.',
                vitalSigns: {
                    temperature: 38.2,
                    bloodPressure: '115/72',
                    heartRate: 88,
                    respiratoryRate: 18,
                    oxygenSaturation: 98,
                    weight: 55,
                    height: 162
                },
                labResults: 'Rapid flu test: Positive for Influenza A',
                additionalNotes: 'Prescribed symptomatic treatment. Advised rest and hydration. Return if symptoms worsen or fever persists >5 days.'
            },
            prescriptionId: IDS.prescriptions.presc4,
            documentIds: [],
            requiresFollowUp: false,
            followUpNotes: 'PRN follow up if symptoms persist or worsen',
            isFromReferral: false,
            status: 'completed',
            createdBy: IDS.profiles.doctor1,
            lastModifiedBy: IDS.profiles.doctor1,
            createdAt: daysAgo(3),
            updatedAt: daysAgo(3)
        }
    ];
};

// ============================================================
// STEP 8: PRESCRIPTIONS (esante_medical_records.prescriptions)
// ============================================================

const createPrescriptions = () => {
    const now = new Date();
    
    const daysAgo = (days) => {
        const d = new Date(now);
        d.setDate(d.getDate() - days);
        return d;
    };

    return [
        // PRESC1: For CONS1 - Patient1 (Mohamed) - Hypertension management
        {
            _id: IDS.prescriptions.presc1,
            consultationId: IDS.consultations.cons1,
            patientId: IDS.profiles.patient1,
            doctorId: IDS.profiles.doctor1,
            prescriptionDate: daysAgo(15),
            medications: [
                {
                    medicationName: 'Amlodipine',
                    dosage: '5mg',
                    form: 'tablet',
                    frequency: 'Once daily in the morning',
                    duration: '30 days',
                    instructions: 'Take with or without food',
                    quantity: 30,
                    notes: 'Continue from previous prescription'
                },
                {
                    medicationName: 'Lisinopril',
                    dosage: '10mg',
                    form: 'tablet',
                    frequency: 'Once daily',
                    duration: '30 days',
                    instructions: 'Take in the evening. Monitor for dry cough.',
                    quantity: 30,
                    notes: 'ACE inhibitor for BP control'
                }
            ],
            generalInstructions: 'Continue low-sodium diet. Regular blood pressure monitoring at home. Aim for BP <140/90.',
            specialWarnings: 'Avoid potassium supplements while on Lisinopril. Report any persistent dry cough.',
            isLocked: true,
            lockedAt: daysAgo(14),
            canEditUntil: daysAgo(14),
            modificationHistory: [
                {
                    modifiedAt: daysAgo(15),
                    modifiedBy: IDS.profiles.doctor1,
                    changeType: 'created',
                    changes: {},
                    previousData: null
                }
            ],
            status: 'active',
            pharmacyName: 'Pharmacie Centrale',
            pharmacyAddress: '12 Avenue Habib Bourguiba, Tunis',
            createdBy: IDS.profiles.doctor1,
            createdAt: daysAgo(15),
            updatedAt: daysAgo(14)
        },
        // PRESC2: For CONS2 - Patient1 (Mohamed) - Cardiac protection
        {
            _id: IDS.prescriptions.presc2,
            consultationId: IDS.consultations.cons2,
            patientId: IDS.profiles.patient1,
            doctorId: IDS.profiles.doctor2,
            prescriptionDate: daysAgo(10),
            medications: [
                {
                    medicationName: 'Aspirin',
                    dosage: '100mg',
                    form: 'tablet',
                    frequency: 'Once daily after lunch',
                    duration: '90 days',
                    instructions: 'Take after meal to reduce stomach irritation',
                    quantity: 90,
                    notes: 'Low-dose aspirin for cardiovascular protection'
                },
                {
                    medicationName: 'Atorvastatin',
                    dosage: '20mg',
                    form: 'tablet',
                    frequency: 'Once daily at bedtime',
                    duration: '90 days',
                    instructions: 'Take at night for maximum efficacy',
                    quantity: 90,
                    notes: 'Statin for cholesterol management'
                }
            ],
            generalInstructions: 'Maintain heart-healthy diet. Regular exercise 30 min/day. Limit alcohol consumption.',
            specialWarnings: 'Report any muscle pain or weakness immediately (statin side effect). Do not take aspirin with other blood thinners.',
            isLocked: true,
            lockedAt: daysAgo(9),
            canEditUntil: daysAgo(9),
            modificationHistory: [
                {
                    modifiedAt: daysAgo(10),
                    modifiedBy: IDS.profiles.doctor2,
                    changeType: 'created',
                    changes: {},
                    previousData: null
                }
            ],
            status: 'active',
            pharmacyName: 'Pharmacie du Lac',
            pharmacyAddress: '45 Rue du Lac Léman, Les Berges du Lac, Tunis',
            createdBy: IDS.profiles.doctor2,
            createdAt: daysAgo(10),
            updatedAt: daysAgo(9)
        },
        // PRESC3: For CONS3 - Patient2 (Leila) - Vitamins only
        {
            _id: IDS.prescriptions.presc3,
            consultationId: IDS.consultations.cons3,
            patientId: IDS.profiles.patient2,
            doctorId: IDS.profiles.doctor1,
            prescriptionDate: daysAgo(8),
            medications: [
                {
                    medicationName: 'Vitamin D3',
                    dosage: '2000 IU',
                    form: 'capsule',
                    frequency: 'Once daily',
                    duration: '60 days',
                    instructions: 'Take with a fatty meal for better absorption',
                    quantity: 60,
                    notes: 'Preventive supplementation'
                },
                {
                    medicationName: 'Omega-3 Fish Oil',
                    dosage: '1000mg',
                    form: 'capsule',
                    frequency: 'Once daily',
                    duration: '60 days',
                    instructions: 'Take with meal',
                    quantity: 60,
                    notes: 'For general cardiovascular health'
                }
            ],
            generalInstructions: 'Maintain balanced diet rich in fruits and vegetables. Continue regular physical activity.',
            specialWarnings: 'None specific for these supplements.',
            isLocked: true,
            lockedAt: daysAgo(7),
            canEditUntil: daysAgo(7),
            modificationHistory: [
                {
                    modifiedAt: daysAgo(8),
                    modifiedBy: IDS.profiles.doctor1,
                    changeType: 'created',
                    changes: {},
                    previousData: null
                }
            ],
            status: 'active',
            pharmacyName: null,
            pharmacyAddress: null,
            createdBy: IDS.profiles.doctor1,
            createdAt: daysAgo(8),
            updatedAt: daysAgo(7)
        },
        // PRESC4: For CONS5 - Patient4 (Sara) - Flu treatment
        {
            _id: IDS.prescriptions.presc4,
            consultationId: IDS.consultations.cons5,
            patientId: IDS.profiles.patient4,
            doctorId: IDS.profiles.doctor1,
            prescriptionDate: daysAgo(3),
            medications: [
                {
                    medicationName: 'Oseltamivir (Tamiflu)',
                    dosage: '75mg',
                    form: 'capsule',
                    frequency: 'Twice daily',
                    duration: '5 days',
                    instructions: 'Take with food to reduce nausea',
                    quantity: 10,
                    notes: 'Antiviral for Influenza A'
                },
                {
                    medicationName: 'Paracetamol',
                    dosage: '500mg',
                    form: 'tablet',
                    frequency: 'Every 6 hours as needed for fever/pain',
                    duration: '5 days',
                    instructions: 'Maximum 4 tablets per day. Do not exceed recommended dose.',
                    quantity: 20,
                    notes: 'For fever and body aches'
                },
                {
                    medicationName: 'Throat Lozenges',
                    dosage: '1 lozenge',
                    form: 'other',
                    frequency: 'Every 2-3 hours as needed',
                    duration: '5 days',
                    instructions: 'Let dissolve slowly in mouth',
                    quantity: 24,
                    notes: 'For sore throat relief'
                }
            ],
            generalInstructions: 'Rest at home for at least 3-5 days. Drink plenty of fluids (2-3 liters/day). Avoid contact with others to prevent spread.',
            specialWarnings: 'Start Tamiflu within 48 hours of symptom onset for best results. Return if breathing difficulty develops.',
            isLocked: true,
            lockedAt: daysAgo(2),
            canEditUntil: daysAgo(2),
            modificationHistory: [
                {
                    modifiedAt: daysAgo(3),
                    modifiedBy: IDS.profiles.doctor1,
                    changeType: 'created',
                    changes: {},
                    previousData: null
                }
            ],
            status: 'active',
            pharmacyName: 'Pharmacie El Manar',
            pharmacyAddress: '8 Rue Farhat Hached, El Manar, Tunis',
            createdBy: IDS.profiles.doctor1,
            createdAt: daysAgo(3),
            updatedAt: daysAgo(2)
        }
    ];
};

// ============================================================
// MAIN SEED FUNCTION - STEP 3: Consultations & Prescriptions
// ============================================================

const seedStep3 = async () => {
    console.log('🌱 STEP 3: Creating Consultations and Prescriptions...\n');

    const medicalConn = createConnection(DB_NAMES.MEDICAL);
    const rdvConn = createConnection(DB_NAMES.RDV);

    await Promise.all([
        new Promise(resolve => medicalConn.on('connected', resolve)),
        new Promise(resolve => rdvConn.on('connected', resolve))
    ]);
    console.log('✅ Connected to databases\n');

    try {
        // Clear existing medical data (but keep structure for documents later)
        console.log('🧹 Clearing existing medical records data...');
        await medicalConn.dropDatabase();

        // Create Consultations
        const consultations = createConsultations();
        await medicalConn.collection('consultations').insertMany(consultations);
        console.log(`✅ Created ${consultations.length} consultations`);

        // Create Prescriptions
        const prescriptions = createPrescriptions();
        await medicalConn.collection('prescriptions').insertMany(prescriptions);
        console.log(`✅ Created ${prescriptions.length} prescriptions`);

        // Create indexes
        await medicalConn.collection('consultations').createIndex({ appointmentId: 1 }, { unique: true });
        await medicalConn.collection('consultations').createIndex({ patientId: 1, consultationDate: -1 });
        await medicalConn.collection('consultations').createIndex({ doctorId: 1, consultationDate: -1 });
        await medicalConn.collection('prescriptions').createIndex({ consultationId: 1 }, { unique: true });
        await medicalConn.collection('prescriptions').createIndex({ patientId: 1, prescriptionDate: -1 });
        console.log('✅ Created indexes\n');

        // Print summary
        console.log('═══════════════════════════════════════════════════════════');
        console.log('📋 STEP 3 COMPLETE - Consultations & Prescriptions Created');
        console.log('═══════════════════════════════════════════════════════════\n');

        console.log('🏥 CONSULTATIONS:');
        console.log('─────────────────────────────────────────');
        consultations.forEach((cons, i) => {
            console.log(`   ${i + 1}. Consultation ${cons._id.toString().slice(-6)}`);
            console.log(`      Patient: ${cons.patientId.toString().slice(-6)} → Doctor: ${cons.doctorId.toString().slice(-6)}`);
            console.log(`      Chief Complaint: ${cons.chiefComplaint.substring(0, 50)}...`);
            console.log(`      Diagnosis: ${cons.medicalNote.diagnosis.substring(0, 50)}...`);
        });

        console.log('\n💊 PRESCRIPTIONS:');
        console.log('─────────────────────────────────────────');
        prescriptions.forEach((presc, i) => {
            console.log(`   ${i + 1}. Prescription ${presc._id.toString().slice(-6)}`);
            console.log(`      For Consultation: ${presc.consultationId.toString().slice(-6)}`);
            console.log(`      Medications: ${presc.medications.map(m => m.medicationName).join(', ')}`);
        });

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('📌 CONSULTATION-PRESCRIPTION MAPPING:');
        console.log('═══════════════════════════════════════════════════════════');
        console.log(`   cons1 → presc1 (Mohamed - Hypertension)`);
        console.log(`   cons2 → presc2 (Mohamed - Cardiac)`);
        console.log(`   cons3 → presc3 (Leila - Vitamins)`);
        console.log(`   cons4 → (no prescription - managed elsewhere)`);
        console.log(`   cons5 → presc4 (Sara - Flu)`);

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('👉 Type "continue" to proceed to STEP 4: Medical Documents & Referrals');
        console.log('═══════════════════════════════════════════════════════════\n');

    } catch (error) {
        console.error('❌ Step 3 Failed:', error);
    } finally {
        await medicalConn.close();
        await rdvConn.close();
    }
};

// ============================================================
// STEP 9: MEDICAL DOCUMENTS (esante_medical_records.medicaldocuments)
// ============================================================

const createMedicalDocuments = () => {
    const now = new Date();
    
    const daysAgo = (days) => {
        const d = new Date(now);
        d.setDate(d.getDate() - days);
        return d;
    };

    return [
        // DOC1: Lab results for Patient1 (Mohamed) - Blood work for hypertension
        {
            _id: IDS.documents.doc1,
            patientId: IDS.profiles.patient1,
            uploadedBy: IDS.profiles.doctor1,
            uploaderType: 'doctor',
            uploaderDoctorId: IDS.profiles.doctor1,
            consultationId: IDS.consultations.cons1,
            documentType: 'lab_result',
            title: 'Blood Work Panel - Hypertension Follow-up',
            description: 'Complete blood count, metabolic panel, and lipid profile for hypertension management',
            fileName: 'blood_work_panel_mohamed_2025.pdf',
            fileSize: 245678,
            mimeType: 'application/pdf',
            fileExtension: 'pdf',
            s3Key: `medical-documents/${IDS.profiles.patient1}/lab_results/blood_work_panel_2025.pdf`,
            s3Bucket: 'esante-medical-documents',
            s3Url: `https://esante-medical-documents.s3.amazonaws.com/medical-documents/${IDS.profiles.patient1}/lab_results/blood_work_panel_2025.pdf`,
            documentDate: daysAgo(18),
            uploadDate: daysAgo(15),
            isSharedWithAllDoctors: true,
            sharedWithDoctors: [IDS.profiles.doctor1, IDS.profiles.doctor2],
            tags: ['blood work', 'hypertension', 'lipid panel', 'cbc'],
            status: 'active',
            createdAt: daysAgo(15),
            updatedAt: daysAgo(15)
        },
        // DOC2: ECG/Echo for Patient1 (Mohamed) - Cardiology consultation
        {
            _id: IDS.documents.doc2,
            patientId: IDS.profiles.patient1,
            uploadedBy: IDS.profiles.doctor2,
            uploaderType: 'doctor',
            uploaderDoctorId: IDS.profiles.doctor2,
            consultationId: IDS.consultations.cons2,
            documentType: 'imaging',
            title: 'Echocardiogram Report',
            description: '2D Echocardiogram with Doppler - Cardiac function assessment',
            fileName: 'echocardiogram_mohamed_jan2026.pdf',
            fileSize: 1567890,
            mimeType: 'application/pdf',
            fileExtension: 'pdf',
            s3Key: `medical-documents/${IDS.profiles.patient1}/imaging/echocardiogram_jan2026.pdf`,
            s3Bucket: 'esante-medical-documents',
            s3Url: `https://esante-medical-documents.s3.amazonaws.com/medical-documents/${IDS.profiles.patient1}/imaging/echocardiogram_jan2026.pdf`,
            documentDate: daysAgo(11),
            uploadDate: daysAgo(10),
            isSharedWithAllDoctors: true,
            sharedWithDoctors: [IDS.profiles.doctor1, IDS.profiles.doctor2],
            tags: ['echocardiogram', 'cardiology', 'heart', 'echo'],
            status: 'active',
            createdAt: daysAgo(10),
            updatedAt: daysAgo(10)
        },
        // DOC3: Stress test for Patient3 (Karim) - Diabetic cardiac eval
        {
            _id: IDS.documents.doc3,
            patientId: IDS.profiles.patient3,
            uploadedBy: IDS.profiles.doctor2,
            uploaderType: 'doctor',
            uploaderDoctorId: IDS.profiles.doctor2,
            consultationId: IDS.consultations.cons4,
            documentType: 'medical_report',
            title: 'Cardiac Stress Test Report',
            description: 'Exercise stress test with ECG monitoring for diabetic cardiovascular assessment',
            fileName: 'stress_test_karim_dec2025.pdf',
            fileSize: 892345,
            mimeType: 'application/pdf',
            fileExtension: 'pdf',
            s3Key: `medical-documents/${IDS.profiles.patient3}/reports/stress_test_dec2025.pdf`,
            s3Bucket: 'esante-medical-documents',
            s3Url: `https://esante-medical-documents.s3.amazonaws.com/medical-documents/${IDS.profiles.patient3}/reports/stress_test_dec2025.pdf`,
            documentDate: daysAgo(6),
            uploadDate: daysAgo(5),
            isSharedWithAllDoctors: false,
            sharedWithDoctors: [IDS.profiles.doctor2, IDS.profiles.doctor3],
            tags: ['stress test', 'cardiac', 'diabetes', 'exercise test'],
            status: 'active',
            createdAt: daysAgo(5),
            updatedAt: daysAgo(5)
        },
        // DOC4: Insurance document for Patient2 (Leila) - uploaded by patient
        {
            _id: IDS.documents.doc4,
            patientId: IDS.profiles.patient2,
            uploadedBy: IDS.profiles.patient2,
            uploaderType: 'patient',
            uploaderDoctorId: null,
            consultationId: null,
            documentType: 'insurance',
            title: 'CNAM Insurance Card',
            description: 'National health insurance card - CNAM Tunisia',
            fileName: 'cnam_card_leila.jpg',
            fileSize: 156789,
            mimeType: 'image/jpeg',
            fileExtension: 'jpg',
            s3Key: `medical-documents/${IDS.profiles.patient2}/insurance/cnam_card.jpg`,
            s3Bucket: 'esante-medical-documents',
            s3Url: `https://esante-medical-documents.s3.amazonaws.com/medical-documents/${IDS.profiles.patient2}/insurance/cnam_card.jpg`,
            documentDate: daysAgo(30),
            uploadDate: daysAgo(30),
            isSharedWithAllDoctors: true,
            sharedWithDoctors: [],
            tags: ['insurance', 'cnam', 'card'],
            status: 'active',
            createdAt: daysAgo(30),
            updatedAt: daysAgo(30)
        },
        // DOC5: Previous medical report for Patient4 (Sara) - uploaded by patient
        {
            _id: IDS.documents.doc5,
            patientId: IDS.profiles.patient4,
            uploadedBy: IDS.profiles.patient4,
            uploaderType: 'patient',
            uploaderDoctorId: null,
            consultationId: null,
            documentType: 'medical_report',
            title: 'Previous Allergy Test Results',
            description: 'Allergy panel test from previous clinic visit',
            fileName: 'allergy_test_sara.pdf',
            fileSize: 345678,
            mimeType: 'application/pdf',
            fileExtension: 'pdf',
            s3Key: `medical-documents/${IDS.profiles.patient4}/reports/allergy_test.pdf`,
            s3Bucket: 'esante-medical-documents',
            s3Url: `https://esante-medical-documents.s3.amazonaws.com/medical-documents/${IDS.profiles.patient4}/reports/allergy_test.pdf`,
            documentDate: daysAgo(60),
            uploadDate: daysAgo(45),
            isSharedWithAllDoctors: true,
            sharedWithDoctors: [],
            tags: ['allergy', 'test', 'immunology'],
            status: 'active',
            createdAt: daysAgo(45),
            updatedAt: daysAgo(45)
        }
    ];
};

// ============================================================
// STEP 10: REFERRALS (esante_referrals.referrals)
// ============================================================

const createReferrals = () => {
    const now = new Date();
    
    const daysAgo = (days) => {
        const d = new Date(now);
        d.setDate(d.getDate() - days);
        return d;
    };

    const daysFromNow = (days) => {
        const d = new Date(now);
        d.setDate(d.getDate() + days);
        return d;
    };

    return [
        // REF1: Dr. Ahmed (General) → Dr. Fatma (Cardio) for Patient1 (Mohamed) - COMPLETED
        {
            _id: IDS.referrals.ref1,
            referringDoctorId: IDS.profiles.doctor1,
            targetDoctorId: IDS.profiles.doctor2,
            patientId: IDS.profiles.patient1,
            referralDate: daysAgo(12),
            reason: 'Patient has hypertension with occasional palpitations. Requires cardiology evaluation to rule out hypertensive heart disease.',
            urgency: 'routine',
            specialty: 'Cardiology',
            diagnosis: 'Essential hypertension with suspected cardiac involvement',
            symptoms: ['palpitations', 'occasional dizziness', 'shortness of breath on exertion'],
            relevantHistory: 'Hypertension diagnosed 3 years ago. Currently on Amlodipine 5mg and Lisinopril 10mg.',
            currentMedications: 'Amlodipine 5mg daily, Lisinopril 10mg daily',
            specificConcerns: 'Please evaluate for LVH and diastolic dysfunction. Consider echo if indicated.',
            attachedDocuments: [IDS.documents.doc1],
            includeFullHistory: true,
            appointmentId: IDS.appointments.apt2,
            isAppointmentBooked: true,
            preferredDates: [daysAgo(10), daysAgo(9), daysAgo(8)],
            status: 'completed',
            statusHistory: [
                {
                    status: 'pending',
                    timestamp: daysAgo(12),
                    updatedBy: IDS.profiles.doctor1,
                    notes: 'Referral created'
                },
                {
                    status: 'accepted',
                    timestamp: daysAgo(11),
                    updatedBy: IDS.profiles.doctor2,
                    notes: 'Referral accepted. Will see patient next week.'
                },
                {
                    status: 'scheduled',
                    timestamp: daysAgo(11),
                    updatedBy: IDS.profiles.doctor2,
                    notes: 'Appointment scheduled'
                },
                {
                    status: 'completed',
                    timestamp: daysAgo(10),
                    updatedBy: IDS.profiles.doctor2,
                    notes: 'Consultation completed. Echo shows mild diastolic dysfunction, no LVH.'
                }
            ],
            referralNotes: 'Patient is compliant with medications. Blood pressure moderately controlled.',
            responseNotes: 'Thank you for the referral. Patient evaluated. Echo shows EF 60%, mild diastolic dysfunction. Recommend adding low-dose aspirin and statin for CV protection.',
            feedback: 'Excellent referral with comprehensive documentation. Patient well-prepared.',
            expiryDate: daysFromNow(78), // 90 days from referral date
            createdAt: daysAgo(12),
            updatedAt: daysAgo(10)
        },
        // REF2: Dr. Ahmed (General) → Dr. Yasmine (Endocrinology) for Patient3 (Karim) - SCHEDULED
        {
            _id: IDS.referrals.ref2,
            referringDoctorId: IDS.profiles.doctor1,
            targetDoctorId: IDS.profiles.doctor3,
            patientId: IDS.profiles.patient3,
            referralDate: daysAgo(3),
            reason: 'Diabetic patient with poor glycemic control despite oral medications. Requires endocrinology consult for insulin initiation consideration.',
            urgency: 'routine',
            specialty: 'Endocrinology',
            diagnosis: 'Type 2 Diabetes Mellitus - poorly controlled',
            symptoms: ['polyuria', 'polydipsia', 'fatigue', 'weight loss 5kg in 3 months'],
            relevantHistory: 'T2DM diagnosed 5 years ago. Previously on Metformin alone. Added Glimepiride 6 months ago. HbA1c still above target.',
            currentMedications: 'Metformin 1000mg BID, Glimepiride 4mg daily, Atorvastatin 20mg daily',
            specificConcerns: 'Please advise on insulin initiation vs GLP-1 agonist. Patient concerned about injections.',
            attachedDocuments: [IDS.documents.doc3],
            includeFullHistory: true,
            appointmentId: IDS.appointments.apt6,
            isAppointmentBooked: true,
            preferredDates: [daysFromNow(2), daysFromNow(3), daysFromNow(5)],
            status: 'scheduled',
            statusHistory: [
                {
                    status: 'pending',
                    timestamp: daysAgo(3),
                    updatedBy: IDS.profiles.doctor1,
                    notes: 'Referral created'
                },
                {
                    status: 'accepted',
                    timestamp: daysAgo(2),
                    updatedBy: IDS.profiles.doctor3,
                    notes: 'Referral accepted. Will evaluate for advanced diabetes management.'
                },
                {
                    status: 'scheduled',
                    timestamp: daysAgo(2),
                    updatedBy: IDS.profiles.doctor3,
                    notes: 'Appointment scheduled for comprehensive diabetes evaluation'
                }
            ],
            referralNotes: 'Patient highly motivated to improve control. Occupation: teacher, needs flexible dosing schedule.',
            responseNotes: 'Thank you. Will evaluate for GLP-1 or basal insulin options.',
            expiryDate: daysFromNow(87), // 90 days from referral date
            createdAt: daysAgo(3),
            updatedAt: daysAgo(2)
        },
        // REF3: Dr. Fatma (Cardio) → Dr. Rached (Dermatology) for Patient1 (Mohamed) - PENDING
        {
            _id: IDS.referrals.ref3,
            referringDoctorId: IDS.profiles.doctor2,
            targetDoctorId: IDS.profiles.doctor4,
            patientId: IDS.profiles.patient1,
            referralDate: daysAgo(1),
            reason: 'Patient noticed skin lesion on chest during examination. Appears to be a suspicious nevus requiring dermatological evaluation.',
            urgency: 'urgent',
            specialty: 'Dermatology',
            diagnosis: 'Suspicious pigmented nevus - rule out melanoma',
            symptoms: ['asymmetric mole', 'irregular borders', 'color variation'],
            relevantHistory: 'No personal history of skin cancer. Father had BCC removed at age 70.',
            currentMedications: 'Amlodipine 5mg, Lisinopril 10mg, Aspirin 100mg, Atorvastatin 20mg',
            specificConcerns: 'Lesion approximately 8mm, irregular borders, noted during cardiac exam. Please evaluate urgently.',
            attachedDocuments: [],
            includeFullHistory: false,
            appointmentId: null,
            isAppointmentBooked: false,
            preferredDates: [daysFromNow(3), daysFromNow(5), daysFromNow(7)],
            status: 'pending',
            statusHistory: [
                {
                    status: 'pending',
                    timestamp: daysAgo(1),
                    updatedBy: IDS.profiles.doctor2,
                    notes: 'Urgent referral created - suspicious skin lesion found during cardiology exam'
                }
            ],
            referralNotes: 'Incidental finding during cardiac examination. Patient advised to seek dermatology evaluation promptly.',
            responseNotes: null,
            expiryDate: daysFromNow(89), // 90 days from referral date
            createdAt: daysAgo(1),
            updatedAt: daysAgo(1)
        },
        // REF4: Dr. Ahmed (General) → Dr. Fatma (Cardio) for Patient2 (Leila) - CANCELLED
        {
            _id: IDS.referrals.ref4,
            referringDoctorId: IDS.profiles.doctor1,
            targetDoctorId: IDS.profiles.doctor2,
            patientId: IDS.profiles.patient2,
            referralDate: daysAgo(20),
            reason: 'Patient reported occasional chest discomfort. Requested cardiology evaluation for peace of mind.',
            urgency: 'routine',
            specialty: 'Cardiology',
            diagnosis: 'Atypical chest pain - anxiety likely',
            symptoms: ['occasional chest tightness', 'anxiety', 'normal ECG'],
            relevantHistory: 'No cardiac risk factors. Normal BMI. Non-smoker. History of anxiety disorder.',
            currentMedications: 'None regular',
            specificConcerns: 'Patient very anxious about heart disease. Consider reassurance with echo if clinically indicated.',
            attachedDocuments: [],
            includeFullHistory: true,
            appointmentId: null,
            isAppointmentBooked: false,
            preferredDates: [],
            status: 'cancelled',
            statusHistory: [
                {
                    status: 'pending',
                    timestamp: daysAgo(20),
                    updatedBy: IDS.profiles.doctor1,
                    notes: 'Referral created at patient request'
                },
                {
                    status: 'cancelled',
                    timestamp: daysAgo(18),
                    updatedBy: IDS.profiles.patient2,
                    notes: 'Patient cancelled - symptoms resolved, feeling much better'
                }
            ],
            referralNotes: 'Low clinical suspicion for cardiac disease. Referral mainly for patient reassurance.',
            responseNotes: null,
            cancellationReason: 'Patient symptoms resolved. Decided cardiology evaluation not necessary at this time.',
            expiryDate: daysFromNow(70), // Would have been 90 days from referral
            createdAt: daysAgo(20),
            updatedAt: daysAgo(18)
        }
    ];
};

// ============================================================
// MAIN SEED FUNCTION - STEP 4: Documents & Referrals
// ============================================================

const seedStep4 = async () => {
    console.log('🌱 STEP 4: Creating Medical Documents and Referrals...\n');

    const medicalConn = createConnection(DB_NAMES.MEDICAL);
    const referralConn = createConnection(DB_NAMES.REFERRAL);

    await Promise.all([
        new Promise(resolve => medicalConn.on('connected', resolve)),
        new Promise(resolve => referralConn.on('connected', resolve))
    ]);
    console.log('✅ Connected to databases\n');

    try {
        // Create Medical Documents (add to existing medical DB)
        console.log('📄 Creating medical documents...');
        const documents = createMedicalDocuments();
        
        // Drop only medicaldocuments collection, keep consultations and prescriptions
        await medicalConn.collection('medicaldocuments').drop().catch(() => {});
        await medicalConn.collection('medicaldocuments').insertMany(documents);
        console.log(`✅ Created ${documents.length} medical documents`);

        // Create indexes for documents
        await medicalConn.collection('medicaldocuments').createIndex({ patientId: 1, uploadDate: -1 });
        await medicalConn.collection('medicaldocuments').createIndex({ s3Key: 1 }, { unique: true });
        await medicalConn.collection('medicaldocuments').createIndex({ consultationId: 1 });

        // Create Referrals
        console.log('\n🔄 Creating referrals...');
        await referralConn.dropDatabase();
        const referrals = createReferrals();
        await referralConn.collection('referrals').insertMany(referrals);
        console.log(`✅ Created ${referrals.length} referrals`);

        // Create indexes for referrals
        await referralConn.collection('referrals').createIndex({ referringDoctorId: 1, referralDate: -1 });
        await referralConn.collection('referrals').createIndex({ targetDoctorId: 1, status: 1 });
        await referralConn.collection('referrals').createIndex({ patientId: 1, referralDate: -1 });
        console.log('✅ Created indexes\n');

        // Print summary
        console.log('═══════════════════════════════════════════════════════════');
        console.log('📋 STEP 4 COMPLETE - Documents & Referrals Created');
        console.log('═══════════════════════════════════════════════════════════\n');

        console.log('📄 MEDICAL DOCUMENTS:');
        console.log('─────────────────────────────────────────');
        documents.forEach((doc, i) => {
            console.log(`   ${i + 1}. ${doc.title}`);
            console.log(`      Type: ${doc.documentType} | Patient: ${doc.patientId.toString().slice(-6)}`);
            console.log(`      Uploader: ${doc.uploaderType} | File: ${doc.fileName}`);
        });

        console.log('\n🔄 REFERRALS:');
        console.log('─────────────────────────────────────────');
        referrals.forEach((ref, i) => {
            console.log(`   ${i + 1}. ${ref.specialty} Referral - ${ref.status.toUpperCase()}`);
            console.log(`      From: Doctor ${ref.referringDoctorId.toString().slice(-6)} → To: Doctor ${ref.targetDoctorId.toString().slice(-6)}`);
            console.log(`      Patient: ${ref.patientId.toString().slice(-6)} | Urgency: ${ref.urgency}`);
            console.log(`      Reason: ${ref.reason.substring(0, 60)}...`);
        });

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('📌 REFERRAL STATUS SUMMARY:');
        console.log('═══════════════════════════════════════════════════════════');
        console.log(`   ref1: Dr. Ahmed → Dr. Fatma (Cardio) for Mohamed - COMPLETED ✅`);
        console.log(`   ref2: Dr. Ahmed → Dr. Yasmine (Endo) for Karim - SCHEDULED 📅`);
        console.log(`   ref3: Dr. Fatma → Dr. Rached (Derm) for Mohamed - PENDING ⏳`);
        console.log(`   ref4: Dr. Ahmed → Dr. Fatma (Cardio) for Leila - CANCELLED ❌`);

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('👉 Type "continue" to proceed to STEP 5: Conversations & Messages');
        console.log('═══════════════════════════════════════════════════════════\n');

    } catch (error) {
        console.error('❌ Step 4 Failed:', error);
    } finally {
        await medicalConn.close();
        await referralConn.close();
    }
};

// ============================================================
// STEP 11: CONVERSATIONS (esante_messaging.conversations)
// ============================================================

const createConversations = () => {
    const now = new Date();
    
    const daysAgo = (days) => {
        const d = new Date(now);
        d.setDate(d.getDate() - days);
        return d;
    };

    // Helper to sort participants (required by schema)
    const sortParticipants = (p1, p2) => {
        return [p1, p2].sort((a, b) => a.toString().localeCompare(b.toString()));
    };

    return [
        // CONV1: Patient1 (Mohamed) ↔ Doctor1 (Ahmed) - Active, recent messages
        {
            _id: IDS.conversations.conv1,
            participants: sortParticipants(IDS.profiles.patient1, IDS.profiles.doctor1),
            participantTypes: [
                { userId: IDS.profiles.patient1, userType: 'patient' },
                { userId: IDS.profiles.doctor1, userType: 'doctor' }
            ],
            conversationType: 'patient_doctor',
            lastMessage: {
                content: 'Thank you doctor, I will follow your advice.',
                senderId: IDS.profiles.patient1,
                timestamp: daysAgo(1),
                isRead: true
            },
            unreadCount: new Map([
                [IDS.profiles.patient1.toString(), 0],
                [IDS.profiles.doctor1.toString(), 0]
            ]),
            isActive: true,
            isArchived: false,
            createdAt: daysAgo(20),
            updatedAt: daysAgo(1)
        },
        // CONV2: Patient1 (Mohamed) ↔ Doctor2 (Fatma) - Active, unread by patient
        {
            _id: IDS.conversations.conv2,
            participants: sortParticipants(IDS.profiles.patient1, IDS.profiles.doctor2),
            participantTypes: [
                { userId: IDS.profiles.patient1, userType: 'patient' },
                { userId: IDS.profiles.doctor2, userType: 'doctor' }
            ],
            conversationType: 'patient_doctor',
            lastMessage: {
                content: 'Please remember to take the aspirin with food to avoid stomach upset.',
                senderId: IDS.profiles.doctor2,
                timestamp: daysAgo(0), // Today
                isRead: false
            },
            unreadCount: new Map([
                [IDS.profiles.patient1.toString(), 1],
                [IDS.profiles.doctor2.toString(), 0]
            ]),
            isActive: true,
            isArchived: false,
            createdAt: daysAgo(12),
            updatedAt: daysAgo(0)
        },
        // CONV3: Patient2 (Leila) ↔ Doctor1 (Ahmed) - Active, minimal messages
        {
            _id: IDS.conversations.conv3,
            participants: sortParticipants(IDS.profiles.patient2, IDS.profiles.doctor1),
            participantTypes: [
                { userId: IDS.profiles.patient2, userType: 'patient' },
                { userId: IDS.profiles.doctor1, userType: 'doctor' }
            ],
            conversationType: 'patient_doctor',
            lastMessage: {
                content: 'Your lab results came back normal. Keep up the healthy lifestyle!',
                senderId: IDS.profiles.doctor1,
                timestamp: daysAgo(5),
                isRead: true
            },
            unreadCount: new Map([
                [IDS.profiles.patient2.toString(), 0],
                [IDS.profiles.doctor1.toString(), 0]
            ]),
            isActive: true,
            isArchived: false,
            createdAt: daysAgo(10),
            updatedAt: daysAgo(5)
        },
        // CONV4: Patient3 (Karim) ↔ Doctor2 (Fatma) - Active
        {
            _id: IDS.conversations.conv4,
            participants: sortParticipants(IDS.profiles.patient3, IDS.profiles.doctor2),
            participantTypes: [
                { userId: IDS.profiles.patient3, userType: 'patient' },
                { userId: IDS.profiles.doctor2, userType: 'doctor' }
            ],
            conversationType: 'patient_doctor',
            lastMessage: {
                content: 'I have scheduled a follow-up with Dr. Yasmine for your diabetes management.',
                senderId: IDS.profiles.doctor2,
                timestamp: daysAgo(3),
                isRead: true
            },
            unreadCount: new Map([
                [IDS.profiles.patient3.toString(), 0],
                [IDS.profiles.doctor2.toString(), 0]
            ]),
            isActive: true,
            isArchived: false,
            createdAt: daysAgo(7),
            updatedAt: daysAgo(3)
        },
        // CONV5: Patient4 (Sara) ↔ Doctor1 (Ahmed) - Active, recent flu consultation
        {
            _id: IDS.conversations.conv5,
            participants: sortParticipants(IDS.profiles.patient4, IDS.profiles.doctor1),
            participantTypes: [
                { userId: IDS.profiles.patient4, userType: 'patient' },
                { userId: IDS.profiles.doctor1, userType: 'doctor' }
            ],
            conversationType: 'patient_doctor',
            lastMessage: {
                content: 'I am feeling much better now, the fever is gone. Thank you!',
                senderId: IDS.profiles.patient4,
                timestamp: daysAgo(1),
                isRead: false
            },
            unreadCount: new Map([
                [IDS.profiles.patient4.toString(), 0],
                [IDS.profiles.doctor1.toString(), 1]
            ]),
            isActive: true,
            isArchived: false,
            createdAt: daysAgo(4),
            updatedAt: daysAgo(1)
        },
        // CONV6: Doctor1 (Ahmed) ↔ Doctor2 (Fatma) - Doctor-to-doctor about Mohamed
        {
            _id: IDS.conversations.conv6,
            participants: sortParticipants(IDS.profiles.doctor1, IDS.profiles.doctor2),
            participantTypes: [
                { userId: IDS.profiles.doctor1, userType: 'doctor' },
                { userId: IDS.profiles.doctor2, userType: 'doctor' }
            ],
            conversationType: 'doctor_doctor',
            lastMessage: {
                content: 'Thank you for the referral. I have completed the cardiac evaluation. Report sent.',
                senderId: IDS.profiles.doctor2,
                timestamp: daysAgo(9),
                isRead: true
            },
            unreadCount: new Map([
                [IDS.profiles.doctor1.toString(), 0],
                [IDS.profiles.doctor2.toString(), 0]
            ]),
            isActive: true,
            isArchived: false,
            createdAt: daysAgo(12),
            updatedAt: daysAgo(9)
        }
    ];
};

// ============================================================
// STEP 12: MESSAGES (esante_messaging.messages)
// ============================================================

const createMessages = () => {
    const now = new Date();
    
    const daysAgo = (days, hours = 0, minutes = 0) => {
        const d = new Date(now);
        d.setDate(d.getDate() - days);
        d.setHours(d.getHours() - hours, minutes, 0, 0);
        return d;
    };

    return [
        // ===== CONV1: Patient1 (Mohamed) ↔ Doctor1 (Ahmed) =====
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv1,
            senderId: IDS.profiles.patient1,
            senderType: 'patient',
            receiverId: IDS.profiles.doctor1,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Hello Dr. Ahmed, I have been experiencing some dizziness in the mornings. Is this normal with my blood pressure medication?',
            isRead: true,
            readAt: daysAgo(14, 2),
            isDelivered: true,
            deliveredAt: daysAgo(15, 0),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(15),
            updatedAt: daysAgo(15)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv1,
            senderId: IDS.profiles.doctor1,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient1,
            receiverType: 'patient',
            messageType: 'text',
            content: 'Hello Mohamed, yes this can happen when starting blood pressure medication. Try standing up slowly from lying or sitting position. If the dizziness persists or worsens, please come see me.',
            isRead: true,
            readAt: daysAgo(14, 1),
            isDelivered: true,
            deliveredAt: daysAgo(14, 3),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(14, 4),
            updatedAt: daysAgo(14, 4)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv1,
            senderId: IDS.profiles.patient1,
            senderType: 'patient',
            receiverId: IDS.profiles.doctor1,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Thank you doctor. Also, I wanted to ask about the referral to Dr. Fatma. When should I expect the appointment?',
            isRead: true,
            readAt: daysAgo(13, 5),
            isDelivered: true,
            deliveredAt: daysAgo(13, 8),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(14),
            updatedAt: daysAgo(14)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv1,
            senderId: IDS.profiles.doctor1,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient1,
            receiverType: 'patient',
            messageType: 'text',
            content: 'I have sent the referral to Dr. Fatma Ben Said. She specializes in cardiology. You should receive a notification when she accepts and schedules your appointment.',
            isRead: true,
            readAt: daysAgo(13, 2),
            isDelivered: true,
            deliveredAt: daysAgo(13, 4),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(13, 5),
            updatedAt: daysAgo(13, 5)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv1,
            senderId: IDS.profiles.patient1,
            senderType: 'patient',
            receiverId: IDS.profiles.doctor1,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Thank you doctor, I will follow your advice.',
            isRead: true,
            readAt: daysAgo(1, 2),
            isDelivered: true,
            deliveredAt: daysAgo(1, 3),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(1, 4),
            updatedAt: daysAgo(1, 4)
        },

        // ===== CONV2: Patient1 (Mohamed) ↔ Doctor2 (Fatma) =====
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv2,
            senderId: IDS.profiles.doctor2,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient1,
            receiverType: 'patient',
            messageType: 'text',
            content: 'Hello Mr. Belhaj, I am Dr. Fatma Ben Said. I have received your referral from Dr. Ahmed. I have reviewed your case and scheduled you for a cardiac evaluation.',
            isRead: true,
            readAt: daysAgo(10, 2),
            isDelivered: true,
            deliveredAt: daysAgo(11),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(11, 2),
            updatedAt: daysAgo(11, 2)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv2,
            senderId: IDS.profiles.patient1,
            senderType: 'patient',
            receiverId: IDS.profiles.doctor2,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Thank you Dr. Fatma. I saw the appointment notification. Is there anything I need to prepare before the visit?',
            isRead: true,
            readAt: daysAgo(10),
            isDelivered: true,
            deliveredAt: daysAgo(10, 1),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(10, 2),
            updatedAt: daysAgo(10, 2)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv2,
            senderId: IDS.profiles.doctor2,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient1,
            receiverType: 'patient',
            messageType: 'text',
            content: 'Please bring your previous ECG reports if you have any, and a list of all medications you are currently taking. No need to fast.',
            isRead: true,
            readAt: daysAgo(9, 8),
            isDelivered: true,
            deliveredAt: daysAgo(9, 10),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(10),
            updatedAt: daysAgo(10)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv2,
            senderId: IDS.profiles.doctor2,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient1,
            receiverType: 'patient',
            messageType: 'text',
            content: 'Please remember to take the aspirin with food to avoid stomach upset.',
            isRead: false,
            readAt: null,
            isDelivered: true,
            deliveredAt: daysAgo(0, 1),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(0, 2),
            updatedAt: daysAgo(0, 2)
        },

        // ===== CONV3: Patient2 (Leila) ↔ Doctor1 (Ahmed) =====
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv3,
            senderId: IDS.profiles.patient2,
            senderType: 'patient',
            receiverId: IDS.profiles.doctor1,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Dr. Ahmed, I just had my annual checkup. When will the lab results be ready?',
            isRead: true,
            readAt: daysAgo(7),
            isDelivered: true,
            deliveredAt: daysAgo(8),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(8, 2),
            updatedAt: daysAgo(8, 2)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv3,
            senderId: IDS.profiles.doctor1,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient2,
            receiverType: 'patient',
            messageType: 'text',
            content: 'Hello Leila, the lab usually takes 2-3 days. I will message you as soon as I receive them.',
            isRead: true,
            readAt: daysAgo(7, 5),
            isDelivered: true,
            deliveredAt: daysAgo(7, 8),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(7, 10),
            updatedAt: daysAgo(7, 10)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv3,
            senderId: IDS.profiles.doctor1,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient2,
            receiverType: 'patient',
            messageType: 'text',
            content: 'Your lab results came back normal. Keep up the healthy lifestyle!',
            isRead: true,
            readAt: daysAgo(4, 10),
            isDelivered: true,
            deliveredAt: daysAgo(5),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(5, 2),
            updatedAt: daysAgo(5, 2)
        },

        // ===== CONV4: Patient3 (Karim) ↔ Doctor2 (Fatma) =====
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv4,
            senderId: IDS.profiles.patient3,
            senderType: 'patient',
            receiverId: IDS.profiles.doctor2,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Dr. Fatma, thank you for the cardiac evaluation. The stress test results were reassuring.',
            isRead: true,
            readAt: daysAgo(4),
            isDelivered: true,
            deliveredAt: daysAgo(4, 2),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(4, 4),
            updatedAt: daysAgo(4, 4)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv4,
            senderId: IDS.profiles.doctor2,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient3,
            receiverType: 'patient',
            messageType: 'text',
            content: 'I have scheduled a follow-up with Dr. Yasmine for your diabetes management.',
            isRead: true,
            readAt: daysAgo(2, 8),
            isDelivered: true,
            deliveredAt: daysAgo(3),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(3, 2),
            updatedAt: daysAgo(3, 2)
        },

        // ===== CONV5: Patient4 (Sara) ↔ Doctor1 (Ahmed) =====
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv5,
            senderId: IDS.profiles.patient4,
            senderType: 'patient',
            receiverId: IDS.profiles.doctor1,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Dr. Ahmed, I started the Tamiflu as prescribed. How long until I should feel better?',
            isRead: true,
            readAt: daysAgo(2, 10),
            isDelivered: true,
            deliveredAt: daysAgo(3),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(3, 2),
            updatedAt: daysAgo(3, 2)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv5,
            senderId: IDS.profiles.doctor1,
            senderType: 'doctor',
            receiverId: IDS.profiles.patient4,
            receiverType: 'patient',
            messageType: 'text',
            content: 'You should notice improvement within 24-48 hours. Continue the full 5-day course even if you feel better. Stay hydrated and rest.',
            isRead: true,
            readAt: daysAgo(2, 6),
            isDelivered: true,
            deliveredAt: daysAgo(2, 8),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(2, 10),
            updatedAt: daysAgo(2, 10)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv5,
            senderId: IDS.profiles.patient4,
            senderType: 'patient',
            receiverId: IDS.profiles.doctor1,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'I am feeling much better now, the fever is gone. Thank you!',
            isRead: false,
            readAt: null,
            isDelivered: true,
            deliveredAt: daysAgo(1, 2),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(1, 4),
            updatedAt: daysAgo(1, 4)
        },

        // ===== CONV6: Doctor1 (Ahmed) ↔ Doctor2 (Fatma) - Doctor to Doctor =====
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv6,
            senderId: IDS.profiles.doctor1,
            senderType: 'doctor',
            receiverId: IDS.profiles.doctor2,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Dr. Fatma, I am sending you a referral for Mohamed Belhaj. He has hypertension with occasional palpitations. Would appreciate your cardiac evaluation.',
            isRead: true,
            readAt: daysAgo(11, 5),
            isDelivered: true,
            deliveredAt: daysAgo(12),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(12, 2),
            updatedAt: daysAgo(12, 2)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv6,
            senderId: IDS.profiles.doctor2,
            senderType: 'doctor',
            receiverId: IDS.profiles.doctor1,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Thank you Dr. Ahmed. I have received the referral and will schedule him for next week. I will keep you updated on the findings.',
            isRead: true,
            readAt: daysAgo(11, 2),
            isDelivered: true,
            deliveredAt: daysAgo(11, 4),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(11, 6),
            updatedAt: daysAgo(11, 6)
        },
        {
            _id: new ObjectId(),
            conversationId: IDS.conversations.conv6,
            senderId: IDS.profiles.doctor2,
            senderType: 'doctor',
            receiverId: IDS.profiles.doctor1,
            receiverType: 'doctor',
            messageType: 'text',
            content: 'Thank you for the referral. I have completed the cardiac evaluation. Report sent.',
            isRead: true,
            readAt: daysAgo(8, 10),
            isDelivered: true,
            deliveredAt: daysAgo(9),
            isEdited: false,
            isDeleted: false,
            metadata: {},
            createdAt: daysAgo(9, 2),
            updatedAt: daysAgo(9, 2)
        }
    ];
};

// ============================================================
// MAIN SEED FUNCTION - STEP 5: Conversations & Messages
// ============================================================

const seedStep5 = async () => {
    console.log('🌱 STEP 5: Creating Conversations and Messages...\n');

    const messagingConn = createConnection(DB_NAMES.MESSAGING);

    await new Promise(resolve => messagingConn.on('connected', resolve));
    console.log('✅ Connected to messaging database\n');

    try {
        // Clear messaging database
        console.log('🧹 Clearing existing messaging data...');
        await messagingConn.dropDatabase();

        // Create Conversations
        console.log('💬 Creating conversations...');
        const conversations = createConversations();
        
        // Convert Map to Object for MongoDB insertion
        const conversationsForDb = conversations.map(conv => ({
            ...conv,
            unreadCount: Object.fromEntries(conv.unreadCount)
        }));
        
        await messagingConn.collection('conversations').insertMany(conversationsForDb);
        console.log(`✅ Created ${conversations.length} conversations`);

        // Create Messages
        console.log('📨 Creating messages...');
        const messages = createMessages();
        await messagingConn.collection('messages').insertMany(messages);
        console.log(`✅ Created ${messages.length} messages`);

        // Create indexes (participants index is NOT unique since same user can be in multiple conversations)
        await messagingConn.collection('conversations').createIndex({ participants: 1 });
        await messagingConn.collection('conversations').createIndex({ participants: 1, 'lastMessage.timestamp': -1 });
        await messagingConn.collection('messages').createIndex({ conversationId: 1, createdAt: -1 });
        await messagingConn.collection('messages').createIndex({ senderId: 1, createdAt: -1 });
        console.log('✅ Created indexes\n');

        // Print summary
        console.log('═══════════════════════════════════════════════════════════');
        console.log('📋 STEP 5 COMPLETE - Conversations & Messages Created');
        console.log('═══════════════════════════════════════════════════════════\n');

        console.log('💬 CONVERSATIONS:');
        console.log('─────────────────────────────────────────');
        const convDescriptions = [
            { id: 'conv1', desc: 'Patient1 (Mohamed) ↔ Doctor1 (Ahmed)', type: 'patient_doctor', msgs: 5 },
            { id: 'conv2', desc: 'Patient1 (Mohamed) ↔ Doctor2 (Fatma)', type: 'patient_doctor', msgs: 4 },
            { id: 'conv3', desc: 'Patient2 (Leila) ↔ Doctor1 (Ahmed)', type: 'patient_doctor', msgs: 3 },
            { id: 'conv4', desc: 'Patient3 (Karim) ↔ Doctor2 (Fatma)', type: 'patient_doctor', msgs: 2 },
            { id: 'conv5', desc: 'Patient4 (Sara) ↔ Doctor1 (Ahmed)', type: 'patient_doctor', msgs: 3 },
            { id: 'conv6', desc: 'Doctor1 (Ahmed) ↔ Doctor2 (Fatma)', type: 'doctor_doctor', msgs: 3 }
        ];
        
        convDescriptions.forEach((c, i) => {
            console.log(`   ${i + 1}. ${c.desc}`);
            console.log(`      Type: ${c.type} | Messages: ${c.msgs}`);
        });

        console.log('\n📊 MESSAGE SUMMARY:');
        console.log('─────────────────────────────────────────');
        console.log(`   Total Messages: ${messages.length}`);
        console.log(`   Read Messages: ${messages.filter(m => m.isRead).length}`);
        console.log(`   Unread Messages: ${messages.filter(m => !m.isRead).length}`);

        console.log('\n📌 UNREAD MESSAGES:');
        console.log('─────────────────────────────────────────');
        console.log(`   - conv2: 1 unread message for Patient1 (Mohamed) from Dr. Fatma`);
        console.log(`   - conv5: 1 unread message for Doctor1 (Ahmed) from Sara`);

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('👉 Type "continue" to proceed to STEP 6: Notifications');
        console.log('═══════════════════════════════════════════════════════════\n');

    } catch (error) {
        console.error('❌ Step 5 Failed:', error);
    } finally {
        await messagingConn.close();
    }
};

// ============================================================
// STEP 13: NOTIFICATIONS (esante_notifications.notifications)
// ============================================================

const createNotifications = () => {
    const now = new Date();
    
    const daysAgo = (days, hours = 0) => {
        const d = new Date(now);
        d.setDate(d.getDate() - days);
        d.setHours(d.getHours() - hours);
        return d;
    };

    const daysFromNow = (days, hours = 0) => {
        const d = new Date(now);
        d.setDate(d.getDate() + days);
        d.setHours(d.getHours() + hours);
        return d;
    };

    return [
        // ===== PATIENT1 (Mohamed) NOTIFICATIONS =====
        // Appointment confirmed with Dr. Ahmed
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient1,
            userType: 'patient',
            title: 'Appointment Confirmed',
            body: 'Your appointment with Dr. Ahmed Ben Ali on December 17, 2025 at 09:00 has been confirmed.',
            type: 'appointment_confirmed',
            relatedResource: {
                resourceType: 'appointment',
                resourceId: IDS.appointments.apt1
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(16) },
                email: { enabled: true, sent: true, sentAt: daysAgo(16) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(16, 2),
            priority: 'medium',
            actionUrl: '/appointments/' + IDS.appointments.apt1.toString(),
            actionData: { appointmentId: IDS.appointments.apt1 },
            createdAt: daysAgo(16),
            updatedAt: daysAgo(16)
        },
        // Referral to cardiology
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient1,
            userType: 'patient',
            title: 'New Referral Created',
            body: 'Dr. Ahmed Ben Ali has referred you to Dr. Fatma Ben Said (Cardiology) for cardiac evaluation.',
            type: 'referral_received',
            relatedResource: {
                resourceType: 'referral',
                resourceId: IDS.referrals.ref1
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(12) },
                email: { enabled: true, sent: true, sentAt: daysAgo(12) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(12, 1),
            priority: 'medium',
            actionUrl: '/referrals/' + IDS.referrals.ref1.toString(),
            actionData: { referralId: IDS.referrals.ref1 },
            createdAt: daysAgo(12),
            updatedAt: daysAgo(12)
        },
        // Referral scheduled
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient1,
            userType: 'patient',
            title: 'Referral Appointment Scheduled',
            body: 'Your referral appointment with Dr. Fatma Ben Said has been scheduled for December 22, 2025 at 14:00.',
            type: 'referral_scheduled',
            relatedResource: {
                resourceType: 'appointment',
                resourceId: IDS.appointments.apt2
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(11) },
                email: { enabled: true, sent: true, sentAt: daysAgo(11) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(11, 1),
            priority: 'medium',
            actionUrl: '/appointments/' + IDS.appointments.apt2.toString(),
            actionData: { appointmentId: IDS.appointments.apt2 },
            createdAt: daysAgo(11),
            updatedAt: daysAgo(11)
        },
        // Prescription created after cardio consultation
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient1,
            userType: 'patient',
            title: 'New Prescription Available',
            body: 'Dr. Fatma Ben Said has created a new prescription for you. Please review the medications and instructions.',
            type: 'prescription_created',
            relatedResource: {
                resourceType: 'prescription',
                resourceId: IDS.prescriptions.presc2
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(10) },
                email: { enabled: true, sent: true, sentAt: daysAgo(10) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(10, 1),
            priority: 'high',
            actionUrl: '/prescriptions/' + IDS.prescriptions.presc2.toString(),
            actionData: { prescriptionId: IDS.prescriptions.presc2 },
            createdAt: daysAgo(10),
            updatedAt: daysAgo(10)
        },
        // New message notification (unread)
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient1,
            userType: 'patient',
            title: 'New Message from Dr. Fatma',
            body: 'Dr. Fatma Ben Said sent you a message about your medication.',
            type: 'new_message',
            relatedResource: {
                resourceType: 'message',
                resourceId: IDS.conversations.conv2
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(0, 2) },
                email: { enabled: false, sent: false },
                inApp: { enabled: true, delivered: true }
            },
            isRead: false,
            readAt: null,
            priority: 'medium',
            actionUrl: '/messages/' + IDS.conversations.conv2.toString(),
            actionData: { conversationId: IDS.conversations.conv2 },
            createdAt: daysAgo(0, 2),
            updatedAt: daysAgo(0, 2)
        },

        // ===== PATIENT2 (Leila) NOTIFICATIONS =====
        // Appointment confirmed
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient2,
            userType: 'patient',
            title: 'Appointment Confirmed',
            body: 'Your appointment with Dr. Ahmed Ben Ali on December 24, 2025 at 11:00 has been confirmed.',
            type: 'appointment_confirmed',
            relatedResource: {
                resourceType: 'appointment',
                resourceId: IDS.appointments.apt3
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(10) },
                email: { enabled: true, sent: true, sentAt: daysAgo(10) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(10, 1),
            priority: 'medium',
            actionUrl: '/appointments/' + IDS.appointments.apt3.toString(),
            actionData: { appointmentId: IDS.appointments.apt3 },
            createdAt: daysAgo(10),
            updatedAt: daysAgo(10)
        },
        // Lab results uploaded
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient2,
            userType: 'patient',
            title: 'Lab Results Available',
            body: 'Your lab results from the annual checkup are now available. All results are normal.',
            type: 'document_uploaded',
            relatedResource: {
                resourceType: 'document',
                resourceId: IDS.documents.doc4
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(5) },
                email: { enabled: true, sent: true, sentAt: daysAgo(5) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(5, 2),
            priority: 'medium',
            actionUrl: '/documents',
            actionData: {},
            createdAt: daysAgo(5),
            updatedAt: daysAgo(5)
        },

        // ===== PATIENT3 (Karim) NOTIFICATIONS =====
        // Upcoming appointment reminder (for tomorrow)
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient3,
            userType: 'patient',
            title: 'Appointment Reminder',
            body: 'Reminder: You have an appointment with Dr. Yasmine Trabelsi tomorrow at 10:00.',
            type: 'appointment_reminder',
            relatedResource: {
                resourceType: 'appointment',
                resourceId: IDS.appointments.apt6
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(0, 1) },
                email: { enabled: true, sent: true, sentAt: daysAgo(0, 1) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: false,
            readAt: null,
            priority: 'high',
            actionUrl: '/appointments/' + IDS.appointments.apt6.toString(),
            actionData: { appointmentId: IDS.appointments.apt6 },
            scheduledFor: daysFromNow(1),
            createdAt: daysAgo(0, 1),
            updatedAt: daysAgo(0, 1)
        },
        // Referral received
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient3,
            userType: 'patient',
            title: 'New Referral to Endocrinology',
            body: 'Dr. Ahmed Ben Ali has referred you to Dr. Yasmine Trabelsi for advanced diabetes management.',
            type: 'referral_received',
            relatedResource: {
                resourceType: 'referral',
                resourceId: IDS.referrals.ref2
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(3) },
                email: { enabled: true, sent: true, sentAt: daysAgo(3) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(3, 1),
            priority: 'medium',
            actionUrl: '/referrals/' + IDS.referrals.ref2.toString(),
            actionData: { referralId: IDS.referrals.ref2 },
            createdAt: daysAgo(3),
            updatedAt: daysAgo(3)
        },

        // ===== PATIENT4 (Sara) NOTIFICATIONS =====
        // Prescription created for flu
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient4,
            userType: 'patient',
            title: 'New Prescription for Flu Treatment',
            body: 'Dr. Ahmed Ben Ali has prescribed Tamiflu and supportive medications for your flu. Start treatment immediately.',
            type: 'prescription_created',
            relatedResource: {
                resourceType: 'prescription',
                resourceId: IDS.prescriptions.presc4
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(3) },
                email: { enabled: true, sent: true, sentAt: daysAgo(3) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(3, 1),
            priority: 'high',
            actionUrl: '/prescriptions/' + IDS.prescriptions.presc4.toString(),
            actionData: { prescriptionId: IDS.prescriptions.presc4 },
            createdAt: daysAgo(3),
            updatedAt: daysAgo(3)
        },

        // ===== DOCTOR1 (Ahmed) NOTIFICATIONS =====
        // New message from patient (unread)
        {
            _id: new ObjectId(),
            userId: IDS.profiles.doctor1,
            userType: 'doctor',
            title: 'New Message from Sara Mejri',
            body: 'Sara Mejri sent you a message about her flu recovery.',
            type: 'new_message',
            relatedResource: {
                resourceType: 'message',
                resourceId: IDS.conversations.conv5
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(1, 4) },
                email: { enabled: false, sent: false },
                inApp: { enabled: true, delivered: true }
            },
            isRead: false,
            readAt: null,
            priority: 'medium',
            actionUrl: '/messages/' + IDS.conversations.conv5.toString(),
            actionData: { conversationId: IDS.conversations.conv5 },
            createdAt: daysAgo(1, 4),
            updatedAt: daysAgo(1, 4)
        },
        // Referral completed notification
        {
            _id: new ObjectId(),
            userId: IDS.profiles.doctor1,
            userType: 'doctor',
            title: 'Referral Completed',
            body: 'Dr. Fatma Ben Said has completed the cardiac evaluation for Mohamed Belhaj. Report available.',
            type: 'consultation_created',
            relatedResource: {
                resourceType: 'consultation',
                resourceId: IDS.consultations.cons2
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(10) },
                email: { enabled: true, sent: true, sentAt: daysAgo(10) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(9, 5),
            priority: 'medium',
            actionUrl: '/referrals/' + IDS.referrals.ref1.toString(),
            actionData: { referralId: IDS.referrals.ref1 },
            createdAt: daysAgo(10),
            updatedAt: daysAgo(10)
        },

        // ===== DOCTOR2 (Fatma) NOTIFICATIONS =====
        // New referral received
        {
            _id: new ObjectId(),
            userId: IDS.profiles.doctor2,
            userType: 'doctor',
            title: 'New Referral Received',
            body: 'Dr. Ahmed Ben Ali has referred Mohamed Belhaj to you for cardiac evaluation.',
            type: 'referral_received',
            relatedResource: {
                resourceType: 'referral',
                resourceId: IDS.referrals.ref1
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(12) },
                email: { enabled: true, sent: true, sentAt: daysAgo(12) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(12, 2),
            priority: 'high',
            actionUrl: '/referrals/' + IDS.referrals.ref1.toString(),
            actionData: { referralId: IDS.referrals.ref1 },
            createdAt: daysAgo(12),
            updatedAt: daysAgo(12)
        },
        // Urgent referral from dermatology (unread)
        {
            _id: new ObjectId(),
            userId: IDS.profiles.doctor4,
            userType: 'doctor',
            title: 'URGENT Referral Received',
            body: 'Dr. Fatma Ben Said has sent an urgent referral for Mohamed Belhaj - suspicious skin lesion requiring evaluation.',
            type: 'referral_received',
            relatedResource: {
                resourceType: 'referral',
                resourceId: IDS.referrals.ref3
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(1) },
                email: { enabled: true, sent: true, sentAt: daysAgo(1) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: false,
            readAt: null,
            priority: 'urgent',
            actionUrl: '/referrals/' + IDS.referrals.ref3.toString(),
            actionData: { referralId: IDS.referrals.ref3 },
            createdAt: daysAgo(1),
            updatedAt: daysAgo(1)
        },

        // ===== DOCTOR3 (Yasmine) NOTIFICATIONS =====
        // New referral received
        {
            _id: new ObjectId(),
            userId: IDS.profiles.doctor3,
            userType: 'doctor',
            title: 'New Referral Received',
            body: 'Dr. Ahmed Ben Ali has referred Karim Chaabane to you for advanced diabetes management.',
            type: 'referral_received',
            relatedResource: {
                resourceType: 'referral',
                resourceId: IDS.referrals.ref2
            },
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(3) },
                email: { enabled: true, sent: true, sentAt: daysAgo(3) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: true,
            readAt: daysAgo(3, 1),
            priority: 'medium',
            actionUrl: '/referrals/' + IDS.referrals.ref2.toString(),
            actionData: { referralId: IDS.referrals.ref2 },
            createdAt: daysAgo(3),
            updatedAt: daysAgo(3)
        },

        // ===== SYSTEM NOTIFICATIONS =====
        // System maintenance alert (all users would get this, showing for patient1)
        {
            _id: new ObjectId(),
            userId: IDS.profiles.patient1,
            userType: 'patient',
            title: 'Scheduled Maintenance',
            body: 'The eSanté platform will undergo scheduled maintenance on January 5, 2026 from 02:00-04:00. Services may be temporarily unavailable.',
            type: 'system_alert',
            relatedResource: {},
            channels: {
                push: { enabled: true, sent: true, sentAt: daysAgo(0) },
                email: { enabled: true, sent: true, sentAt: daysAgo(0) },
                inApp: { enabled: true, delivered: true }
            },
            isRead: false,
            readAt: null,
            priority: 'low',
            actionUrl: null,
            actionData: {},
            scheduledFor: daysFromNow(4),
            createdAt: daysAgo(0),
            updatedAt: daysAgo(0)
        }
    ];
};

// ============================================================
// MAIN SEED FUNCTION - STEP 6: Notifications
// ============================================================

const seedStep6 = async () => {
    console.log('🌱 STEP 6: Creating Notifications...\n');

    const notificationConn = createConnection(DB_NAMES.NOTIFICATIONS);

    await new Promise(resolve => notificationConn.on('connected', resolve));
    console.log('✅ Connected to notifications database\n');

    try {
        // Clear notifications database
        console.log('🧹 Clearing existing notifications...');
        await notificationConn.dropDatabase();

        // Create Notifications
        console.log('🔔 Creating notifications...');
        const notifications = createNotifications();
        await notificationConn.collection('notifications').insertMany(notifications);
        console.log(`✅ Created ${notifications.length} notifications`);

        // Create indexes
        await notificationConn.collection('notifications').createIndex({ userId: 1, createdAt: -1 });
        await notificationConn.collection('notifications').createIndex({ userId: 1, isRead: 1 });
        await notificationConn.collection('notifications').createIndex({ type: 1, createdAt: -1 });
        console.log('✅ Created indexes\n');

        // Print summary
        console.log('═══════════════════════════════════════════════════════════');
        console.log('📋 STEP 6 COMPLETE - Notifications Created');
        console.log('═══════════════════════════════════════════════════════════\n');

        console.log('🔔 NOTIFICATIONS BY USER:');
        console.log('─────────────────────────────────────────');
        
        const byUser = {
            'Patient1 (Mohamed)': notifications.filter(n => n.userId.equals(IDS.profiles.patient1)),
            'Patient2 (Leila)': notifications.filter(n => n.userId.equals(IDS.profiles.patient2)),
            'Patient3 (Karim)': notifications.filter(n => n.userId.equals(IDS.profiles.patient3)),
            'Patient4 (Sara)': notifications.filter(n => n.userId.equals(IDS.profiles.patient4)),
            'Doctor1 (Ahmed)': notifications.filter(n => n.userId.equals(IDS.profiles.doctor1)),
            'Doctor2 (Fatma)': notifications.filter(n => n.userId.equals(IDS.profiles.doctor2)),
            'Doctor3 (Yasmine)': notifications.filter(n => n.userId.equals(IDS.profiles.doctor3)),
            'Doctor4 (Rached)': notifications.filter(n => n.userId.equals(IDS.profiles.doctor4))
        };

        Object.entries(byUser).forEach(([user, notifs]) => {
            if (notifs.length > 0) {
                const unread = notifs.filter(n => !n.isRead).length;
                console.log(`   ${user}: ${notifs.length} notifications (${unread} unread)`);
            }
        });

        console.log('\n📊 NOTIFICATIONS BY TYPE:');
        console.log('─────────────────────────────────────────');
        const byType = {};
        notifications.forEach(n => {
            byType[n.type] = (byType[n.type] || 0) + 1;
        });
        Object.entries(byType).forEach(([type, count]) => {
            console.log(`   ${type}: ${count}`);
        });

        console.log('\n⚠️ UNREAD NOTIFICATIONS:');
        console.log('─────────────────────────────────────────');
        const unread = notifications.filter(n => !n.isRead);
        unread.forEach(n => {
            const priority = n.priority === 'urgent' ? '🚨' : n.priority === 'high' ? '❗' : '📬';
            console.log(`   ${priority} ${n.title}`);
            console.log(`      For: ${n.userType} | Priority: ${n.priority}`);
        });

        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('🎉 ALL STEPS COMPLETE! Comprehensive seed data created.');
        console.log('═══════════════════════════════════════════════════════════\n');

        console.log('📌 SUMMARY OF ALL SEEDED DATA:');
        console.log('─────────────────────────────────────────');
        console.log('   Step 1: 9 Auth Users + 8 Profiles (4 Doctors, 4 Patients)');
        console.log('   Step 2: 60 days of TimeSlots + 8 Appointments');
        console.log('   Step 3: 5 Consultations + 4 Prescriptions');
        console.log('   Step 4: 5 Medical Documents + 4 Referrals');
        console.log('   Step 5: 6 Conversations + 20 Messages');
        console.log('   Step 6: 17 Notifications');
        console.log('\n   Total: 130+ interconnected records across 7 databases\n');

        console.log('═══════════════════════════════════════════════════════════');
        console.log('🚀 To run all steps sequentially:');
        console.log('   SEED_STEP=1 node seed-comprehensive.js');
        console.log('   SEED_STEP=2 node seed-comprehensive.js');
        console.log('   SEED_STEP=3 node seed-comprehensive.js');
        console.log('   SEED_STEP=4 node seed-comprehensive.js');
        console.log('   SEED_STEP=5 node seed-comprehensive.js');
        console.log('   SEED_STEP=6 node seed-comprehensive.js');
        console.log('═══════════════════════════════════════════════════════════\n');

    } catch (error) {
        console.error('❌ Step 6 Failed:', error);
    } finally {
        await notificationConn.close();
    }
};
