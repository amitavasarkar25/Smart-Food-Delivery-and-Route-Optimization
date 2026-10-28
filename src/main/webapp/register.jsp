
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Account | SmartFoodDelivery</title>

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: Arial, sans-serif;
        }

        body {
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 25px;
            background: linear-gradient(135deg, #fff7ed, #ffedd5);
        }

        .register-container {
            width: 100%;
            max-width: 440px;
            background: white;
            padding: 35px;
            border-radius: 18px;
            box-shadow: 0 12px 35px rgba(0, 0, 0, 0.12);
        }

        .logo {
            text-align: center;
            font-size: 30px;
            margin-bottom: 10px;
        }

        h1 {
            text-align: center;
            color: #222;
            font-size: 26px;
            margin-bottom: 8px;
        }

        .subtitle {
            text-align: center;
            color: #777;
            font-size: 14px;
            margin-bottom: 25px;
        }

        .form-group {
            margin-bottom: 18px;
        }

        label {
            display: block;
            margin-bottom: 7px;
            color: #333;
            font-size: 14px;
            font-weight: bold;
        }

        input {
            width: 100%;
            padding: 12px 14px;
            border: 1px solid #ddd;
            border-radius: 8px;
            outline: none;
            font-size: 14px;
            transition: border-color 0.2s;
        }

        input:focus {
            border-color: #ea580c;
            box-shadow: 0 0 0 3px rgba(234, 88, 12, 0.1);
        }

        .register-btn {
            width: 100%;
            padding: 13px;
            border: none;
            border-radius: 8px;
            background: #ea580c;
            color: white;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            margin-top: 5px;
        }

        .register-btn:hover {
            background: #c2410c;
        }

        .login-link {
            text-align: center;
            margin-top: 22px;
            color: #666;
            font-size: 14px;
        }

        .login-link a {
            color: #ea580c;
            font-weight: bold;
            text-decoration: none;
        }

        .login-link a:hover {
            text-decoration: underline;
        }

        .back-home {
            display: block;
            text-align: center;
            margin-top: 18px;
            color: #555;
            text-decoration: none;
            font-size: 13px;
        }

        .back-home:hover {
            color: #ea580c;
        }
    </style>
</head>

<body>

<div class="register-container">

    <div class="logo">🍔</div>

    <h1>Create Account</h1>
    <p class="subtitle">Join SmartFoodDelivery and order your favourites.</p>

    <form action="${pageContext.request.contextPath}/register"
          method="post"
          accept-charset="UTF-8">

        <div class="form-group">
            <label for="name">Full Name</label>
            <input type="text"
                   id="name"
                   name="name"
                   placeholder="Enter your full name"
                   maxlength="100"
                   autocomplete="name"
                   required>
        </div>

        <div class="form-group">
            <label for="email">Email Address</label>
            <input type="email"
                   id="email"
                   name="email"
                   placeholder="Enter your email"
                   maxlength="100"
                   autocomplete="email"
                   required>
        </div>

        <div class="form-group">
            <label for="password">Password</label>
            <input type="password"
                   id="password"
                   name="password"
                   placeholder="Create a password"
                   minlength="8"
                   autocomplete="new-password"
                   required>
        </div>

        <div class="form-group">
            <label for="confirmPassword">Confirm Password</label>
            <input type="password"
                   id="confirmPassword"
                   name="confirmPassword"
                   placeholder="Re-enter your password"
                   minlength="8"
                   autocomplete="new-password"
                   required>
        </div>

        <button type="submit" class="register-btn">
            Create Account
        </button>

    </form>

    <p class="login-link">
        Already have an account?
        <a href="${pageContext.request.contextPath}/login.jsp">Login</a>
    </p>

    <a class="back-home"
       href="${pageContext.request.contextPath}/index.jsp">
        ← Back to Home
    </a>

</div>

<script>
    const form = document.querySelector("form");
    const password = document.getElementById("password");
    const confirmPassword = document.getElementById("confirmPassword");

    form.addEventListener("submit", function(event) {
        if (password.value !== confirmPassword.value) {
            event.preventDefault();
            alert("Passwords do not match. Please try again.");
            confirmPassword.focus();
        }
    });
</script>

</body>
</html>
<%
    String errorMessage =
        (String) request.getAttribute("errorMessage");
    if (errorMessage != null) {
%>
    <div style="background:#fee2e2; color:#991b1b;
                padding:12px; border-radius:8px;
                margin-bottom:18px;">
        <%= errorMessage %>
    </div>
<%
    }
%>