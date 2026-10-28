
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SmartFoodDelivery</title>

    <style>
        * {
            box-sizing: border-box;
            font-family: Arial, sans-serif;
        }

        body {
            margin: 0;
            background: #f7f8fa;
            color: #222;
        }

        nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 20px 8%;
            background: white;
            box-shadow: 0 2px 8px #ddd;
        }

        .logo {
            font-size: 24px;
            font-weight: bold;
            color: #e85d04;
        }

        nav a {
            margin-left: 18px;
            color: #333;
            text-decoration: none;
        }

        .hero {
            min-height: 65vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
            padding: 35px 20px;
            background: linear-gradient(135deg, #fff0e4, white);
        }

        .hero h1 {
            font-size: clamp(34px, 5vw, 56px);
            margin-bottom: 15px;
        }

        .hero h1 span {
            color: #e85d04;
        }

        .hero p {
            max-width: 600px;
            color: #666;
            line-height: 1.7;
            margin-bottom: 28px;
        }

        .btn {
            display: inline-block;
            padding: 14px 25px;
            border-radius: 7px;
            background: #e85d04;
            color: white;
            text-decoration: none;
            font-weight: bold;
        }

        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 20px;
            padding: 40px 8%;
        }

        .feature {
            padding: 25px;
            background: white;
            border-radius: 12px;
            box-shadow: 0 3px 12px #ddd;
        }

        .feature h3 {
            color: #e85d04;
        }

        .feature p {
            color: #666;
            line-height: 1.6;
        }

        footer {
            text-align: center;
            padding: 22px;
            color: #777;
        }

        @media (max-width: 600px) {
            nav {
                flex-direction: column;
                gap: 15px;
            }

            nav a {
                margin: 0 7px;
            }
        }
    </style>
</head>

<body>
    <nav>
        <div class="logo">SmartFoodDelivery</div>

        <div>
            <a href="index.jsp">Home</a>
            <a href="#features">Features</a>
            <a href="login.jsp">Login</a>
            <a href="register.jsp">Register</a>
        </div>
    </nav>

    <section class="hero">
        <h1>Food Delivered <span>Smarter.</span></h1>

        <p>
            Order your favourite food with ease.
            Discover smarter delivery routes, convenient ordering,
            and order tracking with SmartFoodDelivery.
        </p>

        <a href="register.jsp" class="btn">Get Started</a>
    </section>

    <section class="features" id="features">
        <div class="feature">
            <h3>🍔 Easy Ordering</h3>
            <p>Browse food items and place orders through a simple interface.</p>
        </div>

        <div class="feature">
            <h3>📍 Route Optimization</h3>
            <p>Plan efficient delivery routes and reduce travel distance.</p>
        </div>

        <div class="feature">
            <h3>🚚 Order Tracking</h3>
            <p>Track orders from placement through delivery.</p>
        </div>
    </section>

    <footer>
        &copy; 2026 SmartFoodDelivery
    </footer>
</body>
</html>

<%
    String loggedInName = (String) session.getAttribute("userName");
%>

<% if (loggedInName != null) { %>
    <span>Welcome, <%= loggedInName %>!</span>
    <a href="${pageContext.request.contextPath}/logout">Logout</a>
<% } else { %>
    <a href="${pageContext.request.contextPath}/login.jsp">Login</a>
    <a href="${pageContext.request.contextPath}/register.jsp">Register</a>
<% } %>
