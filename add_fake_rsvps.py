import sqlite3
import random
from datetime import datetime, timedelta

print("=" * 50)
print("ADDING FAKE RSVPS TO DATABASE")
print("=" * 50)

conn = sqlite3.connect('campus_events.db')
cursor = conn.cursor()

# First, clear existing RSVPs
cursor.execute("DELETE FROM rsvps")
print("✅ Cleared existing RSVPs")

# Get all users and events
cursor.execute("SELECT id FROM users WHERE role = 'student'")
students = cursor.fetchall()

cursor.execute("SELECT id, title FROM events")
events = cursor.fetchall()

if not students:
    print("❌ No students found. Creating test students...")
    for i in range(1, 21):  # Create 20 test students
        cursor.execute('''
            INSERT INTO users (name, email, password, role, created_at)
            VALUES (?, ?, ?, ?, ?)
        ''', (f'Student {i}', f'student{i}@university.com', 
              '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 
              'student', datetime.now().isoformat()))
    students = cursor.execute("SELECT id FROM users WHERE role = 'student'").fetchall()
    print(f"✅ Created {len(students)} test students")

# Fake student names for variety
first_names = ['John', 'Sarah', 'Michael', 'Emma', 'David', 'Lisa', 'James', 'Maria', 'Robert', 'Anna']
last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez']

# Target attendees per event
target_attendees = {
    1: 68,   # Tech Conference
    2: 120,  # Career Fair
    3: 45,   # AI Ethics Lecture
    4: 89,   # Sports Day
    5: 32    # Flutter Workshop
}

# Create RSVPs
rsvp_count = 0
for event_id, target in target_attendees.items():
    # Randomly select students to RSVP
    num_to_select = min(target, len(students))
    selected_students = random.sample(students, num_to_select)
    
    for i, (student_id,) in enumerate(selected_students):
        name = f"{random.choice(first_names)} {random.choice(last_names)}"
        email = f"{name.lower().replace(' ', '.')}@university.com"
        student_id_num = f"STU{1000 + i}"
        
        # Random timestamp in the last 30 days
        timestamp = (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat()
        
        cursor.execute('''
            INSERT INTO rsvps (eventId, userId, name, email, studentId, status, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (event_id, student_id, name, email, student_id_num, 'confirmed', timestamp))
        
        rsvp_count += 1
    
    # Update event attendees count
    cursor.execute("UPDATE events SET attendees = ? WHERE id = ?", (target, event_id))
    print(f"✅ Added {num_to_select} RSVPs to Event {event_id}")

conn.commit()

# Verify the data
print("\n" + "=" * 50)
print("📊 VERIFYING DATA")
print("=" * 50)

cursor.execute("SELECT id, title, attendees FROM events")
for row in cursor.fetchall():
    print(f"Event {row[0]}: {row[1]} - {row[2]} attendees")

print(f"\n✅ Total RSVPs created: {rsvp_count}")

conn.close()
print("\n🎉 Fake RSVPs added successfully!")
input("\nPress Enter to exit...")