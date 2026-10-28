
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

@WebServlet("/profile/update")
public class UpdateProfileServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html;charset=UTF-8");

        String context = request.getContextPath();
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(context + "/login.jsp");
            return;
        }

        if (!"CUSTOMER".equals(session.getAttribute("userRole"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                               "Only customers can update this profile.");
            return;
        }

        String name = request.getParameter("name");
        String email = request.getParameter("email");

        if (name == null || email == null) {
            response.sendRedirect(context + "/profile.jsp?error=invalid");
            return;
        }

        name = name.trim();
        email = email.trim().toLowerCase(java.util.Locale.ROOT);

        if (name.isEmpty() || name.length() > 100
                || !email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")
                || email.length() > 100) {

            response.sendRedirect(context + "/profile.jsp?error=invalid");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");

        try (Connection con = DBConnection.getConnection()) {

            // Check whether another user already uses this email.
            String checkSql =
                "SELECT id FROM users WHERE email = ? AND id <> ?";

            try (PreparedStatement check =
                    con.prepareStatement(checkSql)) {

                check.setString(1, email);
                check.setInt(2, userId);

                try (ResultSet rs = check.executeQuery()) {
                    if (rs.next()) {
                        response.sendRedirect(
                            context + "/profile.jsp?error=email");
                        return;
                    }
                }
            }

            String updateSql =
                "UPDATE users SET name = ?, email = ? WHERE id = ?";

            try (PreparedStatement update =
                    con.prepareStatement(updateSql)) {

                update.setString(1, name);
                update.setString(2, email);
                update.setInt(3, userId);

                int rows = update.executeUpdate();

                if (rows == 0) {
                    response.sendRedirect(
                        context + "/profile.jsp?error=notfound");
                    return;
                }
            }

            // Refresh the session values used by the dashboard.
            session.setAttribute("userName", name);
            session.setAttribute("userEmail", email);

            response.sendRedirect(context + "/profile.jsp?updated=1");

        } catch (java.sql.SQLException e) {
            throw new ServletException("Unable to update profile.", e);
        }
    }
}
