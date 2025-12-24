import Joi from 'joi';

const documentTypeEnum = ['lab_result', 'imaging', 'prescription', 'insurance', 'medical_report', 'other'];

const uploadDocumentSchema = Joi.object({
  patientId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
  consultationId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
  documentType: Joi.string().valid(...documentTypeEnum).required(),
  title: Joi.string().trim().max(200).required(),
  description: Joi.string().trim().max(1000),
  documentDate: Joi.date(),
  tags: Joi.alternatives().try(
    Joi.array().items(Joi.string().trim().lowercase().max(50)),
    Joi.string().custom((value, helpers) => {
      // Convert comma-separated string to array
      return value.split(',').map(tag => tag.trim().toLowerCase());
    })
  )
});

const updateDocumentSchema = Joi.object({
  title: Joi.string().trim().max(200),
  description: Joi.string().trim().max(1000),
  documentDate: Joi.date(),
  tags: Joi.array().items(Joi.string().trim().lowercase().max(50)),
  isSharedWithAllDoctors: Joi.boolean(),
  sharedWithDoctors: Joi.array().items(Joi.string().pattern(/^[0-9a-fA-F]{24}$/))
}).min(1);

const updateSharingSchema = Joi.object({
  isSharedWithAllDoctors: Joi.boolean().required(),
  sharedWithDoctors: Joi.array().items(Joi.string().pattern(/^[0-9a-fA-F]{24}$/))
});

const getDocumentsQuerySchema = Joi.object({
  documentType: Joi.string().valid(...documentTypeEnum),
  startDate: Joi.date(),
  endDate: Joi.date().min(Joi.ref('startDate')),
  consultationId: Joi.string().pattern(/^[0-9a-fA-F]{24}$/),
  tags: Joi.alternatives().try(
    Joi.array().items(Joi.string()),
    Joi.string()
  ),
  status: Joi.string().valid('active', 'archived', 'deleted').default('active'),
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20)
});

// Validation middleware
export const validateUploadDocument = (req, res, next) => {
  const { error, value } = uploadDocumentSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.body = value;
  next();
};

export const validateUpdateDocument = (req, res, next) => {
  const { error, value } = updateDocumentSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.body = value;
  next();
};

export const validateUpdateSharing = (req, res, next) => {
  const { error, value } = updateSharingSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.body = value;
  next();
};

export const validateGetDocumentsQuery = (req, res, next) => {
  const { error, value } = getDocumentsQuerySchema.validate(req.query, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(detail => detail.message);
    return res.status(400).json({
      message: 'Validation error',
      errors
    });
  }

  req.query = value;
  next();
};
