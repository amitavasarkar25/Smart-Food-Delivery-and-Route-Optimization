
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";

        String text = String.valueOf(value);

        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#39;");
    }
%>

<%
    List<Map<String, Object>> orders =
        (List<Map<String, Object>>) request.getAttribute("orders");

    if (orders == null) {
        orders = java.util.Collections.emptyList();
    }

    List<Map<String, Object>> deliveryStaff =
        (List<Map<String, Object>>) request.getAttribute("deliveryStaff");

    if (deliveryStaff == null) {
        deliveryStaff = java.util.Collections.emptyList();
    }

    String context = request.getContextPath();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Orders | SmartFoodDelivery</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f4f6f9;
            color: #263238;
        }

        header {
            background: #17252a;
            color: white;
            padding: 20px 5%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }

        header h2 {
            margin: 0;
        }

        header a {
            color: white;
            text-decoration: none;
            margin-left: 15px;
        }

        .container {
            width: 95%;
            max-width: 1700px;
            margin: 30px auto;
        }

        .heading {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 20px;
        }

        .count {
            background: white;
            padding: 12px 18px;
            border-radius: 8px;
            box-shadow: 0 2px 8px #00000010;
        }

        .table-wrapper {
            overflow-x: auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 3px 12px #00000010;
        }

        table {
            width: 100%;
            min-width: 1450px;
            border-collapse: collapse;
        }

        th, td {
            text-align: left;
            padding: 14px 12px;
            border-bottom: 1px solid #e5e7eb;
            vertical-align: top;
        }

        th {
            background: #eaf0f2;
            font-size: 13px;
        }

        td {
            font-size: 13px;
        }

        .status {
            display: inline-block;
            padding: 6px 9px;
            border-radius: 5px;
            background: #fff3cd;
            font-weight: bold;
            white-space: nowrap;
        }

        select {
            padding: 9px;
            border: 1px solid #ccd2d7;
            border-radius: 5px;
            background: white;
            margin-bottom: 7px;
            width: 190px;
            max-width: 100%;
        }

        button {
            background: #16804a;
            color: white;
            border: none;
            border-radius: 5px;
            padding: 9px 12px;
            cursor: pointer;
        }

        button:hover {
            background: #10663a;
        }

        .assign-button {
            background: #176b87;
        }

        .assign-button:hover {
            background: #10546b;
        }

        .empty {
            text-align: center;
            padding: 40px;
            color: #667085;
        }

        .back {
            display: inline-block;
            margin-top: 20px;
            color: #176b87;
            text-decoration: none;
        }

        .muted {
            color: #667085;
        }

        .delivery-name {
            font-weight: bold;
            margin-bottom: 5px;
        }
    </style>
</head>

<body>

<header>
    <h2>SmartFoodDelivery Admin</h2>

    <nav>
        <a href="<%= context %>/admin/dashboard">Dashboard</a>
        <a href="<%= context %>/logout">Logout</a>
    </nav>
</header>

<div class="container">

    <div class="heading">
        <div>
            <h1>Manage Orders</h1>
            <p>Update order status and assign delivery personnel.</p>
        </div>

        <div class="count">
            Total Orders: <strong><%= orders.size() %></strong>
        </div>
    </div>

    <div class="table-wrapper">

        <% if (orders.isEmpty()) { %>

            <div class="empty">
                <h3>No orders found</h3>
                <p>Customer orders will appear here after they are placed.</p>
            </div>

        <% } else { %>

            <table>
                <thead>
                    <tr>
                        <th>Order ID</th>
                        <th>Customer</th>
                        <th>Delivery Address</th>
                        <th>Amount</th>
                        <th>Payment</th>
                        <th>Order Date</th>
                        <th>Current Status</th>
                        <th>Update Status</th>
                        <th>Assigned Delivery Person</th>
                    </tr>
                </thead>

                <tbody>

                <% for (Map<String, Object> order : orders) {
                    String currentStatus =
                        String.valueOf(order.get("status"));

                    Object assignedIdObject =
                        order.get("deliveryPersonId");

                    String assignedId = assignedIdObject == null
                        ? ""
                        : String.valueOf(assignedIdObject);
                %>

                    <tr>
                        <td>
                            #<%= escapeHtml(order.get("id")) %>
                        </td>

                        <td>
                            <strong>
                                <%= escapeHtml(order.get("customerName")) %>
                            </strong>
                            <br>
                            <%= escapeHtml(order.get("customerEmail")) %>
                        </td>

                        <td>
                            <%= escapeHtml(order.get("address")) %>
                        </td>

                        <td>
                            ₹<%= escapeHtml(order.get("totalAmount")) %>
                        </td>

                        <td>
                            <%= escapeHtml(order.get("paymentMethod")) %>
                        </td>

                        <td>
                            <%= escapeHtml(order.get("createdAt")) %>
                        </td>

                        <td>
                            <span class="status">
                                <%= escapeHtml(currentStatus) %>
                            </span>
                        </td>

                        <td>
                            <form method="post"
                                  action="<%= context %>/admin/orders">

                                <input type="hidden"
                                       name="orderId"
                                       value="<%= escapeHtml(order.get("id")) %>">

                                <select name="status" required>
                                    <option value="PLACED"
                                        <%= "PLACED".equals(currentStatus)
                                            ? "selected" : "" %>>
                                        Placed
                                    </option>

                                    <option value="PREPARING"
                                        <%= "PREPARING".equals(currentStatus)
                                            ? "selected" : "" %>>
                                        Preparing
                                    </option>

                                    <option value="OUT_FOR_DELIVERY"
                                        <%= "OUT_FOR_DELIVERY".equals(currentStatus)
                                            ? "selected" : "" %>>
                                        Out for Delivery
                                    </option>

                                    <option value="DELIVERED"
                                        <%= "DELIVERED".equals(currentStatus)
                                            ? "selected" : "" %>>
                                        Delivered
                                    </option>
                                </select>

                                <br>

                                <button type="submit">
                                    Update Status
                                </button>
                            </form>
                        </td>

                        <td>
                            <% if (assignedId.isEmpty()) { %>
                                <div class="muted">Not assigned</div>
                            <% } else { %>
                                <div class="delivery-name">
                                    <%= escapeHtml(
                                        order.get("deliveryPersonName")) %>
                                </div>
                                <div class="muted">
                                    Currently assigned
                                </div>
                            <% } %>

                            <form method="post"
                                  action="<%= context %>/admin/orders">

                                <input type="hidden"
                                       name="action"
                                       value="assignDelivery">

                                <input type="hidden"
                                       name="orderId"
                                       value="<%= escapeHtml(order.get("id")) %>">

                                <select name="deliveryPersonId">
                                    <option value="">Unassign delivery person</option>

                                    <% for (Map<String, Object> staff : deliveryStaff) {
                                        String staffId =
                                            String.valueOf(staff.get("id"));
                                    %>
                                        <option value="<%= escapeHtml(staffId) %>"
                                            <%= staffId.equals(assignedId)
                                                ? "selected" : "" %>>
                                            <%= escapeHtml(staff.get("name")) %>
                                        </option>
                                    <% } %>
                                </select>

                                <br>

                                <button type="submit" class="assign-button">
                                    Save Assignment
                                </button>
                            </form>

                            <% if (deliveryStaff.isEmpty()) { %>
                                <p class="muted">
                                    No delivery staff registered yet.
                                </p>
                            <% } %>
                        </td>
                    </tr>

                <% } %>

                </tbody>
            </table>

        <% } %>

    </div>

    <a class="back" href="<%= context %>/admin/dashboard">
        ← Back to Admin Dashboard
    </a>

</div>

</body>
</html>
