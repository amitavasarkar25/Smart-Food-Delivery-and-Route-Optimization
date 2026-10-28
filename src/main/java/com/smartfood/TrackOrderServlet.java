
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

@WebServlet("/orders/track")
public class TrackOrderServlet extends HttpServlet {

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = (Integer) session.getAttribute("userId");

        String sql =
                "SELECT o.id, o.total_amount, o.status, "
                + "o.delivery_address, o.payment_method, o.created_at, "
                + "d.name AS delivery_person_name "
                + "FROM orders o "
                + "LEFT JOIN users d ON o.delivery_person_id = d.id "
                + "WHERE o.user_id = ? "
                + "ORDER BY o.created_at DESC";

        String historySql =
                "SELECT status, changed_at "
                + "FROM order_status_history "
                + "WHERE order_id = ? "
                + "ORDER BY changed_at ASC, id ASC";

        List<Map<String, Object>> orders = new ArrayList<>();

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> order = new HashMap<>();

                    int orderId = rs.getInt("id");

                    order.put("id", orderId);
                    order.put("totalAmount",
                            rs.getBigDecimal("total_amount"));
                    order.put("status",
                            rs.getString("status"));
                    order.put("address",
                            rs.getString("delivery_address"));
                    order.put("paymentMethod",
                            rs.getString("payment_method"));
                    order.put("createdAt",
                            rs.getTimestamp("created_at"));
                    order.put("deliveryPersonName",
                            rs.getString("delivery_person_name"));

                    // Load the chronological status history for this order.
                    List<Map<String, Object>> statusHistory =
                            new ArrayList<>();

                    try (PreparedStatement historyPs =
                                 con.prepareStatement(historySql)) {

                        historyPs.setInt(1, orderId);

                        try (ResultSet historyRs =
                                     historyPs.executeQuery()) {

                            while (historyRs.next()) {
                                Map<String, Object> event =
                                        new HashMap<>();

                                event.put(
                                        "status",
                                        historyRs.getString("status"));

                                event.put(
                                        "changedAt",
                                        historyRs.getTimestamp("changed_at"));

                                statusHistory.add(event);
                            }
                        }
                    }

                    // Backward compatibility for orders created before
                    // status history was introduced.
                    if (statusHistory.isEmpty()) {
                        Map<String, Object> initialEvent =
                                new HashMap<>();

                        initialEvent.put("status", "PLACED");
                        initialEvent.put(
                                "changedAt",
                                rs.getTimestamp("created_at"));

                        statusHistory.add(initialEvent);
                    }

                    order.put("statusHistory", statusHistory);

                    orders.add(order);
                }
            }

            request.setAttribute("orders", orders);

            request.getRequestDispatcher(
                    "/customer/track-orders.jsp")
                    .forward(request, response);

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to load tracked orders.", e);

            throw new ServletException(
                    "Unable to load your orders.", e);
        }
    }
}
