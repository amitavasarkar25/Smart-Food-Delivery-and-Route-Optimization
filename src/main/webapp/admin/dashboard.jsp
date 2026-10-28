
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    if (!"ADMIN".equals(session.getAttribute("userRole"))) {
        response.sendError(403, "Administrator permission required.");
        return;
    }

    int totalOrders = request.getAttribute("totalOrders") == null
            ? 0 : (Integer) request.getAttribute("totalOrders");

    int pendingOrders = request.getAttribute("pendingOrders") == null
            ? 0 : (Integer) request.getAttribute("pendingOrders");

    int completedOrders = request.getAttribute("completedOrders") == null
            ? 0 : (Integer) request.getAttribute("completedOrders");

    java.math.BigDecimal totalSales =
            (java.math.BigDecimal) request.getAttribute("totalSales");

    if (totalSales == null) {
        totalSales = java.math.BigDecimal.ZERO;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard | SmartFoodDelivery</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f4f7f5;
            color: #26332a;
        }

        header {
            background: #176b35;
            color: white;
            padding: 20px 6%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }

        header a {
            color: white;
            text-decoration: none;
        }

        main {
            max-width: 1100px;
            margin: 35px auto;
            padding: 0 20px;
        }

        h1 { color: #176b35; }

        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
            gap: 20px;
            margin-top: 25px;
        }

        .card {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 3px 12px rgba(0,0,0,.06);
        }

        .card h3 {
            margin-top: 0;
            color: #555;
            font-size: 16px;
        }

        .number {
            font-size: 30px;
            font-weight: bold;
            color: #176b35;
        }

        .button {
            display: inline-block;
            margin-top: 25px;
            padding: 12px 18px;
            background: #218838;
            color: white;
            text-decoration: none;
            border-radius: 6px;
        }
    </style>
</head>

<body>

<header>
    <strong>🍽 SmartFoodDelivery — Admin</strong>
    <a href="<%= request.getContextPath() %>/logout">Logout</a>
</header>

<main>
    <h1>Admin Dashboard</h1>
    <p>Monitor restaurant orders and delivery performance.</p>

    <div class="cards">

        <div class="card">
            <h3>Total Orders</h3>
            <div class="number"><%= totalOrders %></div>
        </div>

        <div class="card">
            <h3>Pending / In Progress</h3>
            <div class="number"><%= pendingOrders %></div>
        </div>

        <div class="card">
            <h3>Delivered Orders</h3>
            <div class="number"><%= completedOrders %></div>
        </div>

        <div class="card">
            <h3>Delivered Sales</h3>
            <div class="number">₹<%= totalSales %></div>
        </div>

    </div>

    <a class="button"
       href="<%= request.getContextPath() %>/admin/orders">
        Manage Orders
    </a>

    <a class="button"
       href="<%= request.getContextPath() %>/customer/dashboard.jsp">
        Customer Dashboard
    </a>
     <a href="<%= request.getContextPath() %>/admin/food-menu">
        Manage Food Menu
    </a>
</main>

</body>
</html>
