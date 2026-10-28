
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registration Successful</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #fff7ed;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
        }

        .card {
            background: white;
            padding: 40px;
            border-radius: 16px;
            text-align: center;
            box-shadow: 0 8px 30px #00000015;
            max-width: 400px;
            margin: 20px;
        }

        h1 { color: #15803d; }

        a {
            display: inline-block;
            background: #ea580c;
            color: white;
            padding: 12px 22px;
            border-radius: 8px;
            text-decoration: none;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>Registration Successful!</h1>
        <p>Your SmartFoodDelivery account has been created.</p>
        <p>You can now continue to the login page.</p>
        <a href="${pageContext.request.contextPath}/login.jsp">
            Go to Login
        </a>
    </div>
</body>
</html>
