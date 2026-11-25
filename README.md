# Nexus Omni — Flutter Web Frontend

[![Live Demo](https://img.shields.io/badge/Live_Demo-PythonAnywhere-2ea44f?style=for-the-badge)](https://aaronglamour.pythonanywhere.com)
[![Frontend](https://img.shields.io/badge/Frontend-Flutter_Web-02569B?style=for-the-badge)](https://github.com/AaronGLamour/nexus-omni-frontend)
[![Backend](https://img.shields.io/badge/Backend-Python_Flask_&_Waitress-blue?style=for-the-badge)](https://github.com/AaronGLamour/nexus-omni-backend)

Responsive Arabic-first **Flutter Web** client interface for **Nexus Omni**, featuring token-based authentication, real-time search and filtering, full CRUD operations, and JSON/CSV data portability.

## Live Production App
Try the live deployed application directly in your browser:
**[https://aaronglamour.pythonanywhere.com](https://aaronglamour.pythonanywhere.com)**

## Architecture & Integration
- **API Service (lib/api_service.dart):** Communicates securely with the Flask REST API using Bearer tokens.
- **Dynamic Configuration (lib/api_config.dart):** Automatically adapts to both local development (127.0.0.1:5000) and cloud production (aronglamour.pythonanywhere.com).
- **Production Bundle:** Compiled via lutter build web and bundled directly inside the [nexus-omni-backend](https://github.com/AaronGLamour/nexus-omni-backend) repository for zero-configuration deployment.

## Build From Source
1. Install dependencies: lutter pub get
2. Run locally: lutter run -d chrome
3. Build production web bundle: lutter build web --release
