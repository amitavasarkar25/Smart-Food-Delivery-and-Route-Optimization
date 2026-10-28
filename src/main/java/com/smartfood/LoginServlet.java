
package com.smartfood;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher("/login.jsp")
               .forward(request, response);
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || email.trim().isEmpty()
                || password == null || password.isEmpty()) {

            request.setAttribute(
                    "errorMessage",
                    "Please enter your email and password.");

            request.getRequestDispatcher("/login.jsp")
                   .forward(request, response);
            return;
        }

        String sql = "SELECT id, name, email, password, role "
                   + "FROM users WHERE email = ?";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, email.trim());

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()
                        && PasswordUtil.verifyPassword(
                                password, rs.getString("password"))) {

                    String role = rs.getString("role");

                    // Allow only supported application roles.
                    if (!"ADMIN".equalsIgnoreCase(role)
                            && !"CUSTOMER".equalsIgnoreCase(role)
                            && !"DELIVERY".equalsIgnoreCase(role)) {

                        request.setAttribute(
                                "errorMessage",
                                "Your account role is not supported on this login page.");

                        request.getRequestDispatcher("/login.jsp")
                               .forward(request, response);
                        return;
                    }

                    // Prevent session fixation after successful login.
                    HttpSession existingSession =
                            request.getSession(false);

                    if (existingSession != null) {
                        existingSession.invalidate();
                    }

                    HttpSession session = request.getSession(true);

                    session.setAttribute("userId", rs.getInt("id"));
                    session.setAttribute("userName", rs.getString("name"));
                    session.setAttribute("userEmail", rs.getString("email"));
                    session.setAttribute("userRole", role.toUpperCase());

                    session.setMaxInactiveInterval(30 * 60);

                    // Redirect according to the user's database role.
                    if ("ADMIN".equalsIgnoreCase(role)) {

                        response.sendRedirect(
                                request.getContextPath()
                                + "/admin/dashboard");

                    } else if ("CUSTOMER".equalsIgnoreCase(role)) {

                        response.sendRedirect(
                                request.getContextPath()
                                + "/customer/dashboard.jsp");

                    } else if ("DELIVERY".equalsIgnoreCase(role)) {

                        response.sendRedirect(
                                request.getContextPath()
                                + "/delivery/dashboard");
                    }

                } else {

                    request.setAttribute(
                            "errorMessage",
                            "Invalid email or password.");

                    request.getRequestDispatcher("/login.jsp")
                           .forward(request, response);
                }
            }

        } catch (Exception e) {

            getServletContext().log(
                    "Login failed due to a server error.", e);

            response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR);

            request.setAttribute(
                    "errorMessage",
                    "Unable to log in right now. Please try again.");

            request.getRequestDispatcher("/login.jsp")
                   .forward(request, response);
        }
    }
}
