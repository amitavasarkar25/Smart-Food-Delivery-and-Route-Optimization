
package com.smartfood;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/food/menu")
public class FoodServlet extends HttpServlet {

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

        List<java.util.Map<String, Object>> foodItems =
                new ArrayList<>();

        String sql = "SELECT id, name, description, category, price "
                   + "FROM food_items WHERE available = TRUE "
                   + "ORDER BY category, name";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                java.util.Map<String, Object> item =
                        new java.util.HashMap<>();

                item.put("id", rs.getInt("id"));
                item.put("name", rs.getString("name"));
                item.put("description", rs.getString("description"));
                item.put("category", rs.getString("category"));
                item.put("price", rs.getBigDecimal("price"));

                foodItems.add(item);
            }

            request.setAttribute("foodItems", foodItems);
            request.getRequestDispatcher("/food/menu.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            getServletContext().log("Unable to load food menu.", e);
            response.sendError(
                    HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Unable to load the food menu. Please try again.");
        }
    }
}
