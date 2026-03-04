import sqlite3
import random
import hashlib
from datetime import datetime, timedelta

print("=" * 60)
print("🎭 ADDING MORE FAKE USERS (SKIPPING DUPLICATES)")
print("=" * 60)

conn = sqlite3.connect('campus_events.db')
cursor = conn.cursor()

# Get existing emails
cursor.execute("SELECT email FROM users")
existing_emails = set(row[0] for row in cursor.fetchall())
print(f"📋 Found {len(existing_emails)} existing users")

# Fake student data
first_names = [
    'John', 'Sarah', 'Michael', 'Emma', 'David', 'Lisa', 'James', 'Maria', 
    'Robert', 'Anna', 'William', 'Jennifer', 'Charles', 'Patricia', 'Thomas',
    'Linda', 'Daniel', 'Elizabeth', 'Matthew', 'Susan', 'Anthony', 'Jessica',
    'Donald', 'Karen', 'Paul', 'Nancy', 'Mark', 'Margaret', 'George', 'Betty'
]

last_names = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 
    'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 
    'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
    'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez'
]

# Password for all fake users (hashed version of "password123")
default_password = hashlib.sha256('password123'.encode()).hexdigest()

# Create 20 new fake students (skipping existing emails)
new_count = 0
attempts = 0
max_attempts = 100

while new_count < 20 and attempts < max_attempts:
    attempts += 1
    
    # Generate random name
    first = random.choice(first_names)
    last = random.choice(last_names)
    name = f"{first} {last}"
    
    # Create email
    email = f"{first.lower()}.{last.lower()}@university.com"
    
    # Skip if email already exists
    if email in existing_emails:
        continue
    
    student_id = f"STU{2027000 + new_count}"
    created_at = (datetime.now() - timedelta(days=random.randint(1, 90))).isoformat()
    
    try:
        cursor.execute('''
            INSERT INTO users (name, email, password, role, created_at)
            VALUES (?, ?, ?, ?, ?)
        ''', (name, email, default_password, 'student', created_at))
        
        existing_emails.add(email)  # Add to set to avoid future duplicates
        new_count += 1
        print(f"  ✅ Added: {name} - {email}")
    except:
        continue

conn.commit()
print(f"\n✅ Successfully added {new_count} new students")

# Show total count
cursor.execute("SELECT COUNT(*) FROM users WHERE role='student'")
total = cursor.fetchone()[0]
print(f"📊 Total students now: {total}")

conn.close()
print("\n" + "=" * 60)
input("Press Enter to exit...")