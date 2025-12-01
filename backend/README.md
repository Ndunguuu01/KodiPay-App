# KodiPay Backend

Node.js backend for the KodiPay Real Estate Application.

## Setup

1.  **Install Dependencies**:
    ```bash
    npm install
    ```

2.  **Database Configuration**:
    - Create a MySQL database named `kodipay_db`.
    - Update the `.env` file with your MySQL credentials:
        ```
        DB_HOST=localhost
        DB_USER=root
        DB_PASSWORD=your_password
        DB_NAME=kodipay_db
        ```

3.  **Run Server**:
    ```bash
    node server.js
    ```
    or for development:
    ```bash
    npm run dev
    ```

## API Endpoints

- **Auth**:
    - `POST /api/auth/register` - Register a new user
    - `POST /api/auth/login` - Login and get JWT

- **Properties**:
    - `POST /api/properties` - Create a property (Landlord only)
    - `GET /api/properties` - List properties

- **Payments**:
    - `POST /api/payments` - Make a payment
    - `GET /api/payments` - List payments

- **Messages**:
    - `POST /api/messages` - Send a message
    - `GET /api/messages` - Get messages
