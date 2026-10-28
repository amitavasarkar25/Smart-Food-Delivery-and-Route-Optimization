
package com.smartfood;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/admin/dashboard")
public class AdminServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        if (!"ADMIN".equals(session.getAttribute("userRole"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN,
                    "Administrator permission required.");
            return;
        }

        int totalOrders = 0;
        int pendingOrders = 0;
        int completedOrders = 0;
        BigDecimal totalSales = BigDecimal.ZERO;

        String sql =
                "SELECT COUNT(*) AS total_orders, " +
                "COALESCE(SUM(CASE WHEN status IN " +
                "('PLACED','PREPARING','OUT_FOR_DELIVERY') " +
                "THEN 1 ELSE 0 END),0) AS pending_orders, " +
                "COALESCE(SUM(CASE WHEN status = 'DELIVERED' " +
                "THEN 1 ELSE 0 END),0) AS completed_orders, " +
                "COALESCE(SUM(CASE WHEN status = 'DELIVERED' " +
                "THEN total_amount ELSE 0 END),0) AS total_sales " +
                "FROM orders";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                totalOrders = rs.getInt("total_orders");
                pendingOrders = rs.getInt("pending_orders");
                completedOrders = rs.getInt("completed_orders");
                totalSales = rs.getBigDecimal("total_sales");
            }

        } catch (Exception e) {
            throw new ServletException(
                    "Unable to load admin dashboard.", e);
        }

        request.setAttribute("totalOrders", totalOrders);
        request.setAttribute("pendingOrders", pendingOrders);
        request.setAttribute("completedOrders", completedOrders);
        request.setAttribute("totalSales", totalSales);

        request.getRequestDispatcher("/admin/dashboard.jsp")
               .forward(request, response);
    }
}
