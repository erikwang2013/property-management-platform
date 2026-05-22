<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * English language pack — Admin Panel
 */

return [
    // General
    'success' => 'Operation successful',
    'fail' => 'Operation failed',
    'not_found' => 'Resource not found',
    'unauthorized' => 'Not logged in',
    'forbidden' => 'No permission',
    'token_expired' => 'Token expired or invalid',
    'token_invalid' => 'Token revoked, please login again',
    'too_many_requests' => 'Too many requests, please try again later',
    'account_locked' => 'Account locked, please try again later',
    'account_disabled' => 'Account disabled',
    'server_error' => 'Internal server error',
    'validation_failed' => 'Validation failed',
    'password_required' => 'Password required for sensitive operation',
    'password_wrong' => 'Password verification failed',
    'delete_success' => 'Deleted successfully',
    'create_success' => 'Created successfully',
    'update_success' => 'Updated successfully',

    // Auth
    'auth.login_success' => 'Login successful',
    'auth.username_required' => 'Username and password are required',
    'auth.credentials_wrong' => 'Incorrect username or password',
    'auth.captcha_wrong' => 'Captcha verification failed',
    'auth.logout_success' => 'Logged out',
    'auth.password_min_length' => 'Password must be at least 6 characters',
    'auth.old_password_wrong' => 'Old password is incorrect',
    'auth.password_changed' => 'Password changed successfully',
    'auth.phone_exists' => 'This phone number is already registered',
    'auth.phone_password_required' => 'Phone and password are required',
    'auth.register_success' => 'Registration successful',

    // Community
    'community.name_required' => 'Community name is required',
    'community.not_found' => 'Community not found',

    // Owner
    'owner.not_found' => 'Owner not found',

    // Fee
    'fee.bill_not_found' => 'Bill not found',
    'fee.bill_paid' => 'This bill has been paid or exempted',
    'fee.pay_success' => 'Payment successful',
    'fee.invalid_bill' => 'Invalid bill information',

    // Repair
    'repair.not_found' => 'Repair order not found',
    'repair.description_required' => 'Please describe the issue',
    'repair.submit_success' => 'Repair request submitted',
    'repair.cancelled' => 'Cancelled',
    'repair.cancel_forbidden' => 'Only pending repairs can be cancelled',
    'repair.room_invalid' => 'Invalid property information',
    'repair.rating_range' => 'Rating must be between 1 and 5',
    'repair.rate_forbidden' => 'Only completed repairs can be rated',
    'repair.rate_success' => 'Rating submitted',
    'repair.no_permission' => 'Property not found or access denied',

    // Complaint
    'complaint.not_found' => 'Complaint not found',
    'complaint.title_content_required' => 'Title and content are required',
    'complaint.submit_success' => 'Submitted successfully',
    'complaint.rate_forbidden' => 'Only resolved complaints can be rated',
    'complaint.satisfaction_success' => 'Rating submitted',

    // File
    'file.upload_success' => 'Upload successful',
    'file.upload_failed' => 'Upload failed',

    // Export
    'export.excel_success' => 'Excel export successful',
    'export.pdf_success' => 'PDF export successful',
];
