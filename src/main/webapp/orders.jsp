
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List,java.util.Map" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";
        return value.toString()
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&#39;");
    }
%>

<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, Object>> orders =
        (List<Map<String, Object>>) request.getAttribute("orders");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Orders | SmartFoodDelivery</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f4f7f5;
            color: #26332a;
        }

        header {
            background: #218838;
            color: white;
            padding: 18px 6%;
            display: flex;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        header a {
            color: white;
            text-decoration: none;
        }

        main {
            max-width: 950px;
            margin: 35px auto;
            padding: 0 20px;
        }

        h1 { color: #218838; }

        .order-card {
            background: white;
            padding: 22px;
            margin: 18px 0;
            border-radius: 10px;
            box-shadow: 0 3px 12px rgba(0,0,0,.06);
        }

        .order-card h3 { margin-top: 0; }

        .status {
            display: inline-block;
            padding: 6px 10px;
            background: #d1e7dd;
            color: #0f5132;
            border-radius: 5px;
            font-weight: bold;
        }

        .button {
            display: inline-block;
            padding: 11px 16px;
            background: #218838;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }

        .empty {
            background: white;
            padding: 25px;
            border-radius: 10px;
        }
    </style>
</head>

<body>

<header>
    <strong>🍽 SmartFoodDelivery</strong>
    <a href="<%= request.getContextPath() %>/customer/dashboard.jsp">
        Customer Dashboard
    </a>
</header>

<main>
    <h1>📦 My Orders</h1>

    <% if (orders == null || orders.isEmpty()) { %>

        <div class="empty">
            <p>You have not placed any orders yet.</p>
            <a class="button"
               href="<%= request.getContextPath() %>/food/menu">
                Browse Food
            </a>
        </div>

    <% } else { %>

        <% for (Map<String, Object> order : orders) { %>

            <div class="order-card">

                <h3>Order #<%= order.get("id") %></h3>

                <p>
                    <strong>Total:</strong>
                    ₹<%= escapeHtml(order.get("total")) %>
                </p>

                <p>
                    <strong>Status:</strong>
                    <span class="status">
                        <%= escapeHtml(order.get("status")) %>
                    </span>
                </p>

                <p>
                    <strong>Delivery Address:</strong>
                    <%= escapeHtml(order.get("address")) %>
                </p>

                <p>
                    <strong>Payment:</strong>
                    <%= escapeHtml(order.get("payment")) %>
                </p>

                <p>
                    <strong>Order Date:</strong>
                    <%= escapeHtml(order.get("date")) %>
                </p>

            </div>

        <% } %>

    <% } %>

    <p>
        <a class="button"
           href="<%= request.getContextPath() %>/food/menu">
            Order More Food
        </a>
    </p>

</main>

</body>
</html>
