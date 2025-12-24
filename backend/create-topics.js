const { Kafka } = require('kafkajs');

const kafka = new Kafka({
    clientId: 'admin-client',
    brokers: ['localhost:9092']
});

const admin = kafka.admin();

const topics = [
    'user.registered',
    'user.updated',
    'user.deleted',
    'auth.login',
    'auth.logout',
    'appointment.created',
    'appointment.updated',
    'appointment.cancelled',
    'appointment.confirmed',
    'consultation.created',
    'consultation.updated',
    'prescription.created',
    'prescription.updated',
    'prescription.locked',
    'prescription.auto_locked',
    'medical-document.uploaded',
    'referral.created',
    'referral.updated',
    'message.sent',
    'message.read',
    'notification.created',
    'audit.log'
];

const run = async () => {
    try {
        await admin.connect();
        console.log('✅ Connected to Kafka Admin');

        const existingTopics = await admin.listTopics();
        const topicsToCreate = topics.filter(t => !existingTopics.includes(t));

        if (topicsToCreate.length > 0) {
            console.log(`Creating topics: ${topicsToCreate.join(', ')}`);
            await admin.createTopics({
                topics: topicsToCreate.map(topic => ({
                    topic,
                    numPartitions: 1,
                    replicationFactor: 1
                }))
            });
            console.log('✅ Topics created successfully');
        } else {
            console.log('✅ All topics already exist');
        }

        await admin.disconnect();
    } catch (error) {
        console.error('❌ Error creating topics:', error);
        process.exit(1);
    }
};

run();
