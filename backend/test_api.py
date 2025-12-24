"""
E-Santé Backend API Testing Script
Tests all microservices with mock data
"""

import requests
import json
import time
from datetime import datetime, timedelta

# Configuration
BASE_URL = "http://localhost:3000/api/v1"  # API Gateway
SERVICES = {
    "auth": "http://localhost:3001/api/v1/auth",
    "users": "http://localhost:3002/api/v1/users",
    "rdv": "http://localhost:3003/api/v1/rdv",
    "medical": "http://localhost:3004/api/v1/medical-records",
    "referral": "http://localhost:3007/api/v1/referrals",
    "messaging": "http://localhost:3006/api/v1/messages",
    "notification": "http://localhost:3007/api/v1/notifications",
    "audit": "http://localhost:3008/api/v1/audit"
}

# Global variables to store tokens and IDs
tokens = {
    "patient": None,
    "doctor": None,
    "admin": None
}

user_ids = {
    "patient": None,
    "doctor": None
}

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

def print_success(message):
    print(f"{Colors.GREEN}[OK] {message}{Colors.RESET}")

def print_error(message):
    print(f"{Colors.RED}[ERROR] {message}{Colors.RESET}")

def print_info(message):
    print(f"{Colors.BLUE}[INFO] {message}{Colors.RESET}")

def print_warning(message):
    print(f"{Colors.YELLOW}[WARN] {message}{Colors.RESET}")

def print_section(title):
    print(f"\n{Colors.BLUE}{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}{Colors.RESET}\n")

# ============================================================================
# 1. AUTH SERVICE TESTS
# ============================================================================

def test_register_patient():
    """Test patient registration"""
    print_section("1. Testing Patient Registration")
    
    url = f"{SERVICES['auth']}/register"
    # Use timestamp to generate unique email
    import random
    timestamp = int(time.time())
    random_num = random.randint(1000, 9999)
    email = f"patient{timestamp}{random_num}@test.com"
    
    data = {
        "email": email,
        "password": "Test123456!",
        "role": "patient",
        "profileData": {
            "firstName": "Ahmed",
            "lastName": "Bennani",
            "phoneNumber": "+212612345678",
            "dateOfBirth": "1990-05-15",
            "gender": "male"
        }
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code in [200, 201]:
            result = response.json()
            print_info(f"Response: {json.dumps(result, indent=2)}")
            # Handle different response structures
            if "data" in result:
                tokens["patient"] = result["data"].get("accessToken") or result["data"].get("token")
                if "user" in result["data"]:
                    user_ids["patient"] = result["data"]["user"].get("_id") or result["data"]["user"].get("id")
                elif "userId" in result["data"]:
                    user_ids["patient"] = result["data"]["userId"]
            elif "token" in result or "accessToken" in result:
                tokens["patient"] = result.get("accessToken") or result.get("token")
                user_ids["patient"] = result.get("userId") or result.get("user", {}).get("_id")
            
            print_success(f"Patient registered: {data['email']}")
            if user_ids["patient"]:
                print_info(f"Patient ID: {user_ids['patient']}")
            if tokens["patient"]:
                print_info(f"Token: {tokens['patient'][:50]}...")
            return True
        else:
            print_error(f"Registration failed: {response.status_code}")
            print_error(response.text)
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def test_register_doctor():
    """Test doctor registration"""
    print_section("2. Testing Doctor Registration")
    
    url = f"{SERVICES['auth']}/register"
    # Use timestamp to generate unique email
    import random
    timestamp = int(time.time())
    random_num = random.randint(1000, 9999)
    email = f"doctor{timestamp}{random_num}@test.com"
    
    data = {
        "email": email,
        "password": "Test123456!",
        "role": "doctor",
        "profileData": {
            "firstName": "Fatima",
            "lastName": "Alaoui",
            "phoneNumber": "+212612345679",
            "specialty": "Cardiology",
            "licenseNumber": "DOC123456",
            "clinicName": "Clinique Al Madina",
            "clinicAddress": {
                "street": "123 Avenue Hassan II",
                "city": "Casablanca",
                "zipCode": "20000",
                "country": "Morocco",
                "coordinates": {
                    "latitude": 33.5731,
                    "longitude": -7.5898
                }
            }
        }
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code in [200, 201]:
            result = response.json()
            tokens["doctor"] = result.get("data", {}).get("accessToken") or result.get("accessToken")
            user_ids["doctor"] = result.get("data", {}).get("user", {}).get("_id") or result.get("userId")
            print_success(f"Doctor registered: {data['email']}")
            print_info(f"Doctor ID: {user_ids['doctor']}")
            print_info(f"Token: {tokens['doctor'][:50]}...")
            return True
        else:
            print_error(f"Registration failed: {response.status_code}")
            print_error(response.text)
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def test_login():
    """Test login functionality"""
    print_section("3. Testing Login")
    
    url = f"{SERVICES['auth']}/login"
    data = {
        "email": "patient@test.com",
        "password": "Test123456!"
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            print_success("Patient login successful")
            return True
        else:
            print_error(f"Login failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

# ============================================================================
# 2. USER SERVICE TESTS
# ============================================================================

def test_get_profile():
    """Test getting user profile"""
    print_section("4. Testing Get User Profile")
    
    if not tokens["patient"]:
        print_warning("No patient token available. Skipping...")
        return False
    
    url = f"{SERVICES['users']}/profile"
    headers = {"Authorization": f"Bearer {tokens['patient']}"}
    
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            result = response.json()
            print_success("Profile retrieved successfully")
            print_info(f"Name: {result.get('data', {}).get('firstName')} {result.get('data', {}).get('lastName')}")
            return True
        else:
            print_error(f"Failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def test_search_doctors():
    """Test searching doctors by location"""
    print_section("5. Testing Search Doctors by Location")
    
    url = f"{SERVICES['users']}/doctors/search"
    params = {
        "latitude": 33.5731,
        "longitude": -7.5898,
        "radius": 10,
        "specialty": "Cardiology"
    }
    
    try:
        response = requests.get(url, params=params)
        if response.status_code == 200:
            result = response.json()
            doctors = result.get("doctors", [])
            print_success(f"Found {len(doctors)} doctor(s)")
            if doctors:
                for doc in doctors[:3]:
                    distance = doc.get("distance", "N/A")
                    print_info(f"  - Dr. {doc.get('firstName', '')} {doc.get('lastName', '')} ({distance}km)")
            return True
        else:
            print_error(f"Failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

# ============================================================================
# 3. RDV SERVICE TESTS
# ============================================================================

appointment_id = None

def test_create_timeslot():
    """Test creating doctor availability slots"""
    print_section("6. Testing Create Doctor Time Slots")
    
    if not tokens["doctor"]:
        print_warning("No doctor token available. Skipping...")
        return False
    
    url = f"{SERVICES['rdv']}/timeslots"
    headers = {"Authorization": f"Bearer {tokens['doctor']}"}
    
    # Create slots for tomorrow
    tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    
    data = {
        "date": tomorrow,
        "slots": [
            {"startTime": "09:00", "endTime": "09:30", "isAvailable": True},
            {"startTime": "09:30", "endTime": "10:00", "isAvailable": True},
            {"startTime": "10:00", "endTime": "10:30", "isAvailable": True},
            {"startTime": "14:00", "endTime": "14:30", "isAvailable": True}
        ]
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code in [200, 201]:
            print_success(f"Time slots created for {tomorrow}")
            return True
        else:
            print_error(f"Failed: {response.status_code}")
            print_error(response.text)
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def test_book_appointment():
    """Test booking an appointment"""
    print_section("7. Testing Book Appointment")
    
    if not tokens["patient"] or not user_ids["doctor"]:
        print_warning("Missing patient token or doctor ID. Skipping...")
        return False
    
    url = f"{SERVICES['rdv']}/appointments"
    headers = {"Authorization": f"Bearer {tokens['patient']}"}
    
    tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    
    data = {
        "doctorId": user_ids["doctor"],
        "appointmentDate": tomorrow,
        "time": "09:00",
        "reason": "Consultation de routine"
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code in [200, 201]:
            result = response.json()
            global appointment_id
            appointment_id = result.get("data", {}).get("_id") or result.get("appointmentId")
            print_success(f"Appointment booked for {tomorrow} at 09:00")
            print_info(f"Appointment ID: {appointment_id}")
            return True
        else:
            print_error(f"Failed: {response.status_code}")
            print_error(response.text)
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def test_confirm_appointment():
    """Test confirming an appointment (doctor action)"""
    print_section("8. Testing Confirm Appointment")
    
    if not tokens["doctor"] or not appointment_id:
        print_warning("Missing doctor token or appointment ID. Skipping...")
        return False
    
    url = f"{SERVICES['rdv']}/appointments/{appointment_id}/confirm"
    headers = {"Authorization": f"Bearer {tokens['doctor']}"}
    
    try:
        response = requests.put(url, headers=headers)
        if response.status_code == 200:
            print_success("Appointment confirmed by doctor")
            return True
        else:
            print_error(f"Failed: {response.status_code}")
            print_error(response.text)
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

# ============================================================================
# 4. MEDICAL RECORDS TESTS
# ============================================================================

consultation_id = None

def test_create_consultation():
    """Test creating a consultation"""
    print_section("9. Testing Create Consultation")
    
    if not tokens["doctor"] or not appointment_id or not user_ids["patient"]:
        print_warning("Missing required data. Skipping...")
        return False
    
    url = f"{SERVICES['medical']}/consultations"
    headers = {"Authorization": f"Bearer {tokens['doctor']}"}
    
    data = {
        "appointmentId": appointment_id,
        "patientId": user_ids["patient"],
        "consultationDate": datetime.now().isoformat(),
        "consultationType": "in-person",
        "chiefComplaint": "Douleurs thoraciques",
        "medicalNote": {
            "symptoms": ["Douleur thoracique", "Essoufflement"],
            "diagnosis": "Hypertension artérielle",
            "physicalExamination": "Tension artérielle élevée: 150/95 mmHg",
            "vitalSigns": {
                "temperature": 37.0,
                "bloodPressureSystolic": 150,
                "bloodPressureDiastolic": 95,
                "heartRate": 80,
                "weight": 75,
                "height": 175
            },
            "additionalNotes": "Recommandation: Repos et suivi dans 2 semaines"
        }
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code in [200, 201]:
            result = response.json()
            global consultation_id
            consultation_id = result.get("data", {}).get("_id") or result.get("consultationId")
            print_success("Consultation created successfully")
            print_info(f"Consultation ID: {consultation_id}")
            return True
        else:
            print_error(f"Failed: {response.status_code}")
            print_error(response.text)
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def test_create_prescription():
    """Test creating a prescription"""
    print_section("10. Testing Create Prescription")
    
    if not tokens["doctor"] or not consultation_id:
        print_warning("Missing required data. Skipping...")
        return False
    
    url = f"{SERVICES['medical']}/prescriptions"
    headers = {"Authorization": f"Bearer {tokens['doctor']}"}
    
    data = {
        "consultationId": consultation_id,
        "patientId": user_ids["patient"],
        "medications": [
            {
                "medicationName": "Amlodipine",
                "dosage": "5mg",
                "form": "tablet",
                "frequency": "Une fois par jour",
                "duration": "30 jours",
                "instructions": "À prendre le matin avec un verre d'eau",
                "quantity": 30
            },
            {
                "medicationName": "Aspirine",
                "dosage": "100mg",
                "form": "tablet",
                "frequency": "Une fois par jour",
                "duration": "30 jours",
                "instructions": "Après le repas",
                "quantity": 30
            }
        ],
        "generalInstructions": "Éviter les aliments salés. Contrôle de la tension dans 2 semaines."
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code in [200, 201]:
            result = response.json()
            prescription_id = result.get("data", {}).get("_id")
            print_success("Prescription created successfully")
            print_info(f"Prescription ID: {prescription_id}")
            print_info("Medications: Amlodipine 5mg, Aspirine 100mg")
            return True
        else:
            print_error(f"Failed: {response.status_code}")
            print_error(response.text)
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

# ============================================================================
# 5. NOTIFICATIONS TEST
# ============================================================================

def test_get_notifications():
    """Test getting user notifications"""
    print_section("11. Testing Get Notifications")
    
    if not tokens["patient"]:
        print_warning("No patient token. Skipping...")
        return False
    
    url = f"{SERVICES['notification']}/notifications"
    headers = {"Authorization": f"Bearer {tokens['patient']}"}
    
    try:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            result = response.json()
            notifications = result.get("data", {}).get("notifications", [])
            unread = result.get("data", {}).get("unreadCount", 0)
            print_success(f"Retrieved {len(notifications)} notification(s)")
            print_info(f"Unread: {unread}")
            
            if notifications:
                for notif in notifications[:3]:
                    print_info(f"  - {notif.get('title')}")
            return True
        else:
            print_error(f"Failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

def run_all_tests():
    """Run all tests in sequence"""
    print(f"\n{Colors.BLUE}{'='*60}")
    print("  E-SANTÉ BACKEND API TESTING")
    print(f"{'='*60}{Colors.RESET}\n")
    
    print_info(f"Testing started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print_info(f"API Gateway: {BASE_URL}")
    print_info(f"Testing against localhost services\n")
    
    results = []
    
    # Auth Tests
    results.append(("Register Patient", test_register_patient()))
    time.sleep(1)
    results.append(("Register Doctor", test_register_doctor()))
    time.sleep(1)
    results.append(("Login", test_login()))
    time.sleep(1)
    
    # User Service Tests
    results.append(("Get Profile", test_get_profile()))
    time.sleep(1)
    results.append(("Search Doctors", test_search_doctors()))
    time.sleep(1)
    
    # RDV Tests
    results.append(("Create Time Slots", test_create_timeslot()))
    time.sleep(1)
    results.append(("Book Appointment", test_book_appointment()))
    time.sleep(1)
    results.append(("Confirm Appointment", test_confirm_appointment()))
    time.sleep(1)
    
    # Medical Records Tests
    results.append(("Create Consultation", test_create_consultation()))
    time.sleep(1)
    results.append(("Create Prescription", test_create_prescription()))
    time.sleep(1)
    
    # Notifications Test
    results.append(("Get Notifications", test_get_notifications()))
    
    # Print Summary
    print_section("TEST SUMMARY")
    
    passed = sum(1 for _, result in results if result)
    failed = len(results) - passed
    
    for test_name, result in results:
        status = f"{Colors.GREEN}PASSED{Colors.RESET}" if result else f"{Colors.RED}FAILED{Colors.RESET}"
        print(f"{test_name:.<50} {status}")
    
    print(f"\n{Colors.BLUE}{'='*60}{Colors.RESET}")
    print(f"Total Tests: {len(results)}")
    print(f"{Colors.GREEN}Passed: {passed}{Colors.RESET}")
    print(f"{Colors.RED}Failed: {failed}{Colors.RESET}")
    print(f"Success Rate: {(passed/len(results)*100):.1f}%")
    print(f"{Colors.BLUE}{'='*60}{Colors.RESET}\n")

if __name__ == "__main__":
    try:
        run_all_tests()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Tests interrupted by user{Colors.RESET}")
    except Exception as e:
        print(f"\n\n{Colors.RED}Unexpected error: {str(e)}{Colors.RESET}")
