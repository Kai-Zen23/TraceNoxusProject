# TraceNoxus

TraceNoxus is a comprehensive social collaboration platform built with Flutter. It facilitates community connection and collaboration through robust team management, real-time messaging, and event organization features.

## Key Features

### 🔐 Authentication & Security
- **Secure Onboarding**: Full user registration and login flows.
- **Account Security**: OTP-based password reset and secure token storage.
- **Profile Management**: Customize details and view other user profiles.

### 💬 Communication & Social
- **Real-time Chat**:
    - **General Chat**: Public interactive space.
    - **Private Messaging**: One-on-one conversations.
    - **Team Chat**: Focused group discussions.
- **Friend Network**: Manage friends and handle friend requests.

### 🚀 Teams & Collaboration
- **Team Hubs**: Create and manage teams with dedicated dashboards.
- **Collaboration**: Specialized tools for team-based interaction.

### 📅 Events & Engagement
- **Interactive Calendar**: Track and manage schedules.
- **Event Management**: Create and host events.
- **Announcements**: Centralized system for important updates.

### ⚙️ Admin & Control
- **Admin Dashboard**: High-level view of app activity and metrics.
- **User Management**: Administrative tools for observing and managing users.

## Tech Stack

This project leverages a robust modern stack:
- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: Dart
- **State Management**: `provider`
- **Networking**: `dio`, `http`, `web_socket_channel`
- **Storage**: `flutter_secure_storage`, `shared_preferences`
- **Media**: `video_player`, `audioplayers`, `cached_network_image`
- **Utils**: `intl`, `flutter_dotenv`

## Getting Started

### Prerequisites
- Flutter SDK (>=3.16.0)
- Dart SDK (>=3.2.3)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd TraceNoxus-FrontEnd
   ```

2. **Setup Environment**
   Ensure you have a `.env` file configured if required by `flutter_dotenv`.

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure

- **`lib/screens`**: Contains all UI pages (Auth, Chat, Teams, Dashboard, etc.).
- **`lib/providers`**: State management and business logic.
- **`lib/services`**: Backend API integration services.
- **`lib/models`**: Data models and JSON serialization.
- **`lib/widgets`**: Reusable UI components.
