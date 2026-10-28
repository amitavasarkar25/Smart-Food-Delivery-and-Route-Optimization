
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String role = (String) session.getAttribute("userRole");

    if (!"CUSTOMER".equals(role)) {
        if ("ADMIN".equals(role)) {
            response.sendRedirect(
                request.getContextPath() + "/admin/dashboard");
        } else {
            response.sendError(403, "Access denied.");
        }
        return;
    }

    String context = request.getContextPath();
    String error = request.getParameter("error");
    String success = request.getParameter("success");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Change Password | SmartFoodDelivery</title>

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
            max-width: 520px;
            margin: 40px auto;
            padding: 0 18px;
        }

        .card {
            background: white;
            padding: 28px;
            border-radius: 12px;
            box-shadow: 0 4px 18px #0000000d;
        }

        h1 { margin-top: 0; }

        .subtitle { color: #777; }

        label {
            display: block;
            margin: 18px 0 8px;
            font-weight: bold;
        }

        input {
            width: 100%;
            padding: 12px;
            border: 1px solid #ccc;
            border-radius: 7px;
            font-size: 15px;
        }

        button, .back {
            display: inline-block;
            margin-top: 22px;
            padding: 12px 16px;
            border: none;
            border-radius: 7px;
            font-weight: bold;
            font-size: 14px;
            text-decoration: none;
            cursor: pointer;
        }

        button {
            background: #16803c;
            color: white;
        }

        .back {
            background: #edf1ed;
            color: #263328;
            margin-left: 5px;
        }

        .message {
            padding: 12px;
            border-radius: 7px;
            margin: 16px 0;
        }

        .success {
            background: #e0f5e7;
            color: #146c32;
        }

        .error {
            background: #fde8e7;
            color: #a3221b;
        }

        .hint {
            color: #666;
            font-size: 13px;
            margin-top: 7px;
        }
    </style>
</head>

<body>
<header>
    <h2>SmartFoodDelivery</h2>
</header>

<div class="container">
    <div class="card">
        <h1>Change Password</h1>
        <p class="subtitle">Choose a strong password for your account.</p>

        <% if ("1".equals(success)) { %>
            <div class="message success">
                Password changed successfully!
            </div>
        <% } %>

        <% if ("current".equals(error)) { %>
            <div class="message error">
                Your current password is incorrect.
            </div>
        <% } else if ("mismatch".equals(error)) { %>
            <div class="message error">
                The new passwords do not match.
            </div>
        <% } else if ("length".equals(error)) { %>
            <div class="message error">
                Your new password must be between 8 and 128 characters.
            </div>
        <% } else if ("same".equals(error)) { %>
            <div class="message error">
                Choose a password different from your current one.
            </div>
        <% } else if ("missing".equals(error)) { %>
            <div class="message error">
                Please fill in all three password fields.
            </div>
        <% } else if ("account".equals(error)) { %>
            <div class="message error">
                Your account could not be found. Please log in again.
            </div>
        <% } %>

        <form action="<%= context %>/profile/change-password"
              method="post">

            <label for="currentPassword">Current Password</label>
            <input type="password"
                   id="currentPassword"
                   name="currentPassword"
                   autocomplete="current-password"
                   required>

            <label for="newPassword">New Password</label>
            <input type="password"
                   id="newPassword"
                   name="newPassword"
                   minlength="8"
                   maxlength="128"
                   autocomplete="new-password"
                   required>

            <p class="hint">Use at least 8 characters.</p>

            <label for="confirmPassword">Confirm New Password</label>
            <input type="password"
                   id="confirmPassword"
                   name="confirmPassword"
                   minlength="8"
                   maxlength="128"
                   autocomplete="new-password"
                   required>

            <button type="submit">Update Password</button>

            <a class="back"
               href="<%= context %>/profile.jsp">Back to Profile</a>
        </form>
    </div>
</div>
</body>
</html>
