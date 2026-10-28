
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List,java.util.Map,java.math.BigDecimal" %>

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

    List<Map<String, Object>> cartItems =
        (List<Map<String, Object>>) request.getAttribute("cartItems");

    BigDecimal cartTotal =
        (BigDecimal) request.getAttribute("cartTotal");

    Boolean unavailableFlag =
        (Boolean) request.getAttribute("hasUnavailableItems");

    boolean hasUnavailableItems =
        Boolean.TRUE.equals(unavailableFlag);

    String cartMessage =
        (String) session.getAttribute("cartMessage");

    session.removeAttribute("cartMessage");

    if (cartTotal == null) {
        cartTotal = BigDecimal.ZERO;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>My Cart | SmartFoodDelivery</title>

    <style>
        * {
            box-sizing: border-box;
        }

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
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
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

        h1 {
            color: #218838;
        }

        .message {
            background: #d1e7dd;
            color: #0f5132;
            padding: 12px;
            border-radius: 6px;
            margin: 18px 0;
        }

        .warning {
            background: #fff0cc;
            color: #775500;
            border: 1px solid #e4bd58;
            padding: 14px;
            border-radius: 7px;
            margin: 18px 0;
            line-height: 1.5;
        }

        .cart-item {
            background: white;
            padding: 20px;
            margin: 15px 0;
            border-radius: 10px;
            box-shadow: 0 3px 12px rgba(0, 0, 0, 0.06);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 16px;
        }

        .unavailable-item {
            border: 1px solid #dc7777;
            background: #fffafa;
        }

        .item-info h3 {
            margin: 0 0 8px;
        }

        .item-info p {
            color: #666;
            margin: 5px 0;
        }

        .status {
            display: inline-block;
            padding: 5px 9px;
            border-radius: 14px;
            font-size: 12px;
            font-weight: bold;
            margin-top: 5px;
        }

        .available {
            background: #d1e7dd;
            color: #0f5132;
        }

        .unavailable {
            background: #f8d7da;
            color: #842029;
        }

        input[type="number"] {
            width: 75px;
            padding: 9px;
            border: 1px solid #ccc;
            border-radius: 5px;
        }

        button,
        .button {
            display: inline-block;
            border: none;
            padding: 10px 14px;
            border-radius: 5px;
            cursor: pointer;
            background: #218838;
            color: white;
            text-decoration: none;
            font-size: 14px;
        }

        button:hover:not(:disabled),
        .button:hover {
            opacity: 0.9;
        }

        button:disabled {
            background: #9ba49d;
            cursor: not-allowed;
            opacity: 0.8;
        }

        .remove {
            background: #c62828;
        }

        .actions {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }

        .actions form {
            margin: 0;
        }

        .total {
            background: white;
            padding: 22px;
            border-radius: 10px;
            text-align: right;
            font-size: 22px;
            font-weight: bold;
            margin-top: 25px;
            box-shadow: 0 3px 12px rgba(0, 0, 0, 0.06);
        }

        .checkout-form {
            margin-top: 18px;
        }

        .checkout-button {
            padding: 12px 20px;
            background: #198754;
            color: white;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 16px;
        }

        .empty {
            background: white;
            padding: 25px;
            border-radius: 10px;
        }

        .continue-shopping {
            margin-top: 22px;
        }

        @media (max-width: 600px) {
            main {
                margin-top: 20px;
            }

            .cart-item {
                align-items: flex-start;
                flex-direction: column;
            }

            .total {
                text-align: left;
            }
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

    <h1>🛒 My Shopping Cart</h1>

    <% if (cartMessage != null) { %>
        <div class="message">
            <%= escapeHtml(cartMessage) %>
        </div>
    <% } %>

    <% if (cartItems == null || cartItems.isEmpty()) { %>

        <div class="empty">
            <p>Your cart is empty.</p>

            <a class="button"
               href="<%= request.getContextPath() %>/food/menu">
                Browse Food
            </a>
        </div>

    <% } else { %>

        <% if (hasUnavailableItems) { %>
            <div class="warning">
                <strong>⚠️ Some items are unavailable.</strong>
                <br>
                Remove the unavailable items before proceeding to checkout.
                Their prices are excluded from your cart total.
            </div>
        <% } %>

        <% for (Map<String, Object> item : cartItems) {
            boolean available =
                    Boolean.TRUE.equals(item.get("available"));
        %>

            <div class="cart-item <%= available ? "" : "unavailable-item" %>">

                <div class="item-info">

                    <h3>
                        <%= escapeHtml(item.get("name")) %>
                    </h3>

                    <% if (available) { %>
                        <span class="status available">Available</span>
                    <% } else { %>
                        <span class="status unavailable">Unavailable</span>
                    <% } %>

                    <p>
                        Price: ₹<%= escapeHtml(item.get("price")) %>
                    </p>

                    <p>
                        Quantity: <%= escapeHtml(item.get("quantity")) %>
                    </p>

                    <p>
                        Subtotal: ₹<%= escapeHtml(item.get("subtotal")) %>
                    </p>

                </div>

                <div class="actions">

                    <% if (available) { %>

                        <form action="<%= request.getContextPath() %>/cart"
                              method="post">

                            <input type="hidden"
                                   name="action"
                                   value="update">

                            <input type="hidden"
                                   name="foodId"
                                   value="<%= escapeHtml(item.get("id")) %>">

                            <input type="number"
                                   name="quantity"
                                   min="1"
                                   max="99"
                                   value="<%= escapeHtml(item.get("quantity")) %>"
                                   required
                                   aria-label="Quantity">

                            <button type="submit">
                                Update
                            </button>

                        </form>

                    <% } %>

                    <form action="<%= request.getContextPath() %>/cart"
                          method="post">

                        <input type="hidden"
                               name="action"
                               value="remove">

                        <input type="hidden"
                               name="foodId"
                               value="<%= escapeHtml(item.get("id")) %>">

                        <button class="remove" type="submit">
                            Remove
                        </button>

                    </form>

                </div>

            </div>

        <% } %>

        <div class="total">

            Total: ₹<%= escapeHtml(cartTotal) %>

            <form class="checkout-form"
                  action="<%= request.getContextPath() %>/checkout"
                  method="get">

                <button class="checkout-button"
                        type="submit"
                        <%= hasUnavailableItems ? "disabled" : "" %>>
                    Proceed to Checkout
                </button>

            </form>

            <% if (hasUnavailableItems) { %>
                <p style="font-size: 14px; color: #842029; font-weight: normal;">
                    Remove unavailable items to enable checkout.
                </p>
            <% } %>

        </div>

        <p class="continue-shopping">
            <a class="button"
               href="<%= request.getContextPath() %>/food/menu">
                Continue Shopping
            </a>
        </p>

    <% } %>

</main>

</body>
</html>
