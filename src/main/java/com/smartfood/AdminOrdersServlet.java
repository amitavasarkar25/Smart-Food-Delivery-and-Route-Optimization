
package com.smartfood;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/orders")
public class AdminOrdersServlet extends HttpServlet {

    private boolean isAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        return session != null
                && session.getAttribute("userId") != null
                && "ADMIN".equalsIgnoreCase(
                        String.valueOf(session.getAttribute("userRole")));
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Admin access required.");
            return;
        }

        List<Map<String, Object>> orders = new ArrayList<>();
        List<Map<String, Object>> deliveryStaff = new ArrayList<>();

        String orderSql =
                "SELECT o.id, u.name AS customer_name, "
                + "u.email AS customer_email, o.total_amount, o.status, "
                + "o.delivery_address, o.payment_method, o.created_at, "
                + "o.delivery_person_id, "
                + "d.name AS delivery_person_name "
                + "FROM orders o "
                + "JOIN users u ON o.user_id = u.id "
                + "LEFT JOIN users d ON o.delivery_person_id = d.id "
                + "ORDER BY o.created_at DESC";

        String staffSql =
                "SELECT id, name, email "
                + "FROM users "
                + "WHERE role = 'DELIVERY' "
                + "ORDER BY name";

        try (Connection con = DBConnection.getConnection()) {

            // Load orders and their assigned delivery persons.
            try (PreparedStatement ps = con.prepareStatement(orderSql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> order = new HashMap<>();

                    order.put("id", rs.getInt("id"));
                    order.put("customerName",
                            rs.getString("customer_name"));
                    order.put("customerEmail",
                            rs.getString("customer_email"));
                    order.put("totalAmount",
                            rs.getBigDecimal("total_amount"));
                    order.put("status", rs.getString("status"));
                    order.put("address",
                            rs.getString("delivery_address"));
                    order.put("paymentMethod",
                            rs.getString("payment_method"));
                    order.put("createdAt",
                            rs.getTimestamp("created_at"));

                    int deliveryPersonId =
                            rs.getInt("delivery_person_id");

                    if (rs.wasNull()) {
                        order.put("deliveryPersonId", null);
                    } else {
                        order.put("deliveryPersonId", deliveryPersonId);
                    }

                    order.put("deliveryPersonName",
                            rs.getString("delivery_person_name"));

                    orders.add(order);
                }
            }

            // Load registered delivery staff.
            try (PreparedStatement ps = con.prepareStatement(staffSql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> staff = new HashMap<>();

                    staff.put("id", rs.getInt("id"));
                    staff.put("name", rs.getString("name"));
                    staff.put("email", rs.getString("email"));

                    deliveryStaff.add(staff);
                }
            }

            request.setAttribute("orders", orders);
            request.setAttribute("deliveryStaff", deliveryStaff);

            request.getRequestDispatcher("/admin/orders.jsp")
                    .forward(request, response);

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to load admin orders.", e);

            throw new ServletException(
                    "Unable to load admin orders.", e);
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Admin access required.");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        String orderIdText = request.getParameter("orderId");

        if (orderIdText == null
                || !orderIdText.matches("[0-9]+")) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid order ID.");
            return;
        }

        try {
            int orderId = Integer.parseInt(orderIdText);

            if (orderId <= 0) {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Invalid order ID.");
                return;
            }

            // DELIVERY ASSIGNMENT
            if ("assignDelivery".equals(action)) {

                String deliveryIdText =
                        request.getParameter("deliveryPersonId");

                Integer deliveryPersonId = null;

                // An empty selection means unassign the delivery person.
                if (deliveryIdText != null
                        && !deliveryIdText.trim().isEmpty()) {

                    if (!deliveryIdText.matches("[0-9]+")) {
                        response.sendError(
                                HttpServletResponse.SC_BAD_REQUEST,
                                "Invalid delivery person ID.");
                        return;
                    }

                    deliveryPersonId =
                            Integer.parseInt(deliveryIdText);

                    if (deliveryPersonId <= 0) {
                        response.sendError(
                                HttpServletResponse.SC_BAD_REQUEST,
                                "Invalid delivery person ID.");
                        return;
                    }
                }

                try (Connection con = DBConnection.getConnection()) {

                    // Verify that the selected user is delivery staff.
                    if (deliveryPersonId != null) {

                        String staffSql =
                                "SELECT id FROM users "
                                + "WHERE id = ? AND role = 'DELIVERY'";

                        try (PreparedStatement ps =
                                     con.prepareStatement(staffSql)) {

                            ps.setInt(1, deliveryPersonId);

                            try (ResultSet rs = ps.executeQuery()) {
                                if (!rs.next()) {
                                    response.sendError(
                                            HttpServletResponse.SC_BAD_REQUEST,
                                            "Selected delivery staff account "
                                            + "does not exist.");
                                    return;
                                }
                            }
                        }
                    }

                    String updateSql =
                            "UPDATE orders SET delivery_person_id = ? "
                            + "WHERE id = ?";

                    try (PreparedStatement ps =
                                 con.prepareStatement(updateSql)) {

                        if (deliveryPersonId == null) {
                            ps.setNull(1, Types.INTEGER);
                        } else {
                            ps.setInt(1, deliveryPersonId);
                        }

                        ps.setInt(2, orderId);

                        int updated = ps.executeUpdate();

                        if (updated == 0) {
                            response.sendError(
                                    HttpServletResponse.SC_NOT_FOUND,
                                    "Order not found.");
                            return;
                        }
                    }
                }

                response.sendRedirect(
                        request.getContextPath() + "/admin/orders");
                return;
            }

            // ORDER STATUS UPDATE WITH HISTORY
            String newStatus = request.getParameter("status");

            String[] allowedStatuses = {
                "PLACED",
                "PREPARING",
                "OUT_FOR_DELIVERY",
                "DELIVERED"
            };

            boolean validStatus = false;

            if (newStatus != null) {
                for (String status : allowedStatuses) {
                    if (status.equals(newStatus)) {
                        validStatus = true;
                        break;
                    }
                }
            }

            if (!validStatus) {
                response.sendError(
                        HttpServletResponse.SC_BAD_REQUEST,
                        "Invalid order status.");
                return;
            }

            try (Connection con = DBConnection.getConnection()) {

                boolean originalAutoCommit = con.getAutoCommit();

                try {
                    con.setAutoCommit(false);

                    String currentStatus = null;

                    // Lock the order row to prevent concurrent status updates.
                    String selectSql =
                            "SELECT status FROM orders "
                            + "WHERE id = ? FOR UPDATE";

                    try (PreparedStatement ps =
                                 con.prepareStatement(selectSql)) {

                        ps.setInt(1, orderId);

                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                currentStatus = rs.getString("status");
                            }
                        }
                    }

                    if (currentStatus == null) {
                        con.rollback();

                        response.sendError(
                                HttpServletResponse.SC_NOT_FOUND,
                                "Order not found.");
                        return;
                    }

                    // Only update and record history if the status changed.
                    if (!newStatus.equals(currentStatus)) {

                        String updateSql =
                                "UPDATE orders SET status = ? WHERE id = ?";

                        try (PreparedStatement ps =
                                     con.prepareStatement(updateSql)) {

                            ps.setString(1, newStatus);
                            ps.setInt(2, orderId);

                            ps.executeUpdate();
                        }

                        String historySql =
                                "INSERT INTO order_status_history "
                                + "(order_id, status) VALUES (?, ?)";

                        try (PreparedStatement ps =
                                     con.prepareStatement(historySql)) {

                            ps.setInt(1, orderId);
                            ps.setString(2, newStatus);

                            ps.executeUpdate();
                        }
                    }

                    // Save the order update and history together.
                    con.commit();

                } catch (Exception e) {
                    try {
                        con.rollback();
                    } catch (Exception rollbackError) {
                        e.addSuppressed(rollbackError);
                    }

                    throw e;

                } finally {
                    try {
                        con.setAutoCommit(originalAutoCommit);
                    } catch (Exception resetError) {
                        getServletContext().log(
                                "Unable to restore database auto-commit.",
                                resetError);
                    }
                }
            }

            response.sendRedirect(
                    request.getContextPath() + "/admin/orders");

        } catch (NumberFormatException e) {
            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid numeric value.");

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to process admin order action.", e);

            throw new ServletException(
                    "Unable to process admin order action.", e);
        }
    }
}
