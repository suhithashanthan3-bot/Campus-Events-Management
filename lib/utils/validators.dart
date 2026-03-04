class Validators {
  // Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    // Check if contains only letters and spaces
    final nameRegExp = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegExp.hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Simple email regex
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    // Check for university email (optional but good)
    if (!value.contains('@') || value.split('@')[1].isEmpty) {
      return 'Email must have a valid domain';
    }
    return null;
  }

  // Validate student ID
  static String? validateStudentId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Student ID is required';
    }
    if (value.length < 5) {
      return 'Student ID must be at least 5 characters';
    }
    if (value.length > 20) {
      return 'Student ID must be less than 20 characters';
    }
    // Alphanumeric + common separators
    final studentIdRegExp = RegExp(r'^[a-zA-Z0-9\-_]+$');
    if (!studentIdRegExp.hasMatch(value)) {
      return 'Student ID can only contain letters, numbers, - and _';
    }
    return null;
  }

  // Validate rating (for feedback)
  static String? validateRating(int? value) {
    if (value == null) {
      return 'Please select a rating';
    }
    if (value < 1 || value > 5) {
      return 'Rating must be between 1 and 5';
    }
    return null;
  }

  // Validate comment (for feedback)
  static String? validateComment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your feedback';
    }
    if (value.length < 5) {
      return 'Feedback must be at least 5 characters';
    }
    if (value.length > 500) {
      return 'Feedback must be less than 500 characters';
    }
    return null;
  }
}