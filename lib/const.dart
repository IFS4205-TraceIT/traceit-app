// TraceIT server URL
// TODO: Replace with TraceIT server URL
const String serverUrl = 'http://10.0.2.2:8080';

// Authentication routes
const String routeRegister = '$serverUrl/auth/register';
const String routeLogin = '$serverUrl/auth/login';
const String routeRefresh = '$serverUrl/auth/refresh';
const String routeLogout = '$serverUrl/auth/logout';
const String routeTotpRegister = '$serverUrl/auth/totp/register';
const String routeTotpLogin = '$serverUrl/auth/totp';

// Temp ID routes
const String routeTempId = '$serverUrl/contacts/temp_id';

// Contact status and upload routes
const String routeContactStatus = '$serverUrl/contacts/status';
const String routeContactUploadStatus = '$serverUrl/contacts/upload/status';
const String routeContactUpload = '$serverUrl/contacts/upload';

// Bluetooth exchange
const String serviceUuid = 'bf27730d-860a-4e09-889c-2d8b6a9e0fe7';
const String characteristicUuid = '7f20e8d6-b4f8-4148-8bfa-4ce6b0e270ea';
const String closeContactBroadcastKey = 'closeContactCount';
