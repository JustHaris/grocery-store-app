# 🛒 GroceryStore — Full-Stack eCommerce & Inventory Management System

> 🚀 A production-ready, enterprise-grade grocery marketplace built with Flask, SQL Server, and modern UI/UX principles.

---

## 📌 Project Overview

**GroceryStore** is a full-stack web application designed for the grocery and FMCG industry. It provides a seamless dual-interface system:

- 🛍 **Customer Marketplace** — Browse products, manage cart & wishlist, place orders
- 🧑‍💼 **Admin Dashboard** — Manage inventory, suppliers, and monitor business insights

This project was developed as a **7th Semester Database Administration & Management (DAM)** project, focusing heavily on **ACID compliance, normalization, and real-world architecture**.

---

## 🧠 Key Highlights

- ✅ ACID-compliant transaction handling (atomic checkout system)
- ✅ Fully normalized database (3NF)
- ✅ Role-Based Access Control (RBAC)
- ✅ Secure authentication (Werkzeug hashing)
- ✅ Optimized queries (N+1 problem solved using `joinedload`)
- ✅ Modern responsive UI (Dark/Light mode + glassmorphism)
- ✅ AJAX-powered cart system (no page reloads)
- ✅ Clean MVC-like Flask architecture

---

## 🛠 Tech Stack

### 🔙 Backend
- Python 3.x
- Flask 3.0
- SQLAlchemy (ORM)
- Werkzeug (Security)

### 🗄 Database
- Microsoft SQL Server (SSMS)
- pyodbc (DB driver)

### 🎨 Frontend
- HTML5, CSS3
- Bootstrap 5
- Vanilla JavaScript (ES6+)
- Chart.js (Admin analytics)

---

## 📂 Project Structure

```
GSA/
│
├── app/
│   ├── __init__.py       # App configuration & DB connection
│   ├── models.py         # ORM Models (7 tables)
│   └── routes.py         # All application routes
│
├── database/
│   ├── schema.sql        # Tables & constraints
│   ├── triggers.sql      # Data integrity triggers
│   ├── procedures.sql    # Stored procedures
│   └── views.sql         # Reporting views
│
├── static/
│   ├── style.css         # Custom design system
│   ├── main.js           # Client-side logic
│   └── images/           # Assets
│
├── templates/            # Jinja2 HTML templates
│
├── run.py                # Entry point
└── requirements.txt      # Dependencies
```

---

## 🔐 Core Features

### 👤 Authentication
- Secure login & signup
- Password hashing using Werkzeug
- Session-based authentication

---

### 🛍 Customer Features
- Product browsing with:
  - 🔍 Search
  - 🗂 Category filtering
  - ↕ Sorting
- 🛒 Cart system (AJAX-based)
- ❤️ Wishlist management
- 📦 Order placement (atomic transaction)
- 🧾 Invoice generation
- 📜 Order history tracking

---

### 🧑‍💼 Admin Features
- 📊 Dashboard with analytics (Chart.js)
- 📦 Inventory management (CRUD)
- ⚠ Low stock alerts
- 🚚 Supplier management system
- 🔐 Role-based access control

---

## 🗄 Database Design

### Tables:
- Users
- Categories
- Products
- Orders
- OrderItems
- Wishlist
- Suppliers

### Key Concepts:
- ✔ Foreign key relationships
- ✔ CHECK constraints (price ≥ 0, stock ≥ 0)
- ✔ Unique constraints
- ✔ Indexed queries for performance

---

## ⚙️ ACID Compliance

| Property | Implementation |
|--------|-------------|
| Atomicity | Transaction rollback on failure |
| Consistency | Constraints & validations |
| Isolation | SQL Server default isolation |
| Durability | Persistent DB storage |

---

## ⚡ Performance Optimizations

- 🔥 Solved N+1 Query Problem using:
  ```python
  joinedload(Product.category)
  ```
- 📉 Reduced DB queries drastically
- ⚡ Efficient indexing on key columns

---

## 🎨 UI/UX Features

- 🌙 Dark / Light Mode
- 🧊 Glassmorphism design
- 📱 Fully responsive layout
- 🎯 Smooth animations (IntersectionObserver)
- 🔔 Toast notifications (AJAX feedback)

---

## 🐛 Major Problems Solved

- ❌ Double stock deduction (trigger vs Flask)
- ❌ N+1 query issue
- ❌ Modal UI freeze (z-index issue)
- ❌ Admin role security vulnerability
- ❌ Header layout bugs
- ❌ Duplicate JS loading

---

## 🚀 How to Run Locally

```bash
# Clone repo
git clone https://github.com/JustHaris/grocery-store-app.git

# Go to project folder
cd grocery-store-app

# Create virtual environment
python -m venv .venv
.\.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run app
python run.py
```

App will run at:
http://127.0.0.1:5000

---

## 🔑 Test Credentials

Admin:
Email: admin@gmail.com
Password: admin123

---

## ⚠️ Known Limitations

- ❗ Local SQL Server dependency (not cloud deployed)
- ❗ No payment gateway integration
- ❗ Basic invoice system (non-PDF)
- ❗ Limited scalability without pagination

---

## 📈 Future Enhancements

- 🌐 Cloud deployment (Azure / AWS)
- 💳 Payment integration (Stripe / JazzCash)
- 📊 Advanced analytics dashboard
- 📦 REST API / mobile app support
- 🐳 Docker containerization

---

## 🏆 Final Outcome

This project successfully demonstrates:

- ✔ Real-world full-stack development
- ✔ Strong database design (DAM concepts)
- ✔ Secure authentication & RBAC
- ✔ Production-level UI/UX
- ✔ Performance optimization techniques

---

## 👨‍💻 Author

**Haris Khan**  
BS Information Technology — 7th Semester  

---

## 📜 License

This project is developed for educational purposes.
