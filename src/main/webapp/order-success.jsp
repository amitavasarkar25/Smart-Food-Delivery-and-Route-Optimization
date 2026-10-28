
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    if (session.getAttribute("userId") == null ||
        session.getAttribute("lastOrderId") == null) {
        response.sendRedirect(request.getContextPath() + "/customer/dashboard.jsp");
        return;
    }

    int orderId = ((Number) session.getAttribute("lastOrderId")).intValue();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Order Placed - SmartFoodDelivery</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f6f8;
            text-align: center;
            padding: 60px 20px;
        }
        .card {
            max-width: 500px;
            margin: auto;
            background: white;
            padding: 35px;
            border-radius: 12px;
            box-shadow: 0 4px 15px #00000012;
        }
        .check { font-size: 55px; color: #198754; }
        a {
            display: inline-block;
            margin: 10px;
            color: #198754;
        }
    </style>
</head>
<body>
<div class="card">
    <div class="check">&#10004;</div>
    <h1>Order Placed Successfully!</h1>
    <p>Thank you for ordering with SmartFoodDelivery.</p>
    <h2>Order ID: #<%= orderId %></h2>
    <p>Payment method: Cash on Delivery</p>
    <p>Order status: Placed</p>

    <a href="<%= request.getContextPath() %>/customer/dashboard.jsp">
        Return to Dashboard
    </a>
    <a href="<%= request.getContextPath() %>/food/menu">
        Order More Food
    </a>
</div>
</body>
</html>
