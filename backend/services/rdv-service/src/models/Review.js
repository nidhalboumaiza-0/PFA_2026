import { mongoose } from '../../../../shared/index.js';

const reviewSchema = new mongoose.Schema({
    appointmentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Appointment',
        required: true,
        unique: true // One review per appointment
    },
    patientId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        index: true
    },
    doctorId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        index: true
    },
    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },
    comment: {
        type: String,
        maxlength: 1000,
        default: null // Comment is optional
    }
}, {
    timestamps: true
});

// Index for getting all reviews for a doctor, sorted by date
reviewSchema.index({ doctorId: 1, createdAt: -1 });

// Static method to calculate average rating for a doctor
reviewSchema.statics.calculateAverageRating = async function(doctorId) {
    const result = await this.aggregate([
        { $match: { doctorId: new mongoose.Types.ObjectId(doctorId) } },
        {
            $group: {
                _id: '$doctorId',
                averageRating: { $avg: '$rating' },
                totalReviews: { $sum: 1 }
            }
        }
    ]);

    if (result.length > 0) {
        return {
            rating: Math.round(result[0].averageRating * 10) / 10, // Round to 1 decimal
            totalReviews: result[0].totalReviews
        };
    }

    return { rating: 0, totalReviews: 0 };
};

const Review = mongoose.model('Review', reviewSchema);

export default Review;
