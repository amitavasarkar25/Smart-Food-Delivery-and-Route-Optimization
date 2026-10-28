
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="jakarta.servlet.http.HttpServletResponse" %>

<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String role = String.valueOf(session.getAttribute("userRole"));

    if (!"CUSTOMER".equalsIgnoreCase(role)) {
        if ("ADMIN".equalsIgnoreCase(role)) {
            response.sendRedirect(
                request.getContextPath() + "/admin/dashboard"
            );
        } else {
            response.sendError(
                HttpServletResponse.SC_FORBIDDEN,
                "Customer access required."
            );
        }
        return;
    }

    String userName = (String) session.getAttribute("userName");

    if (userName == null || userName.trim().isEmpty()) {
        userName = "Customer";
    }

    String safeName = userName.replace("&", "&amp;")
                              .replace("<", "&lt;")
                              .replace(">", "&gt;")
                              .replace("\"", "&quot;")
                              .replace("'", "&#39;");

    String context = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Customer Dashboard | SmartFoodDelivery</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            background: #f4f7f5;
            color: #26332a;
        }

        header {
            background: #218838;
            color: white;
            padding: 18px 6%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }

        .brand {
            font-size: 23px;
            font-weight: bold;
        }

        .nav-links {
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 18px;
        }

        header a {
            color: white;
            text-decoration: none;
            font-weight: bold;
        }

        header a:hover {
            text-decoration: underline;
        }

        .container {
            max-width: 1150px;
            margin: 35px auto;
            padding: 0 20px;
        }

        .welcome {
            background: white;
            padding: 32px;
            border-radius: 14px;
            box-shadow: 0 3px 15px rgba(0, 0, 0, 0.06);
            margin-bottom: 30px;
            border-left: 5px solid #218838;
        }

        .welcome h1 {
            margin-top: 0;
            color: #218838;
        }

        .welcome p {
            color: #666;
            line-height: 1.7;
            margin-bottom: 0;
        }

        .section-title {
            margin: 30px 0 18px;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(
                auto-fit,
                minmax(225px, 1fr)
            );
            gap: 20px;
        }

        .card {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 3px 15px rgba(0, 0, 0, 0.06);
            display: flex;
            flex-direction: column;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 22px rgba(0, 0, 0, 0.09);
        }

        .card .icon {
            font-size: 36px;
            margin-bottom: 8px;
        }

        .card h3 {
            margin: 8px 0;
            color: #26332a;
        }

        .card p {
            color: #666;
            line-height: 1.6;
            flex-grow: 1;
        }

        .card a {
            display: inline-block;
            align-self: flex-start;
            margin-top: 12px;
            background: #218838;
            color: white;
            padding: 11px 16px;
            border-radius: 6px;
            text-decoration: none;
            font-weight: bold;
        }

        .card a:hover {
            background: #19692c;
        }

        .track-card {
            border-top: 4px solid #218838;
        }

        footer {
            text-align: center;
            padding: 25px;
            color: #777;
            margin-top: 25px;
        }

        @media (max-width: 500px) {
            .welcome {
                padding: 23px;
            }

            .brand {
                font-size: 20px;
            }

            .nav-links {
                gap: 12px;
            }
        }
    </style>
</head>

<body>

<header>
    <div class="brand">🍽️ SmartFoodDelivery</div>

    <nav class="nav-links">
        <a href="<%= context %>/food/menu">Browse Food</a>
        <a href="<%= context %>/orders">My Orders</a>
        <a href="<%= context %>/logout">Logout</a>
    </nav>
</header>

<main class="container">

    <section class="welcome">
        <h1>Welcome, <%= safeName %>! 👋</h1>

        <p>
            Welcome to your customer dashboard. Discover delicious food,
            manage your cart, track your orders, and enjoy a convenient
            food delivery experience.
        </p>
    </section>

    <h2 class="section-title">Your Dashboard</h2>

    <div class="grid">

        <!-- Card 1: Browse Food -->
        <div class="card">
            <div class="icon">🍕</div>
            <h3>Browse Food</h3>
            <p>
                Explore our menu and discover your next favourite meal.
            </p>
            <a href="<%= context %>/food/menu">Browse Menu</a>
        </div>

        <!-- Card 2: My Cart -->
        <div class="card">
            <div class="icon">🛒</div>
            <h3>My Cart</h3>
            <p>
                View your selected items, adjust quantities, and prepare
                your order for checkout.
            </p>
            <a href="<%= context %>/cart">View Cart</a>
        </div>

        <!-- Card 3: My Orders -->
        <div class="card">
            <div class="icon">📦</div>
            <h3>My Orders</h3>
            <p>
                Review your previous orders, order totals, and payment details.
            </p>
            <a href="<%= context %>/orders">View Orders</a>
        </div>

        <!-- Card 4: Track My Orders -->
        <div class="card track-card">
            <div class="icon">🚚</div>
            <h3>Track My Orders</h3>
            <p>
                Follow your order status from placement and food preparation
                to dispatch and delivery.
            </p>
            <a href="<%= context %>/orders/track">Track Orders</a>
        </div>

        <!-- Card 5: My Profile (only once) -->
        <div class="card">
            <div class="icon">👤</div>
            <h3>My Profile</h3>
            <p>
                Update your personal information and manage your account details.
            </p>
            <a href="<%= context %>/profile.jsp">Manage Profile</a>
        </div>

    </div>

</main>

<footer>
    &copy; 2026 SmartFoodDelivery. All rights reserved.
</footer>

</body>
</html>
