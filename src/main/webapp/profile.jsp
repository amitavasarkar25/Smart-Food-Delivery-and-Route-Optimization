
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%!
    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
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

    String role = (String) session.getAttribute("userRole");

    if ("ADMIN".equals(role)) {
        response.sendRedirect(request.getContextPath() + "/admin/dashboard");
        return;
    }

    if (!"CUSTOMER".equals(role)) {
        response.sendError(403, "Access denied.");
        return;
    }

    String name = (String) session.getAttribute("userName");
    String email = (String) session.getAttribute("userEmail");
    String context = request.getContextPath();

    String updated = request.getParameter("updated");
    String error = request.getParameter("error");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Profile | SmartFoodDelivery</title>

    <style>
        * { box-sizing: border-box; }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f4f7f4;
            color: #263328;
        }

        header {
            background: #16803c;
            color: white;
            padding: 20px 7%;
        }

        header h2 { margin: 0; }

        .container {
            max-width: 620px;
            margin: 40px auto;
            padding: 0 18px;
        }

        .card {
            background: white;
            padding: 28px;
            border-radius: 14px;
            box-shadow: 0 4px 18px #0000000d;
        }

        h1 { margin-top: 0; }

        .subtitle { color: #777; }

        label {
            display: block;
            margin: 20px 0 8px;
            font-weight: bold;
        }

        input {
            width: 100%;
            padding: 13px;
            border: 1px solid #ccc;
            border-radius: 7px;
            font-size: 15px;
        }

        button, .link {
            display: inline-block;
            padding: 12px 18px;
            border: none;
            border-radius: 7px;
            font-size: 15px;
            font-weight: bold;
            text-decoration: none;
            cursor: pointer;
            margin-top: 22px;
        }

        button {
            background: #16803c;
            color: white;
        }

        .link {
            background: #edf1ed;
            color: #263328;
            margin-left: 6px;
        }

        .message {
            padding: 12px;
            border-radius: 7px;
            margin: 18px 0;
        }

        .success {
            background: #e0f5e7;
            color: #146c32;
        }

        .error {
            background: #fde8e7;
            color: #a3221b;
        }

        @media (max-width: 480px) {
            .card { padding: 20px; }
            .link { margin-left: 0; }
        }
    </style>
</head>

<body>
<header>
    <h2>SmartFoodDelivery</h2>
</header>

<div class="container">
    <div class="card">
        <h1>My Profile</h1>
        <p class="subtitle">Update your account information.</p>

        <% if ("1".equals(updated)) { %>
            <div class="message success">
                Profile updated successfully!
            </div>
        <% } %>

        <% if ("email".equals(error)) { %>
            <div class="message error">
                This email address is already registered.
            </div>
        <% } else if ("invalid".equals(error)) { %>
            <div class="message error">
                Enter a valid name and email address.
            </div>
        <% } else if ("notfound".equals(error)) { %>
            <div class="message error">
                Account not found. Please log in again.
            </div>
        <% } %>

        <form action="<%= context %>/profile/update" method="post">
            <label for="name">Full Name</label>
            <input
                type="text"
                id="name"
                name="name"
                maxlength="100"
                required
                value="<%= escapeHtml(name) %>">

            <label for="email">Email Address</label>
            <input
                type="email"
                id="email"
                name="email"
                maxlength="100"
                required
                value="<%= escapeHtml(email) %>">

            <button type="submit">Save Changes</button>

            <a class="link"
               href="<%= context %>/customer/dashboard.jsp">
                Back
            </a>
            <a class="link"
                href="<%= context %>/change-password.jsp">
                Change Password
            </a>
        </form>
    </div>
</div>

</body>
</html>
