
package com.smartfood;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Base64;
import java.util.Locale;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {

    private static final int ITERATIONS = 210000;
    private static final int KEY_LENGTH = 256;

    // Open the registration page.
    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        request.getRequestDispatcher("/register.jsp")
               .forward(request, response);
    }

    // Process registration form submission.
    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String confirmPassword =
                request.getParameter("confirmPassword");

        // Validate empty fields.
        if (name == null || email == null ||
            password == null || confirmPassword == null ||
            name.isBlank() || email.isBlank() ||
            password.isBlank() || confirmPassword.isBlank()) {

            showError(request, response,
                      "All fields are required.");
            return;
        }

        name = name.trim();
        email = email.trim().toLowerCase(Locale.ROOT);

        // Validate name and email length.
        if (name.length() > 100 || email.length() > 100) {
            showError(request, response,
                      "Name or email exceeds the allowed length.");
            return;
        }

        // Validate email format.
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
            showError(request, response,
                      "Please enter a valid email address.");
            return;
        }

        // Validate password length.
        if (password.length() < 8) {
            showError(request, response,
                      "Password must contain at least 8 characters.");
            return;
        }

        // Confirm both passwords match.
        if (!password.equals(confirmPassword)) {
            showError(request, response,
                      "Passwords do not match.");
            return;
        }

        // Hash the password before saving it.
        String hashedPassword;

        try {
            hashedPassword = hashPassword(password);

        } catch (Exception e) {
            getServletContext().log(
                "Password hashing failed.", e
            );

            response.sendError(
                HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                "Unable to process registration right now."
            );
            return;
        }

        // Insert the new customer into MySQL.
        String sql =
            "INSERT INTO users (name, email, password, role) " +
            "VALUES (?, ?, ?, 'CUSTOMER')";

        try (Connection connection = DBConnection.getConnection();
             PreparedStatement statement =
                     connection.prepareStatement(sql)) {

            statement.setString(1, name);
            statement.setString(2, email);
            statement.setString(3, hashedPassword);

            statement.executeUpdate();

            // Registration successful.
            response.sendRedirect(
                request.getContextPath()
                + "/registration-success.jsp"
            );

        } catch (SQLException e) {

            // Handle duplicate email address.
            if ("23000".equals(e.getSQLState())
                    && e.getErrorCode() == 1062) {

                showError(request, response,
                    "This email is already registered. Please log in.");

            } else {

                // TEMPORARY DEBUGGING: identify the real SQL error.
                getServletContext().log(
                    "Database error during registration.", e
                );

                response.setContentType(
                    "text/plain;charset=UTF-8"
                );

                response.setStatus(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR
                );

                response.getWriter().println(
                    "Registration failed: " + e.getMessage()
                );

                response.getWriter().println(
                    "SQL State: " + e.getSQLState()
                );

                response.getWriter().println(
                    "Error Code: " + e.getErrorCode()
                );
            }
        }
    }

    // Generate a salted PBKDF2 password hash.
    private String hashPassword(String password)
            throws Exception {

        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);

        char[] passwordChars = password.toCharArray();

        PBEKeySpec spec = new PBEKeySpec(
            passwordChars,
            salt,
            ITERATIONS,
            KEY_LENGTH
        );

        try {
            SecretKeyFactory factory =
                SecretKeyFactory.getInstance(
                    "PBKDF2WithHmacSHA256"
                );

            byte[] hash =
                factory.generateSecret(spec).getEncoded();

            return "pbkdf2$" + ITERATIONS + "$"
                + Base64.getEncoder().encodeToString(salt) + "$"
                + Base64.getEncoder().encodeToString(hash);

        } finally {
            spec.clearPassword();
            Arrays.fill(passwordChars, '\0');
        }
    }

    // Return validation errors to register.jsp.
    private void showError(HttpServletRequest request,
                           HttpServletResponse response,
                           String message)
            throws ServletException, IOException {

        request.setAttribute("errorMessage", message);

        request.getRequestDispatcher("/register.jsp")
               .forward(request, response);
    }
}
