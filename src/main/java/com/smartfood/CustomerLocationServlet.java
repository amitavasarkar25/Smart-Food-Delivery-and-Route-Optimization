package com.smartfood;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;

@WebServlet("/orders/location")
public class CustomerLocationServlet extends HttpServlet {

    private String jsonEscape(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\n", "\\n")
                    .replace("\r", "\\r")
                    .replace("\t", "\\t");
    }

    private void sendJson(HttpServletResponse response, int statusCode, String json)
            throws IOException {
        response.setStatus(statusCode);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(json);
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        response.setHeader("Pragma", "no-cache");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            sendJson(response, HttpServletResponse.SC_UNAUTHORIZED,
                    "{\"success\":false,\"message\":\"Please log in again.\"}");
            return;
        }

        String role = String.valueOf(session.getAttribute("userRole"));
        if (!"CUSTOMER".equals(role)) {
            sendJson(response, HttpServletResponse.SC_FORBIDDEN,
                    "{\"success\":false,\"message\":\"Access denied.\"}");
            return;
        }

        int userId;
        int orderId;
        try {
            userId = Integer.parseInt(String.valueOf(session.getAttribute("userId")));
            orderId = Integer.parseInt(request.getParameter("orderId"));
            if (orderId <= 0) throw new NumberFormatException();
        } catch (Exception e) {
            sendJson(response, HttpServletResponse.SC_BAD_REQUEST,
                    "{\"success\":false,\"message\":\"Invalid order ID.\"}");
            return;
        }

        String sql =
            "SELECT o.status, dl.latitude, dl.longitude, dl.updated_at " +
            "FROM orders o " +
            "LEFT JOIN delivery_locations dl " +
            "  ON dl.order_id = o.id " +
            " AND dl.delivery_person_id = o.delivery_person_id " +
            "WHERE o.id = ? AND o.user_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, orderId);
            ps.setInt(2, userId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    sendJson(response, HttpServletResponse.SC_NOT_FOUND,
                            "{\"success\":false,\"message\":\"Order not found.\"}");
                    return;
                }

                String status = rs.getString("status");
                java.math.BigDecimal latitude = rs.getBigDecimal("latitude");
                java.math.BigDecimal longitude = rs.getBigDecimal("longitude");
                Timestamp updatedAt = rs.getTimestamp("updated_at");

                boolean hasLocation = latitude != null && longitude != null;
                StringBuilder json = new StringBuilder();
                json.append("{\"success\":true");
                json.append(",\"status\":\"").append(jsonEscape(status)).append("\"");

                if (hasLocation) {
                    json.append(",\"latitude\":").append(latitude.toPlainString());
                    json.append(",\"longitude\":").append(longitude.toPlainString());
                } else {
                    json.append(",\"latitude\":null,\"longitude\":null");
                }

                if (updatedAt != null) {
                    json.append(",\"updatedAt\":\"")
                        .append(jsonEscape(updatedAt.toInstant().toString())).append("\"");
                } else {
                    json.append(",\"updatedAt\":null");
                }

                if ("DELIVERED".equalsIgnoreCase(status)) {
                    json.append(",\"message\":\"Order delivered.\"");
                } else if ("OUT_FOR_DELIVERY".equalsIgnoreCase(status) && !hasLocation) {
                    json.append(",\"message\":\"Waiting for the delivery person's GPS location...\"");
                } else if (!"OUT_FOR_DELIVERY".equalsIgnoreCase(status)) {
                    json.append(",\"message\":\"Live GPS tracking starts when the order is out for delivery.\"");
                }

                json.append("}");
                sendJson(response, HttpServletResponse.SC_OK, json.toString());
            }

        } catch (Exception e) {
            getServletContext().log("Error retrieving customer order location.", e);
            sendJson(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "{\"success\":false,\"message\":\"Unable to retrieve order tracking information.\"}");
        }
    }
}
