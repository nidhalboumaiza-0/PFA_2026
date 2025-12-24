import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

// Configuration
const MONGO_URI_BASE = 'mongodb://admin:password@localhost:27017';
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

const seed = async () => {
    console.log('🌱 Starting Database Seeding...');

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

        // Admin
        const adminId = new mongoose.Types.ObjectId();
        users.push({
            _id: adminId,
            email: 'admin@test.com',
            password: passwordHash,
            role: 'admin',
            isEmailVerified: true,
            isActive: true,
            createdAt: new Date(),
            updatedAt: new Date()
        });

        // Doctors
        const doctorSpecs = ['Generalist', 'Cardiologist', 'Dermatologist'];
        for (let i = 0; i < 3; i++) {
            const userId = new mongoose.Types.ObjectId();
            const profileId = new mongoose.Types.ObjectId();

            users.push({
                _id: userId,
                email: `doctor${i + 1}@test.com`,
                password: passwordHash,
                role: 'doctor',
                profileId: profileId,
                isEmailVerified: true,
                isActive: true,
                createdAt: new Date(),
                updatedAt: new Date()
            });

            doctors.push({
                _id: profileId,
                userId: userId,
                firstName: `Doctor${i + 1}`,
                lastName: `Specialist${i + 1}`,
                specialization: doctorSpecs[i],
                licenseNumber: `LIC-${1000 + i}`,
                phone: `+123456789${i}`,
                address: { street: `${i + 1} Medical Plaza`, city: 'Paris', zipCode: '75001' },
                consultationFee: 50 + (i * 20),
                availability: {
                    monday: [{ start: '09:00', end: '17:00' }],
                    tuesday: [{ start: '09:00', end: '17:00' }],
                    wednesday: [{ start: '09:00', end: '17:00' }],
                    thursday: [{ start: '09:00', end: '17:00' }],
                    friday: [{ start: '09:00', end: '17:00' }]
                },
                createdAt: new Date(),
                updatedAt: new Date()
            });
        }

        // Patients
        for (let i = 0; i < 5; i++) {
            const userId = new mongoose.Types.ObjectId();
            const profileId = new mongoose.Types.ObjectId();

            users.push({
                _id: userId,
                email: `patient${i + 1}@test.com`,
                password: passwordHash,
                role: 'patient',
                profileId: profileId,
                isEmailVerified: true,
                isActive: true,
                createdAt: new Date(),
                updatedAt: new Date()
            });

            patients.push({
                _id: profileId,
                userId: userId,
                firstName: `Patient${i + 1}`,
                lastName: `User${i + 1}`,
                dateOfBirth: new Date(1980 + i * 5, 0, 1),
                gender: i % 2 === 0 ? 'Male' : 'Female',
                phone: `+987654321${i}`,
                address: { street: `${i + 1} Main St`, city: 'Lyon', zipCode: '69001' },
                bloodGroup: ['A+', 'O+', 'B-', 'AB+', 'O-'][i],
                createdAt: new Date(),
                updatedAt: new Date()
            });
        }

        // Insert Users & Profiles
        await authConn.collection('users').insertMany(users);
        await userConn.collection('doctors').insertMany(doctors);
        await userConn.collection('patients').insertMany(patients);

        // ---------------------------------------------------------
        // 2. CREATE APPOINTMENTS
        // ---------------------------------------------------------
        console.log('📅 Creating Appointments...');
        const appointments = [];
        const now = new Date();
        const oneDay = 24 * 60 * 60 * 1000;

        // Past Appointments (Completed)
        for (let i = 0; i < 3; i++) {
            const appId = new mongoose.Types.ObjectId();
            appointments.push({
                _id: appId,
                patientId: patients[i]._id,
                doctorId: doctors[0]._id, // All saw the Generalist
                date: new Date(now.getTime() - (i + 1) * oneDay),
                startTime: '10:00',
                endTime: '10:30',
                status: 'completed',
                type: 'consultation',
                reason: 'Regular checkup',
                createdAt: new Date(),
                updatedAt: new Date()
            });
        }

        // Upcoming Appointments (Confirmed)
        for (let i = 0; i < 2; i++) {
            const appId = new mongoose.Types.ObjectId();
            appointments.push({
                _id: appId,
                patientId: patients[i]._id,
                doctorId: doctors[1]._id, // Seeing Cardiologist
                date: new Date(now.getTime() + (i + 1) * oneDay),
                startTime: '14:00',
                endTime: '14:30',
                status: 'confirmed',
                type: 'consultation',
                reason: 'Heart checkup',
                createdAt: new Date(),
                updatedAt: new Date()
            });
        }

        await rdvConn.collection('appointments').insertMany(appointments);

        // ---------------------------------------------------------
        // 3. CREATE MEDICAL RECORDS (For completed appointments)
        // ---------------------------------------------------------
        console.log('🩺 Creating Medical Records...');
        const consultations = [];
        const prescriptions = [];

        const completedApps = appointments.filter(a => a.status === 'completed');

        for (const app of completedApps) {
            const consultId = new mongoose.Types.ObjectId();

            // Consultation
            consultations.push({
                _id: consultId,
                appointmentId: app._id,
                patientId: app.patientId,
                doctorId: app.doctorId,
                consultationDate: app.date,
                diagnosis: 'Common Cold',
                symptoms: ['Cough', 'Fever'],
                notes: 'Patient advised to rest.',
                vitalSigns: {
                    temperature: 38.5,
                    bloodPressure: '120/80',
                    heartRate: 75,
                    weight: 70
                },
                createdAt: new Date(),
                updatedAt: new Date()
            });

            // Prescription
            prescriptions.push({
                consultationId: consultId,
                patientId: app.patientId,
                doctorId: app.doctorId,
                prescriptionDate: app.date,
                medications: [
                    {
                        medicationName: 'Paracetamol',
                        dosage: '500mg',
                        frequency: '3 times a day',
                        duration: '5 days',
                        form: 'tablet'
                    }
                ],
                isLocked: true, // Past prescriptions are locked
                status: 'active',
                createdBy: app.doctorId,
                createdAt: new Date(),
                updatedAt: new Date()
            });
        }

        await medicalConn.collection('consultations').insertMany(consultations);
        await medicalConn.collection('prescriptions').insertMany(prescriptions);

        // ---------------------------------------------------------
        // 4. CREATE MESSAGES
        // ---------------------------------------------------------
        console.log('💬 Creating Messages...');
        const conversationId = new mongoose.Types.ObjectId();

        // Conversation between Patient 1 and Doctor 1
        await msgConn.collection('conversations').insertOne({
            _id: conversationId,
            participants: [
                { userId: patients[0].userId, role: 'patient' },
                { userId: doctors[0].userId, role: 'doctor' }
            ],
            lastMessage: {
                content: 'Thank you doctor.',
                senderId: patients[0].userId,
                createdAt: new Date()
            },
            createdAt: new Date(),
            updatedAt: new Date()
        });

        await msgConn.collection('messages').insertMany([
            {
                conversationId: conversationId,
                senderId: doctors[0].userId,
                content: 'How are you feeling today?',
                readBy: [{ userId: patients[0].userId, readAt: new Date() }],
                createdAt: new Date(now.getTime() - 1000 * 60 * 60)
            },
            {
                conversationId: conversationId,
                senderId: patients[0].userId,
                content: 'Much better, thanks!',
                readBy: [],
                createdAt: new Date(now.getTime() - 1000 * 60 * 30)
            }
        ]);

        console.log('✨ Database Seeding Completed Successfully!');
        console.log('-------------------------------------------');
        console.log('🔑 Test Credentials:');
        console.log('   Patient: patient1@test.com / password123');
        console.log('   Doctor:  doctor1@test.com  / password123');
        console.log('   Admin:   admin@test.com    / password123');
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
