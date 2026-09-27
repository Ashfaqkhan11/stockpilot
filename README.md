# StockPilot

An Inventory & Purchase Management application built with **Flutter**, **GetX**, and **Supabase**, following the **MVC architectural pattern**.

## Overview

StockPilot helps businesses manage products, suppliers, purchase orders, and inventory in real time. It includes authentication, a business insights dashboard, automatic stock updates from purchase activity, and full inventory history tracking.

## Tech Stack

- **Flutter** — cross-platform UI
- **GetX** — routing, dependency injection (bindings), and state management
- **Supabase** — Authentication, Database (Postgres), Storage, and Realtime
- **Architecture** — MVC (Model–View–Controller)

## Features

- User authentication with persistent sessions
- Dashboard with key business insights
- Product management with image upload
- Supplier management
- Purchase order creation and management
- Automatic inventory updates on purchase activity
- Inventory history and stock movement tracking
- Search, filter, and sort across modules
- Realtime updates via Supabase Realtime
- Loading, empty, and error states throughout
- Pull-to-refresh support

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── routes/              # GetX route definitions (app_pages.dart, app_routes.dart)
│   ├── bindings/             # Global/initial bindings
│   └── theme/                 # App-wide theming
├── modules/
│   ├── auth/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── bindings/
│   ├── dashboard/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── bindings/
│   ├── products/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── bindings/
│   ├── suppliers/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── bindings/
│   ├── purchase_orders/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── views/
│   │   └── bindings/
│   └── inventory/
│       ├── controllers/
│       ├── models/
│       ├── views/
│       └── bindings/
├── data/
│   ├── services/              # Supabase auth, db, storage, realtime services
│   ├── repositories/          # Data access layer between controllers and Supabase
│   └── models/                # Shared data models
├── shared/
│   ├── widgets/               # Reusable UI components
│   └── utils/                 # Helpers, validators, formatters
└── constants/                  # App constants, strings, asset paths
```


## Architecture Notes

- **Model** — plain Dart classes representing entities (Product, Supplier, PurchaseOrder, InventoryMovement, etc.), typically with `fromJson`/`toJson` for Supabase.
- **View** — Flutter widgets, kept free of business logic; they observe controller state via GetX (`Obx`/`GetBuilder`).
- **Controller** — GetX controllers holding state and business logic, injected via **Bindings** so each screen lazily loads only what it needs.
- **Repository/Service layer** — Supabase calls (auth, database, storage, realtime) are wrapped in a service/repository layer rather than called directly from controllers, keeping data access testable and swappable.
- **Realtime** — Supabase Realtime subscriptions are managed centrally (e.g. in a dedicated service) to avoid duplicate listeners across screens.

> Replace the bullet points above with the actual decisions you made if they differ.

## Setup & Installation

### Prerequisites

- Flutter SDK (version X.X.X or higher)
- Dart SDK
- A Supabase account/project
- Android Studio / Xcode (for emulators) or a physical device

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd stockpilot
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment variables

Create a `.env` file in the project root (or configure `lib/constants/supabase_config.dart`, depending on your setup):

```
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

> Never commit real keys. Add `.env` to `.gitignore`.

### 4. Set up the Supabase project

1. Create a new project at [supabase.com](https://supabase.com).
2. Run the SQL scripts in `/supabase/schema.sql` (or your migrations folder) to create the required tables: `products`, `suppliers`, `purchase_orders`, `purchase_order_items`, `inventory_movements`, etc.
3. Enable **Row Level Security (RLS)** and add policies as needed.
4. Create a Storage bucket (e.g. `product-images`) for product image uploads and set the appropriate access policy.
5. Enable **Realtime** on the relevant tables (e.g. `products`, `inventory_movements`) from the Supabase dashboard.

### 5. Run the app

```bash
flutter run
```

## Demo Video

A short demonstration video covering core features and architectural decisions is available here: **[insert video link]**

## Assumptions Made

- [List any assumptions you made, e.g. "Each purchase order automatically increases stock quantity for its line items upon confirmation."]
- [e.g. "Only authenticated users can access any module; no guest mode."]
- [Add/remove as relevant to your implementation.]

## Known Limitations / Future Improvements

- [e.g. "No offline support yet — requires an active connection for Supabase calls."]
- [e.g. "Pagination not yet implemented on large product lists."]

## License

This project was built as a technical assignment and is not licensed for production use.
