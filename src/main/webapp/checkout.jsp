
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.math.BigDecimal" %>
<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    BigDecimal total = (BigDecimal) request.getAttribute("checkoutTotal");
    if (total == null) {
        total = BigDecimal.ZERO;
    }

    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Checkout - SmartFoodDelivery</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #f4f6f8;
            margin: 0;
            padding: 30px;
        }
        .container {
            max-width: 550px;
            margin: 30px auto;
            background: white;
            padding: 28px;
            border-radius: 12px;
            box-shadow: 0 4px 15px #00000012;
        }
        label { display: block; margin-top: 18px; font-weight: bold; }
        textarea, select {
            width: 100%;
            box-sizing: border-box;
            padding: 12px;
            margin-top: 8px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 15px;
        }
        button {
            width: 100%;
            margin-top: 22px;
            padding: 13px;
            background: #198754;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
        }
        .error { color: #b42318; }
        .total { font-size: 22px; font-weight: bold; }
        a { color: #198754; }
    </style>
</head>
<body>
<div class="container">
    <h1>Checkout</h1>

    <% if (error != null) { %>
        <p class="error"><%= error.replace("&", "&amp;")
                .replace("<", "&lt;").replace(">", "&gt;") %></p>
    <% } %>

    <p class="total">Order total: ₹<%= total %></p>

    <form method="post"
          action="<%= request.getContextPath() %>/checkout">

        <label for="deliveryAddress">Delivery Address</label>
        <textarea id="deliveryAddress" name="deliveryAddress"
                  rows="4" maxlength="500" required
                  placeholder="Enter your complete delivery address"></textarea>

        <label for="paymentMethod">Payment Method</label>
        <select id="paymentMethod" name="paymentMethod">
            <option value="COD">Cash on Delivery (COD)</option>
        </select>

        <button type="submit">Place Order</button>
    </form>

    <p><a href="<%= request.getContextPath() %>/cart">Back to Cart</a></p>
</div>
</body>
</html>
