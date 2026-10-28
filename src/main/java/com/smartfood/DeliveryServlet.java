
package com.smartfood;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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

@WebServlet("/delivery/dashboard")
public class DeliveryServlet extends HttpServlet {

    private boolean isDelivery(HttpServletRequest request,
                               HttpServletResponse response)
            throws IOException {

        HttpSession session = request.getSession(false);

        if (session == null
                || session.getAttribute("userId") == null
                || !"DELIVERY".equals(session.getAttribute("userRole"))) {

            response.sendRedirect(
                    request.getContextPath() + "/login.jsp");
            return false;
        }

        return true;
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        if (!isDelivery(request, response)) {
            return;
        }

        HttpSession session = request.getSession(false);
        int deliveryPersonId =
                (Integer) session.getAttribute("userId");

        List<Map<String, Object>> orders = new ArrayList<>();

        String sql =
                "SELECT o.id, o.total_amount, o.status, "
              + "o.delivery_address, o.payment_method, o.created_at, "
              + "u.name AS customer_name, u.email AS customer_email "
              + "FROM orders o "
              + "JOIN users u ON o.user_id = u.id "
              + "WHERE o.delivery_person_id = ? "
              + "ORDER BY o.created_at DESC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, deliveryPersonId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> order = new HashMap<>();

                    order.put("id", rs.getInt("id"));
                    order.put("totalAmount",
                            rs.getBigDecimal("total_amount"));
                    order.put("status", rs.getString("status"));
                    order.put("address",
                            rs.getString("delivery_address"));
                    order.put("paymentMethod",
                            rs.getString("payment_method"));
                    order.put("createdAt",
                            rs.getTimestamp("created_at"));
                    order.put("customerName",
                            rs.getString("customer_name"));
                    order.put("customerEmail",
                            rs.getString("customer_email"));

                    orders.add(order);
                }
            }

            request.setAttribute("orders", orders);
            request.getRequestDispatcher("/delivery/dashboard.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to load delivery dashboard.", e);

            throw new ServletException(
                    "Unable to load delivery dashboard.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        if (!isDelivery(request, response)) {
            return;
        }

        HttpSession session = request.getSession(false);
        int deliveryPersonId =
                (Integer) session.getAttribute("userId");

        String orderIdText = request.getParameter("orderId");
        String newStatus = request.getParameter("status");

        if (orderIdText == null || newStatus == null
                || !("OUT_FOR_DELIVERY".equals(newStatus)
                || "DELIVERED".equals(newStatus))) {

            response.sendRedirect(
                    request.getContextPath() + "/delivery/dashboard");
            return;
        }

        int orderId;

        try {
            orderId = Integer.parseInt(orderIdText);

            if (orderId <= 0) {
                throw new NumberFormatException();
            }
        } catch (NumberFormatException e) {
            response.sendRedirect(
                    request.getContextPath() + "/delivery/dashboard");
            return;
        }

        try (Connection con = DBConnection.getConnection()) {

            boolean originalAutoCommit = con.getAutoCommit();

            try {
                con.setAutoCommit(false);

                String currentStatus = null;

                // Lock and verify that this order belongs to this
                // delivery person.
                String selectSql =
                        "SELECT status FROM orders "
                      + "WHERE id = ? AND delivery_person_id = ? "
                      + "FOR UPDATE";

                try (PreparedStatement ps =
                             con.prepareStatement(selectSql)) {

                    ps.setInt(1, orderId);
                    ps.setInt(2, deliveryPersonId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            currentStatus = rs.getString("status");
                        }
                    }
                }

                // Do not allow changes to unassigned or other staff's orders.
                if (currentStatus == null) {
                    con.rollback();

                    session.setAttribute(
                            "deliveryMessage",
                            "Order could not be updated. Check its assignment.");

                } else if (!("PLACED".equals(currentStatus)
                        || "PREPARING".equals(currentStatus)
                        || "OUT_FOR_DELIVERY".equals(currentStatus))) {

                    con.rollback();

                    session.setAttribute(
                            "deliveryMessage",
                            "Order could not be updated from its current status.");

                } else if ("DELIVERED".equals(currentStatus)
                        && "DELIVERED".equals(newStatus)) {

                    con.rollback();

                    session.setAttribute(
                            "deliveryMessage",
                            "This order has already been delivered.");

                } else if (newStatus.equals(currentStatus)) {

                    // Do not create duplicate history entries when
                    // the requested status is already current.
                    con.commit();

                    session.setAttribute(
                            "deliveryMessage",
                            "Order #" + orderId
                            + " already has status " + currentStatus + ".");

                } else {

                    // Update the order status.
                    String updateSql =
                            "UPDATE orders SET status = ? "
                          + "WHERE id = ? AND delivery_person_id = ?";

                    try (PreparedStatement ps =
                                 con.prepareStatement(updateSql)) {

                        ps.setString(1, newStatus);
                        ps.setInt(2, orderId);
                        ps.setInt(3, deliveryPersonId);

                        int updated = ps.executeUpdate();

                        if (updated != 1) {
                            throw new ServletException(
                                    "Order status update failed.");
                        }
                    }

                    // Record the new status and timestamp.
                    String historySql =
                            "INSERT INTO order_status_history "
                          + "(order_id, status) VALUES (?, ?)";

                    try (PreparedStatement ps =
                                 con.prepareStatement(historySql)) {

                        ps.setInt(1, orderId);
                        ps.setString(2, newStatus);
                        ps.executeUpdate();
                    }

                    // Commit the order update and history together.
                    con.commit();

                    session.setAttribute(
                            "deliveryMessage",
                            "Order #" + orderId
                            + " updated successfully to " + newStatus + ".");
                }

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

            response.sendRedirect(
                    request.getContextPath() + "/delivery/dashboard");

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to update delivery order status.", e);

            throw new ServletException(
                    "Unable to update delivery order status.", e);
        }
    }
}
