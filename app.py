from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import datetime
import jwt
from functools import wraps
import hashlib
import os

app = Flask(__name__)
CORS(app, origins=["*"])

SECRET_KEY = 'campus-events-secret-key-2026'
DATABASE = 'campus_events.db'

def get_db():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    # Create users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            role TEXT DEFAULT 'student',
            created_at TEXT NOT NULL
        )
    ''')
    
    # Create events table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            location TEXT NOT NULL,
            capacity INTEGER NOT NULL,
            attendees INTEGER DEFAULT 0,
            status TEXT DEFAULT 'upcoming',
            imageUrl TEXT
        )
    ''')
    
    # Create rsvps table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS rsvps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            eventId INTEGER NOT NULL,
            userId INTEGER NOT NULL,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            studentId TEXT NOT NULL,
            status TEXT DEFAULT 'confirmed',
            timestamp TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users(id)
        )
    ''')
    
    # Create feedback table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS feedback (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            eventId INTEGER NOT NULL,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            rating INTEGER NOT NULL,
            comment TEXT NOT NULL,
            timestamp TEXT NOT NULL
        )
    ''')
    
    # Insert default admin if not exists
    cursor.execute("SELECT * FROM users WHERE email = 'admin@university.com'")
    if not cursor.fetchone():
        cursor.execute('''
            INSERT INTO users (name, email, password, role, created_at)
            VALUES (?, ?, ?, ?, ?)
        ''', ('Admin', 'admin@university.com', 
              hashlib.sha256('admin123'.encode()).hexdigest(), 
              'admin', datetime.datetime.now().isoformat()))
        print("✅ Admin created")
    
    # Insert default student if not exists
    cursor.execute("SELECT * FROM users WHERE email = 'student@university.com'")
    if not cursor.fetchone():
        cursor.execute('''
            INSERT INTO users (name, email, password, role, created_at)
            VALUES (?, ?, ?, ?, ?)
        ''', ('Student', 'student@university.com',
              hashlib.sha256('student123'.encode()).hexdigest(),
              'student', datetime.datetime.now().isoformat()))
        print("✅ Student created")
    
    # Insert sample events if none exist
    cursor.execute("SELECT COUNT(*) FROM events")
    if cursor.fetchone()[0] == 0:
        sample_events = [
            ('Tech Conference 2026', 'Biggest tech conference', '2026-04-15', '10:00 AM', 'Main Hall', 200, 145, 'upcoming', 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400'),
            ('Career Fair 2026', 'Meet recruiters', '2026-05-10', '11:00 AM', 'Gymnasium', 300, 278, 'upcoming', 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=400'),
            ('AI Ethics Lecture', 'Guest lecture', '2026-04-05', '2:00 PM', 'Room 201', 80, 62, 'upcoming', 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=400'),
            ('Sports Day', 'Annual sports', '2026-04-18', '9:00 AM', 'Sports Complex', 150, 98, 'upcoming', 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400'),
            ('Flutter Workshop', 'Coding workshop', '2026-04-12', '3:00 PM', 'CS Lab 3', 40, 38, 'upcoming', 'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=400')
        ]
        for event in sample_events:
            cursor.execute('''
                INSERT INTO events (title, description, date, time, location, capacity, attendees, status, imageUrl)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', event)
        print("✅ Sample events created")
    
    conn.commit()
    conn.close()
    print("✅ SQLite Database initialized successfully!")

# Initialize database on startup
init_db()

# Token helper function
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Token missing'}), 401
        try:
            token = token.split(' ')[1]
            decoded = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
            request.user = decoded
        except Exception as e:
            return jsonify({'error': 'Invalid token'}), 401
        return f(*args, **kwargs)
    return decorated

# Auth endpoints
@app.route('/auth/register', methods=['POST'])
def register():
    try:
        data = request.json
        conn = get_db()
        cursor = conn.cursor()
        
        # Check if user exists
        cursor.execute("SELECT * FROM users WHERE email = ?", (data['email'],))
        if cursor.fetchone():
            conn.close()
            return jsonify({'error': 'Email already registered'}), 400
        
        hashed = hashlib.sha256(data['password'].encode()).hexdigest()
        cursor.execute('''
            INSERT INTO users (name, email, password, role, created_at)
            VALUES (?, ?, ?, ?, ?)
        ''', (data['name'], data['email'], hashed, 'student', datetime.datetime.now().isoformat()))
        
        user_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return jsonify({
            'success': True, 
            'message': 'Registration successful',
            'user': {
                'id': user_id, 
                'name': data['name'], 
                'email': data['email'], 
                'role': 'student'
            }
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/auth/login', methods=['POST'])
def login():
    try:
        data = request.json
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM users WHERE email = ?", (data['email'],))
        user = cursor.fetchone()
        conn.close()
        
        if user:
            hashed = hashlib.sha256(data['password'].encode()).hexdigest()
            if user['password'] == hashed:
                token = jwt.encode({
                    'user_id': user['id'],
                    'email': user['email'],
                    'role': user['role'],
                    'exp': datetime.datetime.utcnow() + datetime.timedelta(days=1)
                }, SECRET_KEY)
                
                return jsonify({
                    'success': True,
                    'token': token,
                    'user': {
                        'id': user['id'],
                        'name': user['name'],
                        'email': user['email'],
                        'role': user['role']
                    }
                })
        
        return jsonify({'error': 'Invalid credentials'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Event endpoints
@app.route('/events', methods=['GET'])
def get_events():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM events")
    events = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(events)

@app.route('/events/<int:event_id>', methods=['GET'])
def get_event(event_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM events WHERE id = ?", (event_id,))
    event = cursor.fetchone()
    conn.close()
    if event:
        return jsonify(dict(event))
    return jsonify({'error': 'Event not found'}), 404

# RSVP endpoints
@app.route('/rsvps', methods=['POST'])
@token_required
def create_rsvp():
    try:
        data = request.json
        conn = get_db()
        cursor = conn.cursor()
        
        # Check if already registered
        cursor.execute('''
            SELECT * FROM rsvps 
            WHERE eventId = ? AND userId = ? AND status = 'confirmed'
        ''', (data['eventId'], request.user['user_id']))
        
        if cursor.fetchone():
            conn.close()
            return jsonify({'error': 'Already registered for this event'}), 400
        
        # Create RSVP
        cursor.execute('''
            INSERT INTO rsvps (eventId, userId, name, email, studentId, status, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (data['eventId'], request.user['user_id'], data['name'], data['email'], 
              data['studentId'], 'confirmed', datetime.datetime.now().isoformat()))
        
        # Update event attendees
        cursor.execute("UPDATE events SET attendees = attendees + 1 WHERE id = ?", (data['eventId'],))
        
        rsvp_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return jsonify({'success': True, 'id': rsvp_id, 'message': 'RSVP confirmed'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/my-rsvps', methods=['GET'])
@token_required
def get_my_rsvps():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM rsvps WHERE userId = ?", (request.user['user_id'],))
    rsvps = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(rsvps)

@app.route('/rsvps/<int:rsvp_id>', methods=['DELETE'])
@token_required
def cancel_rsvp(rsvp_id):
    try:
        conn = get_db()
        cursor = conn.cursor()
        
        # Get RSVP details
        cursor.execute("SELECT * FROM rsvps WHERE id = ? AND userId = ?", 
                      (rsvp_id, request.user['user_id']))
        rsvp = cursor.fetchone()
        
        if not rsvp:
            conn.close()
            return jsonify({'error': 'RSVP not found'}), 404
        
        # Update status
        cursor.execute("UPDATE rsvps SET status = 'cancelled' WHERE id = ?", (rsvp_id,))
        
        # Decrease event attendees
        cursor.execute("UPDATE events SET attendees = attendees - 1 WHERE id = ? AND attendees > 0", 
                      (rsvp['eventId'],))
        
        conn.commit()
        conn.close()
        
        return jsonify({'success': True, 'message': 'RSVP cancelled successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Feedback endpoint
@app.route('/feedback', methods=['POST'])
def create_feedback():
    try:
        data = request.json
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO feedback (eventId, name, email, rating, comment, timestamp)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (data['eventId'], data['name'], data['email'], data['rating'], 
              data['comment'], datetime.datetime.now().isoformat()))
        
        fb_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return jsonify({'success': True, 'id': fb_id, 'message': 'Feedback submitted'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Admin endpoints
@app.route('/admin/events', methods=['GET'])
@token_required
def admin_get_events():
    if request.user.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM events")
    events = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(events)

@app.route('/admin/events', methods=['POST'])
@token_required
def admin_create_event():
    if request.user.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    try:
        data = request.json
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO events (title, description, date, time, location, capacity, attendees, status, imageUrl)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (data['title'], data['description'], data['date'], data['time'], 
              data['location'], data['capacity'], 0, 'upcoming', data.get('imageUrl', '')))
        
        event_id = cursor.lastrowid
        conn.commit()
        
        cursor.execute("SELECT * FROM events WHERE id = ?", (event_id,))
        event = dict(cursor.fetchone())
        conn.close()
        
        return jsonify({'success': True, 'event': event}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/admin/events/<int:event_id>', methods=['PUT'])
@token_required
def admin_update_event(event_id):
    if request.user.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    try:
        data = request.json
        conn = get_db()
        cursor = conn.cursor()
        
        # Build update query
        updates = []
        values = []
        for key in ['title', 'description', 'date', 'time', 'location', 'capacity', 'imageUrl']:
            if key in data:
                updates.append(f"{key} = ?")
                values.append(data[key])
        
        if not updates:
            conn.close()
            return jsonify({'error': 'No fields to update'}), 400
        
        values.append(event_id)
        cursor.execute(f"UPDATE events SET {', '.join(updates)} WHERE id = ?", values)
        
        conn.commit()
        
        cursor.execute("SELECT * FROM events WHERE id = ?", (event_id,))
        event = dict(cursor.fetchone())
        conn.close()
        
        return jsonify({'success': True, 'event': event})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/admin/events/<int:event_id>', methods=['DELETE'])
@token_required
def admin_delete_event(event_id):
    if request.user.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM events WHERE id = ?", (event_id,))
        conn.commit()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Event deleted'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/admin/rsvps', methods=['GET'])
@token_required
def admin_get_rsvps():
    if request.user.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM rsvps")
    rsvps = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(rsvps)

@app.route('/admin/users', methods=['GET'])
@token_required
def admin_get_users():
    if request.user.get('role') != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email, role FROM users")
    users = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(users)

# Test endpoint
@app.route('/test', methods=['GET'])
def test():
    return jsonify({'message': 'SQLite version working!'})

if __name__ == '__main__':
    print("=" * 50)
    print("🚀 CAMPUS EVENTS API (SQLite Version)")
    print("=" * 50)
    print("📡 Running on http://127.0.0.1:5000")
    print("\n✅ SQLite is built into Python - no installation needed!")
    print("✅ Database file: campus_events.db")
    print("=" * 50)
    app.run(debug=True, host='0.0.0.0', port=5000)