# MaatriCare / PregaCare
**Your Intelligent Maternal Healthcare Companion**

## 1. Executive Summary
**Problem being solved:** Maternal healthcare often suffers from fragmented information, lack of immediate emergency response, and insufficient emotional/partner support during pregnancy.
**Target users:** Expectant mothers and their partners.
**Why this problem matters:** Ensuring the health, safety, and emotional well-being of pregnant women is critical. Delays in emergency response or lack of proper tracking can lead to severe complications.
**High-level solution:** MaatriCare is a comprehensive, Flutter-based maternal healthcare companion that integrates health tracking, intelligent emergency SOS, educational resources, and a unique shared partner journey.

## 2. Key Features
- **Intelligent Emergency SOS:** A 2-second hold gesture to trigger SOS, share live GPS, and contact primary care. Prevent accidental triggers.
- **Comprehensive Health Tracking:** Logs for medication, emotional wellness, baby monitoring, and medical records.
- **Shared Partner Journey:** Allows partners to connect and engage in the pregnancy journey.
- **Knowledge Hub & Education:** Curated resources for maternal care.
- **Appointment & Schedule Management:** Keep track of doctor visits.
- **Glassmorphism UI:** A highly polished, modern, and soothing interface for an exceptional user experience.

## 3. Technical Stack
- **Frontend:** Flutter, Dart, GoRouter
- **Backend & Cloud:** Firebase (Auth, Firestore, Storage, Messaging)
- **State Management:** Provider, flutter_bloc
- **Hardware Integration:** Geolocator (Live GPS), Local Notifications

## 4. Installation and Setup Guide
### Prerequisites
- Flutter SDK (^3.10.4)
- Dart SDK
- Firebase Project setup

### Environment setup
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Configure your Firebase project and ensure `firebase_options.dart` is correctly set up.
4. Run `flutter run` to launch the application.

---
**For the complete, in-depth technical analysis, architecture diagrams, and hackathon judging details, please see [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md).**
