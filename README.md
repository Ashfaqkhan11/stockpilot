# 📦 StockPilot - Inventory Management System

> A complete real-time inventory management solution built with Flutter, Supabase, and GetX - designed for small businesses to track stock, sales, purchases, and profits.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![GetX](https://img.shields.io/badge/GetX-8A2BE2?style=for-the-badge)

## 🚀 Live Demo
- **APK:** [Download Latest Release](https://github.com/Ashfaqkhan11/stockpilot-inventory-management/releases)
- **Video Demo:** [Watch on Loom / Drive](#)

## ✨ Features

### 1. Dashboard (Real-time)
- Total Products, Total Sales, Total Purchases, Total Profit
- Live stock value calculation
- User-wise data isolation

### 2. Products Management
- CRUD operations with image upload (Supabase Storage)
- Purchase Price & Sale Price tracking
- Stock quantity management

### 3. Inventory
- Low-stock alerts (< 10) with pulse animation
- Live updates via Supabase Realtime
- Search and filter products

### 4. Sales
- Auto stock decrease on sale
- **Profit auto-calculation:** `(sale_price - purchase_price) * quantity`
- Product name & user tracking

### 5. Purchases
- Auto stock increase on purchase
- Supplier linking
- Total amount calculation

### 6. History (Live Timeline)
- Combined Sales + Purchases timeline
- Shows Profit for every sale: `Profit: Rs X`
- Real-time updates using `stream(primaryKey: ['id'])`
- Fallback logic for old records using productMap

### 7. Suppliers
- Full CRUD for suppliers
- Contact management

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter 3.x |
| State Management | GetX |
| Backend | Supabase (Postgres, Auth, Storage, Realtime) |
| Architecture | MVC + GetX Bindings |
| Auth | Supabase Auth (Row Level Security) |

## 📸 Screenshots

| Dashboard | Inventory | Sales |
|-----------|-----------|-------|
|![Dashboard](screenshots/dashboard.png) |![Inventory](screenshots/inventory.png) |![Sales](screenshots/sales.png) |

| History with Profit | Add Product | Suppliers |
|---------------------|-------------|-----------|
|![History](screenshots/history.png) |![Add](screenshots/add_product.png) |![Suppliers](screenshots/suppliers.png) |

## 📊 Database Schema

**products**
```sql
id uuid PK, name text, quantity int, purchase_price numeric,
sale_price numeric, image_url text, user_id uuid FK