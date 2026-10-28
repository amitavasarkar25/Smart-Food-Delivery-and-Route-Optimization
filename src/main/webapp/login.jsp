
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login | SmartFoodDelivery</title>

    <style>
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            font-family: Arial, sans-serif;
            background: #f4f7f5;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }

        .login-container {
            width: 90%;
            max-width: 420px;
            padding: 32px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 6px 24px rgba(0, 0, 0, 0.10);
        }

        h1 {
            text-align: center;
            color: #218838;
            margin-top: 0;
        }

        p {
            text-align: center;
            color: #666;
        }

        label {
            display: block;
            margin-top: 18px;
            margin-bottom: 7px;
            font-weight: bold;
        }

        input {
            width: 100%;
            padding: 12px;
            border: 1px solid #ccc;
            border-radius: 6px;
            font-size: 15px;
        }

        button {
            width: 100%;
            margin-top: 24px;
            padding: 13px;
            border: none;
            border-radius: 6px;
            background: #218838;
            color: white;
            font-size: 16px;
            cursor: pointer;
        }

        button:hover {
            background: #19692c;
        }

        .error {
            padding: 10px;
            margin-top: 15px;
            color: #842029;
            background: #f8d7da;
            border-radius: 6px;
        }

        .links {
            margin-top: 20px;
            text-align: center;
        }

        a {
            color: #218838;
            text-decoration: none;
        }
    </style>
</head>

<body>
    <div class="login-container">
        <h1>Welcome Back!</h1>
        <p>Login to SmartFoodDelivery</p>

        <% if (request.getAttribute("errorMessage") != null) { %>
            <div class="error">
                <%= request.getAttribute("errorMessage") %>
            </div>
        <% } %>

        <form action="${pageContext.request.contextPath}/login"
              method="post">

            <label for="email">Email Address</label>
            <input type="email"
                   id="email"
                   name="email"
                   required
                   autocomplete="email">

            <label for="password">Password</label>
            <input type="password"
                   id="password"
                   name="password"
                   required
                   autocomplete="current-password">

            <button type="submit">Login</button>
        </form>

        <div class="links">
            Don't have an account?
            <a href="${pageContext.request.contextPath}/register.jsp">
                Register here
            </a>
            <br><br>
            <a href="${pageContext.request.contextPath}/index.jsp">
                Back to Home
            </a>
        </div>
    </div>
</body>
</html>
