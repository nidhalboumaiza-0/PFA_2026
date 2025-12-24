# PROMPT 2: Service Auth - Authentication Microservice

## Objective
Build a complete authentication and authorization microservice with email verification, JWT tokens, and role-based access control for Patients and Doctors.

## Requirements

### 1. Database Schema

#### User Model
```javascript
{
  email: String (unique, required),
  password: String (hashed, required),
  role: String (enum: ['patient', 'doctor', 'admin'], required),
  isEmailVerified: Boolean (default: false),
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  passwordResetToken: String,
  passwordResetExpires: Date,
  isActive: Boolean (default: true),
  lastLogin: Date,
  createdAt: Date,
  updatedAt: Date,
  
  // Reference to detailed profile
  profileId: ObjectId (reference to Patient or Doctor collection)
}
```

### 2. Core Features

#### A. Registration (Sign Up)
**Endpoint:** `POST /api/v1/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "role": "patient", // or "doctor"
  "profileData": {
    // Patient: firstName, lastName, dateOfBirth, phone, address
    // Doctor: firstName, lastName, specialty, phone, clinicAddress, licenseNumber
  }
}
```

**Process:**
1. Validate input data
2. Check if email already exists
3. Hash password with bcrypt (10 rounds)
4. Generate email verification token (JWT or random string)
5. Create user in database (isEmailVerified: false)
6. Create profile in User Service (Patient/Doctor)
7. Send verification email via Nodemailer
8. Publish Kafka event: `user.registered`
9. Return success message

**Email Template:**
- Welcome message
- Verification link: `${FRONTEND_URL}/verify-email?token=${token}`
- Token expires in 24 hours

#### B. Email Verification
**Endpoint:** `GET /api/v1/auth/verify-email/:token`

**Process:**
1. Decode/verify token
2. Check if token is expired
3. Find user by token
4. Set isEmailVerified = true
5. Clear verification token
6. Publish Kafka event: `user.verified`
7. Return success message

#### C. Login
**Endpoint:** `POST /api/v1/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Process:**
1. Find user by email
2. Check if user exists
3. Check if email is verified
4. Check if account is active
5. Compare password with bcrypt
6. Generate JWT access token (expires in 1 day)
7. Generate JWT refresh token (expires in 30 days)
8. Update lastLogin
9. Publish Kafka event: `user.logged_in`
10. Return tokens + user info (without password)

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "email": "...",
      "role": "patient",
      "isEmailVerified": true
    },
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG..."
  }
}
```

#### D. Refresh Token
**Endpoint:** `POST /api/v1/auth/refresh-token`

**Request Body:**
```json
{
  "refreshToken": "eyJhbG..."
}
```

**Process:**
1. Verify refresh token
2. Generate new access token
3. Return new access token

#### E. Forgot Password
**Endpoint:** `POST /api/v1/auth/forgot-password`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Process:**
1. Find user by email
2. Generate password reset token (expires in 1 hour)
3. Save token and expiry to database
4. Send reset email via Nodemailer
5. Return success message

**Email Template:**
- Password reset link: `${FRONTEND_URL}/reset-password?token=${token}`
- Token expires in 1 hour

#### F. Reset Password
**Endpoint:** `POST /api/v1/auth/reset-password/:token`

**Request Body:**
```json
{
  "newPassword": "NewSecurePass123"
}
```

**Process:**
1. Verify token and check expiry
2. Find user by token
3. Hash new password
4. Update password
5. Clear reset token
6. Publish Kafka event: `user.password_reset`
7. Send confirmation email
8. Return success message

#### G. Logout
**Endpoint:** `POST /api/v1/auth/logout`

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Process:**
1. Verify JWT token
2. Optional: Add token to blacklist (Redis)
3. Publish Kafka event: `user.logged_out`
4. Return success message

#### H. Change Password (Authenticated)
**Endpoint:** `POST /api/v1/auth/change-password`

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Request Body:**
```json
{
  "currentPassword": "OldPass123",
  "newPassword": "NewPass123"
}
```

**Process:**
1. Verify JWT token
2. Verify current password
3. Hash new password
4. Update password
5. Return success message

### 3. JWT Token Structure

#### Access Token Payload:
```javascript
{
  userId: "...",
  email: "...",
  role: "patient", // or "doctor" or "admin"
  profileId: "...",
  type: "access",
  iat: 1234567890,
  exp: 1234567890
}
```

#### Refresh Token Payload:
```javascript
{
  userId: "...",
  type: "refresh",
  iat: 1234567890,
  exp: 1234567890
}
```

### 4. Middleware

#### authenticate (Verify JWT)
```javascript
// Usage: protect routes
router.get('/profile', authenticate, getProfile);
```

#### authorize (Role-based)
```javascript
// Usage: restrict to specific roles
router.post('/admin/users', authenticate, authorize('admin'), createUser);
```

### 5. Security Features
- Password hashing with bcrypt (10+ rounds)
- JWT with secure secrets
- Token expiration
- Email verification required
- Rate limiting on auth endpoints
- Account lockout after failed attempts (optional)
- Audit logging for all auth events

### 6. Nodemailer Configuration

#### Email Service Setup:
```javascript
// Support Gmail, SendGrid, or custom SMTP
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});
```

#### Email Templates:
1. Welcome + Email Verification
2. Password Reset
3. Password Changed Confirmation
4. Account Activated

### 7. Kafka Events Published

```javascript
// user.registered
{
  eventType: 'user.registered',
  userId: '...',
  email: '...',
  role: 'patient',
  timestamp: Date.now()
}

// user.verified
{
  eventType: 'user.verified',
  userId: '...',
  email: '...',
  timestamp: Date.now()
}

// user.logged_in
{
  eventType: 'user.logged_in',
  userId: '...',
  timestamp: Date.now()
}

// user.password_reset
{
  eventType: 'user.password_reset',
  userId: '...',
  timestamp: Date.now()
}
```

### 8. Error Handling
- Invalid credentials
- Email already exists
- Email not verified
- Invalid/expired token
- Account inactive
- Weak password

### 9. Validation Rules
- Email: Valid email format
- Password: Min 8 characters, 1 uppercase, 1 lowercase, 1 number
- Role: Must be 'patient' or 'doctor' (admin created separately)

## API Endpoints Summary
```
POST   /api/v1/auth/register
GET    /api/v1/auth/verify-email/:token
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh-token
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password/:token
POST   /api/v1/auth/logout
POST   /api/v1/auth/change-password
GET    /api/v1/auth/me (get current user)
```

## Deliverables
1. ✅ User model with validation
2. ✅ All authentication endpoints
3. ✅ Email verification flow with Nodemailer
4. ✅ JWT token generation and verification
5. ✅ Password reset flow
6. ✅ Authentication middleware
7. ✅ Authorization middleware (role-based)
8. ✅ Kafka event publishers
9. ✅ Error handling
10. ✅ Input validation

## Testing Checklist
- [ ] Register patient successfully
- [ ] Register doctor successfully
- [ ] Email verification works
- [ ] Login with verified account
- [ ] Login fails with unverified account
- [ ] Refresh token works
- [ ] Forgot password sends email
- [ ] Reset password with valid token
- [ ] Change password when authenticated
- [ ] JWT middleware protects routes
- [ ] Role authorization works

---

**Next Step:** After this prompt is complete, proceed to PROMPT 3 (Service Users)
