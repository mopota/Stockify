```md
# 📦 Stockify - Inventory & Marketplace Management App

<p align="center">
  <img src="assets/logo.png" width="150" alt="Stockify Logo"/>
</p>

<p align="center">
A modern Inventory & Marketplace Management application built with <b>Flutter</b> and <b>Firebase</b>.
</p>

<p align="center">
<img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter"/>
<img src="https://img.shields.io/badge/Firebase-Backend-orange?logo=firebase"/>
<img src="https://img.shields.io/badge/Material%203-UI-green"/>
<img src="https://img.shields.io/badge/License-MIT-success"/>
</p>

---

# ✨ Features

## 🔐 Authentication

- Email & Password Authentication
- Email Verification
- Forgot Password
- Secure Session Management
- Firebase Authentication

---

## 👤 Profile & Settings

- Material 3 Modern UI
- Edit Profile Information
- Upload Profile Picture
- Cloudinary / Firebase Storage Integration
- Separate Account & App Settings
- Dark / Light Mode
- Arabic & English Languages (i18n)

---

## 🛍️ Marketplace

- Role Based Access Control (RBAC)
  - 👑 Admin
  - 🛒 Seller
  - 👤 Buyer

- Product Management
  - Add Products
  - Edit Products
  - Delete Products
  - Admin Approval System

- Advanced Search
- Categories Filter
- Favorites
- Shopping Cart

---

## 📦 Orders

- Shipping Addresses
- Order Tracking
- Order Status

```

Pending
Processing
Shipped
Delivered
Cancelled

````

---

## 💳 Payments

- Stripe Integration
- Secure Checkout
- Payment Methods
- Order History

---

# 🛠 Tech Stack

| Technology | Description |
|------------|-------------|
| Flutter | Cross Platform Framework |
| Firebase Auth | Authentication |
| Cloud Firestore | Database |
| Firebase Storage | File Storage |
| Flutter Bloc / Cubit | State Management |
| Material 3 | UI System |
| Shared Preferences | Local Storage |
| Hive | Offline Cache |
| Cached Network Image | Image Caching |
| Image Picker | Image Selection |
| Image Cropper | Image Editing |
| HTTP | REST APIs |

---

# 📸 Screenshots

| Home | Product | Cart |
|------|---------|------|
| ![](screenshots/home.png) | ![](screenshots/product.png) | ![](screenshots/cart.png) |

---

# 📂 Project Structure

```text
lib/
│
├── core/
│   ├── constants/
│   ├── services/
│   ├── themes/
│   ├── utils/
│   └── widgets/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── sources/
│
├── features/
│   ├── auth/
│   ├── home/
│   ├── products/
│   ├── cart/
│   ├── favorites/
│   ├── orders/
│   ├── profile/
│   ├── settings/
│   └── admin/
│
└── main.dart
````

---

# 🚀 Getting Started

## Clone Repository

```bash
git clone https://github.com/mopota/stockify.git
```

```bash
cd stockify
```

---

## Install Packages

```bash
flutter pub get
```

---

## Firebase Setup

1. Create a Firebase Project

2. Add Android Application

```
Package Name:
com.project1
```

3. Download

```
google-services.json
```

4. Place it inside

```
android/app/
```

5. Enable

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

---

## Run Application

```bash
flutter run
```

---

# 🧱 Architecture

```
Presentation
      │
      ▼
Cubit / Bloc
      │
      ▼
Repository
      │
      ▼
Firebase Services
      │
      ▼
Firestore / Storage / Auth
```

---

# 🌍 Localization

Supported Languages

* 🇬🇧 English
* 🇪🇬 العربية

---

# 🔒 Security

* Firebase Authentication
* Email Verification
* Firestore Security Rules
* Storage Rules
* Role-Based Access Control (RBAC)

---

# 🤝 Contributing

Contributions are always welcome!

1. Fork the repository

2. Create your feature branch

```bash
git checkout -b feature/AmazingFeature
```

3. Commit your changes

```bash
git commit -m "Add AmazingFeature"
```

4. Push to GitHub

```bash
git push origin feature/AmazingFeature
```

5. Open a Pull Request

---

# 📋 Roadmap

* [x] Authentication
* [x] Marketplace
* [x] Favorites
* [x] Shopping Cart
* [x] Orders
* [x] Stripe Payment
* [x] Firebase Backend
* [ ] Push Notifications
* [ ] Chat Between Buyers & Sellers
* [ ] Product Reviews
* [ ] Admin Dashboard
* [ ] Analytics

---

# 📄 License

This project is licensed under the **MIT License**.

---

# 👨‍💻 Developer

**Mohamed Taha**

📧 [mohamed.dio555@gmail.com](mailto:mohamed.dio555@gmail.com)

GitHub

```
https://github.com/your-username
```

---

# ⭐ Support

If you like this project, don't forget to leave a ⭐ on GitHub.

---

<p align="center">
Made with ❤️ using Flutter & Firebase
</p>
```




