
package com.smartfood;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet("/delivery/location/update")
public class DeliveryLocationServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("userId") == null
                || !"DELIVERY".equalsIgnoreCase(
                        String.valueOf(session.getAttribute("userRole")))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            writeJson(response, false, "Delivery login required.");
            return;
        }

        int deliveryPersonId;
        int orderId;
        BigDecimal latitude;
        BigDecimal longitude;

        try {
            deliveryPersonId = Integer.parseInt(
                    String.valueOf(session.getAttribute("userId")));
            orderId = Integer.parseInt(request.getParameter("orderId"));
            latitude = new BigDecimal(request.getParameter("latitude"));
            longitude = new BigDecimal(request.getParameter("longitude"));

            if (orderId <= 0
                    || latitude.compareTo(new BigDecimal("-90")) < 0
                    || latitude.compareTo(new BigDecimal("90")) > 0
                    || longitude.compareTo(new BigDecimal("-180")) < 0
                    || longitude.compareTo(new BigDecimal("180")) > 0) {
                throw new IllegalArgumentException("Invalid coordinates.");
            }
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            writeJson(response, false, "Invalid order ID or GPS coordinates.");
            return;
        }

        String assignmentSql =
                "SELECT id FROM orders "
                + "WHERE id = ? AND delivery_person_id = ? "
                + "AND status = 'OUT_FOR_DELIVERY'";

        String upsertSql =
                "INSERT INTO delivery_locations "
                + "(order_id, delivery_person_id, latitude, longitude) "
                + "VALUES (?, ?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE "
                + "delivery_person_id = VALUES(delivery_person_id), "
                + "latitude = VALUES(latitude), "
                + "longitude = VALUES(longitude), "
                + "updated_at = CURRENT_TIMESTAMP";

        try (Connection con = DBConnection.getConnection()) {

            // Confirm this delivery person owns this active delivery.
            try (PreparedStatement ps = con.prepareStatement(assignmentSql)) {
                ps.setInt(1, orderId);
                ps.setInt(2, deliveryPersonId);

                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                        writeJson(response, false,
                                "Order is not assigned to you or is not out for delivery.");
                        return;
                    }
                }
            }

            try (PreparedStatement ps = con.prepareStatement(upsertSql)) {
                ps.setInt(1, orderId);
                ps.setInt(2, deliveryPersonId);
                ps.setBigDecimal(3, latitude);
                ps.setBigDecimal(4, longitude);
                ps.executeUpdate();
            }

            writeJson(response, true, "Location updated.");

        } catch (SQLException e) {
            getServletContext().log("Failed to save delivery GPS location.", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            writeJson(response, false, "Could not save location.");
        }
    }

    private void writeJson(HttpServletResponse response,
                           boolean success, String message)
            throws IOException {

        // Escape strings before returning JSON.
        String safeMessage = message
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");

        try (PrintWriter out = response.getWriter()) {
            out.print("{\"success\":" + success
                    + ",\"message\":\"" + safeMessage + "\"}");
        }
    }
}
