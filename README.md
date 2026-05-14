# Genç Cüzdan

Genç Cüzdan is a cross-platform mobile budgeting application designed to improve financial literacy among young adults. It focuses on helping students and early-career users build sustainable saving habits through simple budgeting, visual goal tracking, and accessible financial tools.

This project was developed as a bachelor's thesis at Aydın Adnan Menderes University, Computer Engineering Department.

---

## Purpose

Many finance applications assume users already understand budgeting concepts, investment terminology, and financial planning. That creates a barrier for younger users who are managing money independently for the first time.

Genç Cüzdan addresses this by offering:

- Simple expense and income tracking
- Goal-based saving system
- Visual progress indicators
- Low-friction interface
- Gamified motivation features

The goal is not advanced finance management. The goal is habit formation.

---

## Screenshots

### Main Page

![Main](Screenshots/Main_goal.png)

### Wallet

![Wallet](Screenshots/Wallet_dashboard.png)

### Profile

![Profile](Screenshots/Profile_badges.png)

---

## Core Features

### Financial Tracking

- Add income and expense records
- Categorize transactions
- Track monthly financial summary
- Record recurring expenses
- Quick-add saved expense templates

### Savings Goals

- Create personal savings targets
- Assign custom icons and colors
- Track contribution progress
- Separate active and completed goals
- Progress visualization through charts and radial indicators

### Asset Management

- Track multiple asset types:
  - Turkish Lira
  - USD
  - EUR
  - Gold
- View total assets
- Analyze savings against personal goals

### User Engagement

- Achievement badge system
- Milestone rewards
- Progress-based retention mechanics

---

## Technology Stack

### Frontend

- Flutter
- Dart

Chosen for single-codebase deployment on both Android and iOS. Flutter enables responsive UI rendering and smooth visual interactions.

### Backend

- FastAPI
- Python
- Pydantic

Provides REST API endpoints, schema validation, and asynchronous request handling.

### Database

- PostgreSQL
- SQLAlchemy ORM

Used for transactional persistence and relational integrity.

Deployment is self-hosted with Cloudflare Tunnel for secure public access without exposing server ports.

---

## Client-server architecture:

```text
Flutter Mobile App
        ↓
HTTPS (TLS)
        ↓
Cloudflare Tunnel
        ↓
FastAPI Backend
        ↓
SQLAlchemy ORM
        ↓
PostgreSQL Database
