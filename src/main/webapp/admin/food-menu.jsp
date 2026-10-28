
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.math.BigDecimal" %>

<%!
    private String esc(Object value) {
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
    if (session.getAttribute("userId") == null
            || !"ADMIN".equals(session.getAttribute("userRole"))) {
        response.sendError(403, "Admin access required.");
        return;
    }

    List<Map<String, Object>> foodItems =
            (List<Map<String, Object>>) request.getAttribute("foodItems");

    String context = request.getContextPath();
    String success = request.getParameter("success");
    String error = request.getParameter("error");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Food Menu | SmartFoodDelivery</title>

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

        header h2 { margin: 0; }

        header a {
            color: white;
            text-decoration: none;
            font-weight: bold;
        }

        .container {
            max-width: 1250px;
            margin: 30px auto;
            padding: 0 18px;
        }

        .panel {
            background: white;
            padding: 24px;
            border-radius: 12px;
            margin-bottom: 25px;
            box-shadow: 0 3px 14px #0000000d;
        }

        h1, h2 { margin-top: 0; }

        .form-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 15px;
        }

        label {
            display: block;
            font-weight: bold;
            margin-bottom: 7px;
        }

        input, textarea {
            width: 100%;
            padding: 11px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font: inherit;
        }

        textarea {
            min-height: 75px;
            resize: vertical;
        }

        .full { grid-column: 1 / -1; }

        button, .button {
            display: inline-block;
            border: none;
            border-radius: 6px;
            padding: 10px 14px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            text-decoration: none;
        }

        .primary {
            background: #218838;
            color: white;
        }

        .secondary {
            background: #e9efea;
            color: #26332a;
        }

        .warning {
            background: #fff0cc;
            color: #775500;
        }

        .success-message {
            padding: 13px;
            background: #e0f5e7;
            color: #146c32;
            border-radius: 7px;
            margin-bottom: 20px;
        }

        .error-message {
            padding: 13px;
            background: #fde8e7;
            color: #a3221b;
            border-radius: 7px;
            margin-bottom: 20px;
        }

        .table-wrap {
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 850px;
        }

        th, td {
            padding: 13px 10px;
            border-bottom: 1px solid #e5e5e5;
            text-align: left;
            vertical-align: top;
        }

        th {
            background: #f0f5f0;
        }

        td input, td textarea {
            min-width: 100px;
            margin-bottom: 8px;
        }

        td textarea {
            min-width: 150px;
        }

        .status {
            display: inline-block;
            padding: 5px 9px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: bold;
        }

        .available {
            background: #e0f5e7;
            color: #146c32;
        }

        .unavailable {
            background: #fde8e7;
            color: #a3221b;
        }

        .actions {
            display: flex;
            flex-direction: column;
            align-items: flex-start;
            gap: 7px;
        }

        @media (max-width: 650px) {
            .form-grid {
                grid-template-columns: 1fr;
            }

            .full { grid-column: auto; }

            .panel { padding: 17px; }
        }
    </style>
</head>

<body>

<header>
    <h2>🍽️ SmartFoodDelivery — Menu Management</h2>
    <a href="<%= context %>/admin/dashboard">Admin Dashboard</a>
</header>

<main class="container">

    <h1>Manage Food Menu</h1>
    <p>Add dishes, update prices, and manage availability.</p>

    <% if ("added".equals(success)) { %>
        <div class="success-message">Food item added successfully.</div>
    <% } else if ("updated".equals(success)) { %>
        <div class="success-message">Food item updated successfully.</div>
    <% } else if ("toggled".equals(success)) { %>
        <div class="success-message">Food availability updated.</div>
    <% } %>

    <% if (error != null) { %>
        <div class="error-message">
            <% if ("invalid".equals(error)) { %>
                Please check your inputs. The name, price, or other field may be invalid.
            <% } else if ("action".equals(error)) { %>
                Invalid menu action.
            <% } else { %>
                The request could not be completed.
            <% } %>
        </div>
    <% } %>

    <section class="panel">
        <h2>Add New Food Item</h2>

        <form action="<%= context %>/admin/food-menu" method="post">
            <input type="hidden" name="action" value="add">

            <div class="form-grid">

                <div>
                    <label for="name">Food Name *</label>
                    <input type="text" id="name" name="name"
                           maxlength="150" required>
                </div>

                <div>
                    <label for="category">Category</label>
                    <input type="text" id="category" name="category"
                           maxlength="100" placeholder="e.g. Indian">
                </div>

                <div>
                    <label for="price">Price (₹) *</label>
                    <input type="number" id="price" name="price"
                           min="0.01" max="99999999" step="0.01" required>
                </div>

                <div>
                    <label for="image_url">Image URL</label>
                    <input type="url" id="image_url" name="image_url"
                           maxlength="500" placeholder="https://...">
                </div>

                <div class="full">
                    <label for="description">Description</label>
                    <textarea id="description" name="description"
                              maxlength="500"></textarea>
                </div>

                <div class="full">
                    <button type="submit" class="primary">
                        + Add Food Item
                    </button>
                </div>

            </div>
        </form>
    </section>

    <section class="panel">
        <h2>Existing Food Items</h2>

        <% if (foodItems == null || foodItems.isEmpty()) { %>
            <p>No food items found in the database.</p>
        <% } else { %>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Food Details</th>
                        <th>Price</th>
                        <th>Availability</th>
                        <th>Actions</th>
                    </tr>
                </thead>

                <tbody>
                <% for (Map<String, Object> item : foodItems) {
                    Object id = item.get("id");
                    boolean available =
                            Boolean.TRUE.equals(item.get("available"));
                %>

                    <tr>
                        <td><%= esc(id) %></td>

                        <td>
                            <form id="edit-<%= esc(id) %>"
                                  action="<%= context %>/admin/food-menu"
                                  method="post">

                                <input type="hidden" name="action" value="update">
                                <input type="hidden" name="id" value="<%= esc(id) %>">

                                <label>Food Name</label>
                                <input type="text" name="name"
                                       maxlength="150"
                                       value="<%= esc(item.get("name")) %>"
                                       required>

                                <label>Category</label>
                                <input type="text" name="category"
                                       maxlength="100"
                                       value="<%= esc(item.get("category")) %>">

                                <label>Description</label>
                                <textarea name="description"
                                          maxlength="500"><%= esc(item.get("description")) %></textarea>

                                <label>Image URL</label>
                                <input type="url" name="image_url"
                                       maxlength="500"
                                       value="<%= esc(item.get("image_url")) %>">
                            </form>
                        </td>

                        <td>
                            <label>Price (₹)</label>
                            <input type="number"
                                   name="price"
                                   form="edit-<%= esc(id) %>"
                                   min="0.01"
                                   max="99999999"
                                   step="0.01"
                                   value="<%= esc(item.get("price")) %>"
                                   required>
                        </td>

                        <td>
                            <% if (available) { %>
                                <span class="status available">Available</span>
                            <% } else { %>
                                <span class="status unavailable">Unavailable</span>
                            <% } %>
                        </td>

                        <td>
                            <div class="actions">
                                <button type="submit"
                                        form="edit-<%= esc(id) %>"
                                        class="primary">
                                    Save Changes
                                </button>

                                <form action="<%= context %>/admin/food-menu"
                                      method="post">
                                    <input type="hidden" name="action" value="toggle">
                                    <input type="hidden" name="id" value="<%= esc(id) %>">

                                    <button type="submit" class="warning">
                                        <%= available
                                                ? "Mark Unavailable"
                                                : "Mark Available" %>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>

                <% } %>
                </tbody>
            </table>
        </div>

        <% } %>
    </section>

</main>

</body>
</html>
