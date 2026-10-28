
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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/orders")
public class MyOrdersServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int userId = ((Number) session.getAttribute("userId")).intValue();

        List<Map<String, Object>> orders = new ArrayList<>();

        String sql = "SELECT id, total_amount, status, delivery_address, " +
                     "payment_method, created_at " +
                     "FROM orders WHERE user_id = ? ORDER BY created_at DESC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> order = new HashMap<>();

                    order.put("id", rs.getInt("id"));
                    order.put("total", rs.getBigDecimal("total_amount"));
                    order.put("status", rs.getString("status"));
                    order.put("address", rs.getString("delivery_address"));
                    order.put("payment", rs.getString("payment_method"));
                    order.put("date", rs.getTimestamp("created_at"));

                    orders.add(order);
                }
            }

        } catch (Exception e) {
            throw new ServletException("Unable to load your orders.", e);
        }

        request.setAttribute("orders", orders);

        request.getRequestDispatcher("/orders.jsp")
               .forward(request, response);
    }
}
