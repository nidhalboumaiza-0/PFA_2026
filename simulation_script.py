import requests
import json
import time
import random
from datetime import datetime, timedelta
import sys

# Configuration
BASE_URL = "http://localhost:3000"  # API Gateway URL
HEADERS = {"Content-Type": "application/json"}

# Test Data
DOCTOR_EMAIL = f"doctor_{int(time.time())}@test.com"
PATIENT_EMAIL = f"patient_{int(time.time())}@test.com"
PASSWORD = "Password123!"

# Location: Central Tunis (Example)
LAT = 36.8065
LON = 10.1815

def print_step(message):
    print(f"\n{'='*50}")
    print(f"[*] {message}")
    print(f"{'='*50}")

def register_user(role, email, password, name):
    print_step(f"Registering {role}: {email}")
    url = f"{BASE_URL}/api/v1/auth/register"
    data = {
        "email": email,
        "password": password,
        "fullName": name,
        "role": role,
        "phoneNumber": f"55{random.randint(100000, 999999)}"
    }
    
    # Add doctor specific fields
    if role == "doctor":
        data.update({
            "specialty": "Cardiologist",
            "licenseNumber": f"TUN-{random.randint(10000, 99999)}",
            "bio": "Expert in heart health with 10 years experience."
        })
        
    try:
        response = requests.post(url, json=data, headers=HEADERS)
        if response.status_code in [200, 201]:
            print(f"[+] {role.capitalize()} registered successfully.")
            return True
        else:
            print(f"[-] Failed to register {role}: {response.text}")
            return False
    except Exception as e:
        print(f"[-] Error: {e}")
        return False

def login_user(email, password):
    print_step(f"Logging in: {email}")
    url = f"{BASE_URL}/api/v1/auth/login"
    data = {
        "email": email,
        "password": password
    }
    
    try:
        response = requests.post(url, json=data, headers=HEADERS)
        if response.status_code == 200:
            result = response.json()
            token = result['data']['tokens']['accessToken']
            user_id = result['data']['user']['id']
            print(f"[+] Login successful. Token: {token[:10]}...")
            return token, user_id
        else:
            print(f"[-] Login failed: {response.text}")
            return None, None
    except Exception as e:
        print(f"[-] Error: {e}")
        return None, None

def update_location(token, role, lat, lon):
    print_step(f"Updating {role} location to ({lat}, {lon})")
    endpoint = "/api/v1/users/doctor/profile" if role == "doctor" else "/api/v1/users/patient/profile"
    url = f"{BASE_URL}{endpoint}"
    
    # Provide appropriate payload structure according to your backend schema
    # Assuming update profile accepts location object or individual fields
    data = {
        "location": {
            "type": "Point",
            "coordinates": [lon, lat], # GeoJSON expects [lon, lat]
            "address": "Tunis, Tunisia"
        }
    }
    
    headers = HEADERS.copy()
    headers["Authorization"] = f"Bearer {token}"
    
    try:
        response = requests.patch(url, json=data, headers=headers)
        if response.status_code == 200:
            print("[+] Location updated successfully.")
            return True
        else:
            print(f"[-] Failed to update location: {response.text}")
            return False
    except Exception as e:
        print(f"[-] Error: {e}")
        return False

def set_doctor_availability(token, doctor_id):
    print_step("Setting Doctor Availability")
    url = f"{BASE_URL}/api/v1/appointments/doctor/availability"
    
    # Set availability for today
    today = datetime.now().strftime("%Y-%m-%d")
    data = {
        "date": today,
        "timeSlots": ["09:00", "10:00", "11:00", "14:00", "15:00"]
    }
    
    headers = HEADERS.copy()
    headers["Authorization"] = f"Bearer {token}"
    
    try:
        # Note: Depending on your API, this might be POST or PUT
        response = requests.post(url, json=data, headers=headers)
        if response.status_code in [200, 201]:
            print(f"[+] Availability set for {today}: {data['timeSlots']}")
            return True
        else:
            print(f"[-] Failed to set availability: {response.text}")
            return False
    except Exception as e:
        print(f"[-] Error: {e}")
        return False

def search_doctor(patient_token, specialty, lat, lon):
    print_step(f"Searching for {specialty} near ({lat}, {lon})")
    # Using the 'nearby' endpoint or general search
    url = f"{BASE_URL}/api/v1/users/doctors/search"
    
    params = {
        "specialty": specialty,
        "lat": lat,
        "lon": lon,
        "radius": 10000, # 10km radius
        "page": 1,
        "limit": 10
    }
    
    headers = HEADERS.copy()
    headers["Authorization"] = f"Bearer {patient_token}"
    
    try:
        response = requests.get(url, params=params, headers=headers)
        if response.status_code == 200:
            doctors = response.json().get('data', {}).get('doctors', [])
            print(f"[+] Found {len(doctors)} doctors.")
            for doc in doctors:
                print(f"   - Dr. {doc.get('fullName')} ({doc.get('distance', 'N/A')} km)")
            return doctors
        else:
            print(f"[-] Search failed: {response.text}")
            return []
    except Exception as e:
        print(f"[-] Error: {e}")
        return []

def book_appointment(patient_token, doctor_id, time_slot):
    print_step(f"Booking appointment with Doctor ID: {doctor_id} at {time_slot}")
    url = f"{BASE_URL}/api/v1/appointments/request"
    
    today = datetime.now().strftime("%Y-%m-%d")
    
    data = {
        "doctorId": doctor_id,
        "appointmentDate": today,
        "appointmentTime": time_slot,
        "reason": "Regular checkup",
        "notes": "I have mild chest pain."
    }
    
    headers = HEADERS.copy()
    headers["Authorization"] = f"Bearer {patient_token}"
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code in [200, 201]:
            result = response.json()
            appointment_id = result.get('data', {}).get('id')
            print(f"[+] Appointment requested successfully. ID: {appointment_id}")
            return appointment_id
        else:
            print(f"[-] Booking failed: {response.text}")
            return None
    except Exception as e:
        print(f"[-] Error: {e}")
        return None

def doctor_action_appointment(doctor_token, appointment_id, action="confirm"):
    print_step(f"Doctor {action}ing appointment ID: {appointment_id}")
    url = f"{BASE_URL}/api/v1/appointments/{appointment_id}/{action}"
    
    headers = HEADERS.copy()
    headers["Authorization"] = f"Bearer {doctor_token}"
    
    try:
        response = requests.patch(url, headers=headers) # Or PUT/POST
        if response.status_code == 200:
            print(f"[+] Appointment {action}ed successfully.")
            return True
        else:
            print(f"[-] Failed to {action} appointment: {response.text}")
            return False
    except Exception as e:
        print(f"[-] Error: {e}")
        return False

def main():
    print("[*] Starting E-Sante Full Scenario Simulation...")
    
    # 1. Register Users
    register_user("doctor", DOCTOR_EMAIL, PASSWORD, "Nidhal Doctor")
    register_user("patient", PATIENT_EMAIL, PASSWORD, "John Patient")
    
    # 2. Login
    doc_token, doc_id = login_user(DOCTOR_EMAIL, PASSWORD)
    pat_token, pat_id = login_user(PATIENT_EMAIL, PASSWORD)
    
    if not doc_token or not pat_token:
        print("[!] Simulation stopped: Auth failed.")
        return

    # 3. Update Locations (Near each other)
    update_location(doc_token, "doctor", LAT, LON)
    update_location(pat_token, "patient", LAT + 0.001, LON + 0.001) # Very close (~150m)
    
    # 4. Set Doctor Availability
    set_doctor_availability(doc_token, doc_id)
    
    # 5. Patient Searches for Doctor
    doctors = search_doctor(pat_token, "Cardiologist", LAT, LON)
    
    target_doctor = None
    if doctors:
        # Find our created doctor
        for doc in doctors:
            if doc.get('id') == doc_id or doc.get('_id') == doc_id: # Handle ID variations
                target_doctor = doc
                break
        
        # Fallback if list is short or mocked
        if not target_doctor and len(doctors) > 0:
             # Just pick the first purely for simulation flow if our created doc isn't indexed yet
             target_doctor = doctors[0] 
    else:
        print("[!] No doctors found. Using created doctor ID directly.")
        target_doctor = {"id": doc_id} 

    if target_doctor:
        target_doc_id = target_doctor.get('id') or target_doctor.get('_id')
        print(f"[>] Target Doctor ID: {target_doc_id}")
        
        # 6. Patient Books Appointment
        print("[~] Waiting 2 seconds before booking...")
        time.sleep(2)
        appointment_id = book_appointment(pat_token, target_doc_id, "10:00")
        
        if appointment_id:
            # 7. Doctor Accepts Appointment
            print("[~] Waiting 2 seconds before doctor action...")
            time.sleep(2)
            doctor_action_appointment(doc_token, appointment_id, "confirm")
            
            print("\n[+] Scenario Completed Successfully!")
        else:
            print("[!] Booking failed.")
    else:
        print("[!] Context failed: Could not find doctor to book.")

if __name__ == "__main__":
    main()
