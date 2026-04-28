# Tengdosh Ecosystem (User & Pro)

Modern Flutter application architecture designed for a dual-app ecosystem: **Tengdosh** (Students) and **Tengdosh Pro** (Staff/Teachers).

## 🏗 Architecture: Clean-Core Strategy
The project follows a modular architecture to maximize logic reuse:
- `lib/core/`: Shared logic, networking (Dio), storage, and global models.
- `lib/features/shared/`: Common features like Auth and Profile.
- `lib/apps/user/`: Student-specific UI and entry point.
- `lib/apps/pro/`: Staff-specific UI and entry point.

---

## 🚀 Future-Proof Architecture Guide

### 1. Adding a Third App (e.g., Tengdosh Parent / Admin-Web)
Tengdosh is built on a **Shared-Core** modularity. To add a new application:
- **Entry Point:** Create a new directory in `lib/apps/{new_app}/` with its own `main_{new_app}.dart` and `root_app.dart`.
- **Logic Reuse:** Import existing features from `lib/features/shared/` and core logic from `lib/core/`.
- **Strategy Injection:** Define a new `IAuthRepository` implementation if the new app uses a different auth provider (e.g., ParentID).
- **Initialization:**
  ```bash
  flutter run -t lib/apps/new_app/main_new_app.dart
  ```

### 2. Firebase Push Notifications (Dual-App Strategy)
To handle notifications across both User and Pro apps:
- **Project Structure:** Use a single Firebase Project with two Android/iOS apps to share the same notification topics.
- **Dynamic Channels:** Use the `university_prefix` as a topic name (e.g., `/topics/tuit_all`, `/topics/tuit_staff`).
- **Token Management:** Store the FCM token alongside the JWT in the `AuthService`. When switching university servers, re-subscribe to the new prefix-based topic.

### 3. Multi-University JWT Security Protocol
Our `ApiClient` uses a specialized interceptor for multi-tenancy security:
- **Isolation:** Each university server (`{prefix}.tengdosh.uz`) only accepts tokens signed by its own secret or the Central OAuth2 Issuer.
- **Interception:** The `ApiClient` automatically injects the `Authorization` header. If a 401 (Unauthorized) is received, the app must clear the local cache and re-route the user back to the Central Login to prevent "cross-university" data leaks.
- **Validation:** Always verify the `iss` (Issuer) and `aud` (Audience) claims in the JWT on the backend to ensure the token belongs to the current university server.

---

## 🛠 Commands
- **Run User App:** `flutter run -t lib/apps/user/main_user.dart`
- **Run Pro App:** `flutter run -t lib/apps/pro/main_pro.dart`

---

Built with ❤️ by Antigravity & The Tengdosh Team.
🚀 Terminating Session... Success.
