import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

// Configuration - use environment variable or fallback to localhost
const MONGO_URI_BASE = process.env.MONGO_URI || 'mongodb://admin:password@localhost:27017';
const DB_NAMES = {
    AUTH: 'esante_auth',
    USER: 'esante_users',
    RDV: 'esante_rdv',
    MEDICAL: 'esante_medical_records',
    MESSAGING: 'esante_messaging',
    NOTIFICATION: 'esante_notifications'
};

// Helper to create connection
const createConnection = (dbName) => {
    return mongoose.createConnection(`${MONGO_URI_BASE}/${dbName}?authSource=admin`);
};

// ============================================================
// COMPREHENSIVE MOCK DATA - Tunis Area (Close Geographic)
// ============================================================

// Base coordinates: Mountain View, California (Android Emulator Default Location)
// This ensures doctors are near the emulator's default GPS location
const BASE_COORDS = { lng: -122.0840, lat: 37.4220 };

// Generate nearby coordinates (within ~5km radius)
const getNearbyCoords = (index, spread = 0.02) => {
    const offsetLng = (Math.random() - 0.5) * spread;
    const offsetLat = (Math.random() - 0.5) * spread;
    return [BASE_COORDS.lng + offsetLng, BASE_COORDS.lat + offsetLat];
};

// Comprehensive doctor data
const doctorProfiles = [
    {
        firstName: 'Ahmed',
        lastName: 'Ben Ali',
        specialty: 'Médecine Générale',
        subSpecialty: 'Médecine Familiale',
        phone: '+216 71 123 456',
        licenseNumber: 'TN-MG-2015-001',
        yearsOfExperience: 12,
        education: [
            { degree: 'Doctorat en Médecine', institution: 'Faculté de Médecine de Tunis', year: 2012 },
            { degree: 'Résidence en Médecine Générale', institution: 'Hôpital Charles Nicolle', year: 2015 }
        ],
        languages: ['Français', 'Arabe', 'Anglais'],
        clinicName: 'Cabinet Médical Ben Ali',
        clinicAddress: {
            street: '45 Avenue Habib Bourguiba',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1000',
            country: 'Tunisia'
        },
        about: 'Médecin généraliste expérimenté avec plus de 12 ans de pratique. Spécialisé dans la médecine familiale et la prévention. Je m\'engage à offrir des soins personnalisés et attentifs à chaque patient.',
        consultationFee: 60,
        acceptsInsurance: true,
        rating: 4.8,
        totalReviews: 156
    },
    {
        firstName: 'Fatma',
        lastName: 'Trabelsi',
        specialty: 'Cardiologie',
        subSpecialty: 'Échocardiographie',
        phone: '+216 71 234 567',
        licenseNumber: 'TN-CD-2010-042',
        yearsOfExperience: 18,
        education: [
            { degree: 'Doctorat en Médecine', institution: 'Faculté de Médecine de Sousse', year: 2006 },
            { degree: 'Spécialisation Cardiologie', institution: 'Hôpital La Rabta', year: 2010 }
        ],
        languages: ['Français', 'Arabe', 'Anglais'],
        clinicName: 'Centre Cardiologique Trabelsi',
        clinicAddress: {
            street: '123 Rue de Marseille, Les Berges du Lac',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1053',
            country: 'Tunisia'
        },
        about: 'Cardiologue certifiée avec une expertise en échocardiographie et maladies cardiovasculaires. Je combine les dernières avancées médicales avec une approche humaine.',
        consultationFee: 100,
        acceptsInsurance: true,
        rating: 4.9,
        totalReviews: 234
    },
    {
        firstName: 'Youssef',
        lastName: 'Hammami',
        specialty: 'Dermatologie',
        subSpecialty: 'Dermatologie Esthétique',
        phone: '+216 71 345 678',
        licenseNumber: 'TN-DM-2013-089',
        yearsOfExperience: 14,
        education: [
            { degree: 'Doctorat en Médecine', institution: 'Faculté de Médecine de Tunis', year: 2009 },
            { degree: 'Diplôme de Dermatologie', institution: 'Hôpital Habib Thameur', year: 2013 }
        ],
        languages: ['Français', 'Arabe', 'Anglais'],
        clinicName: 'Clinique Dermatologique Hammami',
        clinicAddress: {
            street: '78 Avenue de la Liberté, Belvédère',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1002',
            country: 'Tunisia'
        },
        about: 'Dermatologue spécialisé dans le traitement des maladies de la peau et la dermatologie esthétique. J\'utilise des techniques modernes pour des résultats optimaux.',
        consultationFee: 80,
        acceptsInsurance: true,
        rating: 4.7,
        totalReviews: 189
    },
    {
        firstName: 'Khadija',
        lastName: 'Sassi',
        specialty: 'Pédiatrie',
        subSpecialty: 'Néonatologie',
        phone: '+216 71 456 789',
        licenseNumber: 'TN-PD-2011-156',
        yearsOfExperience: 16,
        education: [
            { degree: 'Doctorat en Médecine', institution: 'Faculté de Médecine de Monastir', year: 2007 },
            { degree: 'Spécialisation Pédiatrie', institution: 'Hôpital d\'Enfants de Tunis', year: 2011 }
        ],
        languages: ['Français', 'Arabe'],
        clinicName: 'Cabinet Pédiatrique Sassi',
        clinicAddress: {
            street: '34 Rue Alain Savary, El Menzah',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1004',
            country: 'Tunisia'
        },
        about: 'Pédiatre dévouée avec une passion pour la santé des enfants. Spécialisée en néonatologie, j\'accompagne les familles avec bienveillance et professionnalisme.',
        consultationFee: 70,
        acceptsInsurance: true,
        rating: 4.9,
        totalReviews: 312
    },
    {
        firstName: 'Omar',
        lastName: 'Chaabane',
        specialty: 'Ophtalmologie',
        subSpecialty: 'Chirurgie Réfractive',
        phone: '+216 71 567 890',
        licenseNumber: 'TN-OP-2008-023',
        yearsOfExperience: 20,
        education: [
            { degree: 'Doctorat en Médecine', institution: 'Faculté de Médecine de Tunis', year: 2003 },
            { degree: 'Fellowship Chirurgie Réfractive', institution: 'Institut Hedi Raies d\'Ophtalmologie', year: 2008 }
        ],
        languages: ['Français', 'Arabe', 'Anglais'],
        clinicName: 'Centre Ophtalmologique Chaabane',
        clinicAddress: {
            street: '92 Avenue de Paris, Lafayette',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1000',
            country: 'Tunisia'
        },
        about: 'Ophtalmologue expert en chirurgie réfractive (LASIK, PKR). 20 ans d\'expérience dans le traitement des pathologies oculaires avec les technologies les plus avancées.',
        consultationFee: 90,
        acceptsInsurance: true,
        rating: 4.8,
        totalReviews: 267
    },
    {
        firstName: 'Salma',
        lastName: 'Bouazizi',
        specialty: 'Gynécologie',
        subSpecialty: 'Obstétrique',
        phone: '+216 71 678 901',
        licenseNumber: 'TN-GY-2012-078',
        yearsOfExperience: 15,
        education: [
            { degree: 'Doctorat en Médecine', institution: 'Faculté de Médecine de Sfax', year: 2008 },
            { degree: 'DES Gynécologie-Obstétrique', institution: 'Hôpital Wassila Bourguiba', year: 2012 }
        ],
        languages: ['Français', 'Arabe', 'Anglais'],
        clinicName: 'Cabinet Gynécologique Bouazizi',
        clinicAddress: {
            street: '56 Rue de Palestine, Mutuelleville',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1002',
            country: 'Tunisia'
        },
        about: 'Gynécologue-obstétricienne passionnée par la santé féminine. J\'accompagne mes patientes à chaque étape de leur vie avec écoute et expertise.',
        consultationFee: 85,
        acceptsInsurance: true,
        rating: 4.9,
        totalReviews: 198
    },
    {
        firstName: 'Rachid',
        lastName: 'Miled',
        specialty: 'Orthopédie',
        subSpecialty: 'Chirurgie du Genou',
        phone: '+216 71 789 012',
        licenseNumber: 'TN-OR-2009-034',
        yearsOfExperience: 19,
        education: [
            { degree: 'Doctorat en Médecine', institution: 'Faculté de Médecine de Tunis', year: 2004 },
            { degree: 'Spécialisation Orthopédie', institution: 'Institut Kassab d\'Orthopédie', year: 2009 }
        ],
        languages: ['Français', 'Arabe', 'Anglais'],
        clinicName: 'Clinique Orthopédique Miled',
        clinicAddress: {
            street: '112 Avenue Mohamed V, Centre Urbain Nord',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1003',
            country: 'Tunisia'
        },
        about: 'Chirurgien orthopédiste spécialisé dans la chirurgie du genou et les traumatismes sportifs. Je combine expertise chirurgicale et médecine sportive.',
        consultationFee: 95,
        acceptsInsurance: true,
        rating: 4.7,
        totalReviews: 145
    },
    {
        firstName: 'Nadia',
        lastName: 'Gharbi',
        specialty: 'Psychiatrie',
        subSpecialty: 'Psychothérapie',
        phone: '+216 71 890 123',
        licenseNumber: 'TN-PS-2014-067',
        yearsOfExperience: 13,
        education: [
            { degree: 'Doctorat en Médecine', institution: 'Faculté de Médecine de Sousse', year: 2010 },
            { degree: 'DES Psychiatrie', institution: 'Hôpital Razi', year: 2014 }
        ],
        languages: ['Français', 'Arabe', 'Anglais'],
        clinicName: 'Cabinet de Psychiatrie Gharbi',
        clinicAddress: {
            street: '28 Rue du Lac Léman, Les Berges du Lac',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1053',
            country: 'Tunisia'
        },
        about: 'Psychiatre et psychothérapeute, je propose une approche globale de la santé mentale. Spécialisée dans l\'anxiété, la dépression et les troubles de l\'humeur.',
        consultationFee: 100,
        acceptsInsurance: true,
        rating: 4.8,
        totalReviews: 178
    }
];

// Comprehensive patient data
const patientProfiles = [
    {
        firstName: 'Mohamed',
        lastName: 'Belhaj',
        dateOfBirth: new Date('1985-03-15'),
        gender: 'male',
        phone: '+216 20 111 111',
        address: {
            street: '23 Rue Ibn Khaldoun',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1000',
            country: 'Tunisia'
        },
        bloodType: 'A+',
        allergies: ['Pénicilline'],
        chronicDiseases: ['Hypertension'],
        emergencyContact: {
            name: 'Sonia Belhaj',
            relationship: 'Épouse',
            phone: '+216 20 111 222'
        },
        insuranceInfo: {
            provider: 'CNAM',
            policyNumber: 'CNAM-2023-789456',
            expiryDate: new Date('2025-12-31')
        }
    },
    {
        firstName: 'Leila',
        lastName: 'Jebali',
        dateOfBirth: new Date('1990-07-22'),
        gender: 'female',
        phone: '+216 22 222 222',
        address: {
            street: '67 Avenue de Carthage',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1000',
            country: 'Tunisia'
        },
        bloodType: 'O+',
        allergies: [],
        chronicDiseases: [],
        emergencyContact: {
            name: 'Karim Jebali',
            relationship: 'Frère',
            phone: '+216 22 222 333'
        },
        insuranceInfo: {
            provider: 'CNRPS',
            policyNumber: 'CNRPS-2024-123456',
            expiryDate: new Date('2026-06-30')
        }
    },
    {
        firstName: 'Karim',
        lastName: 'Nasri',
        dateOfBirth: new Date('1978-11-08'),
        gender: 'male',
        phone: '+216 23 333 333',
        address: {
            street: '89 Rue de Bizerte, Bab Saadoun',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1005',
            country: 'Tunisia'
        },
        bloodType: 'B+',
        allergies: ['Aspirine', 'Fruits de mer'],
        chronicDiseases: ['Diabète Type 2', 'Cholestérol'],
        emergencyContact: {
            name: 'Amina Nasri',
            relationship: 'Épouse',
            phone: '+216 23 333 444'
        },
        insuranceInfo: {
            provider: 'STAR Assurance',
            policyNumber: 'STAR-2023-567890',
            expiryDate: new Date('2025-08-15')
        }
    },
    {
        firstName: 'Sara',
        lastName: 'Khemiri',
        dateOfBirth: new Date('1995-02-14'),
        gender: 'female',
        phone: '+216 24 444 444',
        address: {
            street: '15 Rue Farhat Hached, El Manar',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '2092',
            country: 'Tunisia'
        },
        bloodType: 'AB+',
        allergies: ['Arachides'],
        chronicDiseases: [],
        emergencyContact: {
            name: 'Hassan Khemiri',
            relationship: 'Père',
            phone: '+216 24 444 555'
        },
        insuranceInfo: {
            provider: 'GAT Assurance',
            policyNumber: 'GAT-2024-345678',
            expiryDate: new Date('2026-03-20')
        }
    },
    {
        firstName: 'Yassine',
        lastName: 'Mejri',
        dateOfBirth: new Date('1982-09-30'),
        gender: 'male',
        phone: '+216 25 555 555',
        address: {
            street: '42 Boulevard 7 Novembre, Ariana',
            city: 'Ariana',
            state: 'Ariana',
            zipCode: '2080',
            country: 'Tunisia'
        },
        bloodType: 'O-',
        allergies: [],
        chronicDiseases: ['Asthme'],
        emergencyContact: {
            name: 'Nadia Mejri',
            relationship: 'Sœur',
            phone: '+216 25 555 666'
        },
        insuranceInfo: {
            provider: 'Carte Assurance',
            policyNumber: 'CARTE-2023-901234',
            expiryDate: new Date('2025-11-30')
        }
    },
    {
        firstName: 'Hind',
        lastName: 'Chtioui',
        dateOfBirth: new Date('1988-05-18'),
        gender: 'female',
        phone: '+216 26 666 666',
        address: {
            street: '78 Rue du Lac Windermere, Les Berges du Lac',
            city: 'Tunis',
            state: 'Tunis',
            zipCode: '1053',
            country: 'Tunisia'
        },
        bloodType: 'A-',
        allergies: ['Latex', 'Sulfamides'],
        chronicDiseases: ['Migraine chronique'],
        emergencyContact: {
            name: 'Ahmed Chtioui',
            relationship: 'Époux',
            phone: '+216 26 666 777'
        },
        insuranceInfo: {
            provider: 'AMI Assurance',
            policyNumber: 'AMI-2024-678901',
            expiryDate: new Date('2026-01-15')
        }
    }
];

// Working hours template
const defaultWorkingHours = [
    { day: 'Monday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '18:00' }] },
    { day: 'Tuesday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '18:00' }] },
    { day: 'Wednesday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '18:00' }] },
    { day: 'Thursday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '18:00' }] },
    { day: 'Friday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '12:30' }, { startTime: '14:00', endTime: '17:00' }] },
    { day: 'Saturday', isAvailable: true, slots: [{ startTime: '09:00', endTime: '13:00' }] },
    { day: 'Sunday', isAvailable: false, slots: [] }
];

const seed = async () => {
    console.log('🌱 Starting Database Seeding with Comprehensive Data...');
    console.log('📍 GPS Coordinates: Mountain View, CA (Android Emulator Default)');
    console.log('📝 Profile Info: Tunisian data for realistic testing');

    // Create connections
    const authConn = createConnection(DB_NAMES.AUTH);
    const userConn = createConnection(DB_NAMES.USER);
    const rdvConn = createConnection(DB_NAMES.RDV);
    const medicalConn = createConnection(DB_NAMES.MEDICAL);
    const msgConn = createConnection(DB_NAMES.MESSAGING);
    const notifConn = createConnection(DB_NAMES.NOTIFICATION);

    // Wait for connections
    await Promise.all([
        new Promise(resolve => authConn.on('connected', resolve)),
        new Promise(resolve => userConn.on('connected', resolve)),
        new Promise(resolve => rdvConn.on('connected', resolve)),
        new Promise(resolve => medicalConn.on('connected', resolve)),
        new Promise(resolve => msgConn.on('connected', resolve)),
        new Promise(resolve => notifConn.on('connected', resolve))
    ]);
    console.log('✅ Connected to all databases');

    try {
        // Clear existing data
        console.log('🧹 Clearing existing data...');
        await Promise.all([
            authConn.dropDatabase(),
            userConn.dropDatabase(),
            rdvConn.dropDatabase(),
            medicalConn.dropDatabase(),
            msgConn.dropDatabase(),
            notifConn.dropDatabase()
        ]);

        // ---------------------------------------------------------
        // 1. CREATE USERS & PROFILES
        // ---------------------------------------------------------
        console.log('👤 Creating Users and Profiles...');

        const passwordHash = await bcrypt.hash('password123', 10);
        const users = [];
        const doctors = [];
        const patients = [];

        // Admin User
        const adminId = new mongoose.Types.ObjectId();
        users.push({
            _id: adminId,
            email: 'admin@esante.ma',
            password: passwordHash,
            role: 'admin',
            isEmailVerified: true,
            isActive: true,
            lastLogin: new Date(),
            createdAt: new Date(),
            updatedAt: new Date()
        });

        // Create Doctors with full profiles
        console.log('👨‍⚕️ Creating Doctor profiles...');
        for (let i = 0; i < doctorProfiles.length; i++) {
            const profile = doctorProfiles[i];
            const userId = new mongoose.Types.ObjectId();
            const profileId = new mongoose.Types.ObjectId();
            const coords = getNearbyCoords(i);

            users.push({
                _id: userId,
                email: `${profile.firstName.toLowerCase()}.${profile.lastName.toLowerCase()}@esante.ma`,
                password: passwordHash,
                role: 'doctor',
                profileId: profileId,
                isEmailVerified: true,
                isActive: true,
                lastLogin: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000), // Random last login within week
                createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000), // Created within past year
                updatedAt: new Date()
            });

            doctors.push({
                _id: profileId,
                userId: userId,
                firstName: profile.firstName,
                lastName: profile.lastName,
                specialty: profile.specialty,
                subSpecialty: profile.subSpecialty,
                phone: profile.phone,
                profilePhoto: null,
                licenseNumber: profile.licenseNumber,
                yearsOfExperience: profile.yearsOfExperience,
                education: profile.education,
                languages: profile.languages,
                clinicName: profile.clinicName,
                clinicAddress: {
                    ...profile.clinicAddress,
                    coordinates: {
                        type: 'Point',
                        coordinates: coords
                    }
                },
                about: profile.about,
                consultationFee: profile.consultationFee,
                acceptsInsurance: profile.acceptsInsurance,
                rating: profile.rating,
                totalReviews: profile.totalReviews,
                workingHours: defaultWorkingHours,
                isVerified: true,
                isActive: true,
                createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
                updatedAt: new Date()
            });
        }

        // Create Patients with full profiles
        console.log('🏥 Creating Patient profiles...');
        for (let i = 0; i < patientProfiles.length; i++) {
            const profile = patientProfiles[i];
            const userId = new mongoose.Types.ObjectId();
            const profileId = new mongoose.Types.ObjectId();
            const coords = getNearbyCoords(i + 10); // Offset to avoid exact same coords as doctors

            users.push({
                _id: userId,
                email: `${profile.firstName.toLowerCase()}.${profile.lastName.toLowerCase()}@gmail.com`,
                password: passwordHash,
                role: 'patient',
                profileId: profileId,
                isEmailVerified: true,
                isActive: true,
                lastLogin: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000),
                createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
                updatedAt: new Date()
            });

            patients.push({
                _id: profileId,
                userId: userId,
                firstName: profile.firstName,
                lastName: profile.lastName,
                dateOfBirth: profile.dateOfBirth,
                gender: profile.gender,
                phone: profile.phone,
                address: {
                    ...profile.address,
                    coordinates: {
                        type: 'Point',
                        coordinates: coords
                    }
                },
                profilePhoto: null,
                bloodType: profile.bloodType,
                allergies: profile.allergies,
                chronicDiseases: profile.chronicDiseases,
                emergencyContact: profile.emergencyContact,
                insuranceInfo: profile.insuranceInfo,
                isActive: true,
                createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
                updatedAt: new Date()
            });
        }

        // Insert Users & Profiles
        await authConn.collection('users').insertMany(users);
        await userConn.collection('doctors').insertMany(doctors);
        await userConn.collection('patients').insertMany(patients);

        // Create 2dsphere indexes for geospatial queries
        await userConn.collection('doctors').createIndex({ 'clinicAddress.coordinates': '2dsphere' });
        await userConn.collection('patients').createIndex({ 'address.coordinates': '2dsphere' });

        // Create text indexes for search
        await userConn.collection('doctors').createIndex({
            firstName: 'text',
            lastName: 'text',
            clinicName: 'text',
            specialty: 'text'
        });

        console.log('✨ Database Seeding Completed Successfully!');
        console.log('-------------------------------------------');
        console.log('🔑 Test Credentials (Password: password123):');
        console.log('-------------------------------------------');
        console.log('👨‍💼 Admin:');
        console.log('   Email: admin@esante.ma');
        console.log('');
        console.log('👨‍⚕️ Doctors:');
        doctors.forEach((doc, i) => {
            const user = users.find(u => u.profileId?.toString() === doc._id.toString());
            console.log(`   ${i + 1}. Dr. ${doc.firstName} ${doc.lastName} (${doc.specialty})`);
            console.log(`      Email: ${user.email}`);
        });
        console.log('');
        console.log('🏥 Patients:');
        patients.forEach((pat, i) => {
            const user = users.find(u => u.profileId?.toString() === pat._id.toString());
            console.log(`   ${i + 1}. ${pat.firstName} ${pat.lastName}`);
            console.log(`      Email: ${user.email}`);
        });
        console.log('-------------------------------------------');
        console.log('📍 GPS: Mountain View, CA (matches Android Emulator default)');
        console.log('📅 No appointments created - ready for testing!');
        console.log('-------------------------------------------');

    } catch (error) {
        console.error('❌ Seeding Failed:', error);
    } finally {
        await Promise.all([
            authConn.close(),
            userConn.close(),
            rdvConn.close(),
            medicalConn.close(),
            msgConn.close(),
            notifConn.close()
        ]);
        process.exit(0);
    }
};

seed();
