
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
        response.sendRedirect(
            request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, Object>> foodItems =
        (List<Map<String, Object>>) request.getAttribute("foodItems");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Food Menu | SmartFoodDelivery</title>

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
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
        }

        header a {
            color: white;
            text-decoration: none;
            font-weight: bold;
        }

        main {
            max-width: 1150px;
            margin: 35px auto;
            padding: 0 20px;
        }

        h1 { color: #218838; }

        .subtitle { color: #666; }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
            gap: 22px;
            margin-top: 25px;
        }

        .card {
            background: white;
            padding: 22px;
            border-radius: 12px;
            box-shadow: 0 3px 15px rgba(0,0,0,.07);
        }

        .food-icon {
            font-size: 48px;
            margin-bottom: 12px;
        }

        .category {
            color: #218838;
            font-size: 13px;
            font-weight: bold;
            text-transform: uppercase;
        }

        .description {
            color: #666;
            line-height: 1.5;
            min-height: 45px;
        }

        .price {
            font-size: 21px;
            font-weight: bold;
            margin: 18px 0 0;
        }

        .back {
            display: inline-block;
            margin-top: 28px;
            color: #218838;
            text-decoration: none;
        }

        .empty {
            background: white;
            padding: 20px;
            border-radius: 8px;
        }
        
        .card form {
            margin-top: 18px;
        }

        .card form label {
            display: block;
            margin-bottom: 12px;
            font-size: 14px;
        }

        .card form input {
            width: 65px;
            padding: 8px;
            border: 1px solid #ccc;
            border-radius: 5px;
        }

        .card form button {
            width: 100%;
            padding: 11px;
            border: none;
            border-radius: 6px;
            background: #218838;
            color: white;
            cursor: pointer;
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
    <h1>Our Food Menu 🍕</h1>
    <p class="subtitle">
        Explore our dishes and choose what you would like to eat.
    </p>

    <% if (foodItems == null || foodItems.isEmpty()) { %>

        <div class="empty">
            No food items are currently available.
        </div>

    <% } else { %>

        <div class="grid">
            <% for (Map<String, Object> item : foodItems) { %>

                <article class="card">
                    <div class="food-icon">🍽️</div>

                    <div class="category">
                        <%= escapeHtml(item.get("category")) %>
                    </div>

                    <h3><%= escapeHtml(item.get("name")) %></h3>

                    <p class="description">
                        <%= escapeHtml(item.get("description")) %>
                    </p>

                    <p class="price">
                        ₹<%= escapeHtml(item.get("price")) %>
                    </p>
                    
                    <form action="<%= request.getContextPath() %>/cart"
                        method="post">
                        <input type="hidden" name="action" value="add">
                        <input type="hidden" name="foodId"
                            value="<%= item.get("id") %>">

                        <label>
                            Quantity:
                            <input type="number" name="quantity"
                                value="1" min="1" max="99" required>
                        </label>

                        <button type="submit">Add to Cart</button>
                      </form>

                </article>

            <% } %>
        </div>

    <% } %>

    <a class="back"
       href="<%= request.getContextPath() %>/customer/dashboard.jsp">
        ← Back to Dashboard
    </a>
</main>

</body>
</html>
