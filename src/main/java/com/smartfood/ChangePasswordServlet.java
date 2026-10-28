
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

@WebServlet("/profile/change-password")
public class ChangePasswordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String context = request.getContextPath();
        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(context + "/login.jsp");
            return;
        }

        if (!"CUSTOMER".equals(session.getAttribute("userRole"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Only customers can change their password here.");
            return;
        }

        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        if (currentPassword == null || newPassword == null
                || confirmPassword == null
                || currentPassword.isEmpty()
                || newPassword.isEmpty()
                || confirmPassword.isEmpty()) {

            response.sendRedirect(
                    context + "/change-password.jsp?error=missing");
            return;
        }

        if (newPassword.length() < 8 || newPassword.length() > 128) {
            response.sendRedirect(
                    context + "/change-password.jsp?error=length");
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            response.sendRedirect(
                    context + "/change-password.jsp?error=mismatch");
            return;
        }

        if (currentPassword.equals(newPassword)) {
            response.sendRedirect(
                    context + "/change-password.jsp?error=same");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");

        try (Connection con = DBConnection.getConnection()) {

            String storedHash;

            String selectSql =
                    "SELECT password FROM users WHERE id = ?";

            try (PreparedStatement ps = con.prepareStatement(selectSql)) {
                ps.setInt(1, userId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        response.sendRedirect(
                                context + "/change-password.jsp?error=account");
                        return;
                    }

                    storedHash = rs.getString("password");
                }
            }

            // Verify the current password using your existing utility.
            if (!PasswordUtil.verifyPassword(
                    currentPassword, storedHash)) {

                response.sendRedirect(
                        context + "/change-password.jsp?error=current");
                return;
            }

            // Hash the new password before saving it.
            String newHash = PasswordUtil.hashPassword(newPassword);

            String updateSql =
                    "UPDATE users SET password = ? WHERE id = ?";

            try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                ps.setString(1, newHash);
                ps.setInt(2, userId);

                if (ps.executeUpdate() != 1) {
                    response.sendRedirect(
                            context + "/change-password.jsp?error=account");
                    return;
                }
            }

            response.sendRedirect(
                    context + "/change-password.jsp?success=1");

        } catch (java.sql.SQLException e) {
            throw new ServletException("Unable to change password.", e);
        }
    }
}
