
package com.smartfood;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/admin/food-menu")
public class AdminFoodServlet extends HttpServlet {

    private boolean isAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);

        return session != null
                && session.getAttribute("userId") != null
                && "ADMIN".equals(session.getAttribute("userRole"));
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAdmin(request)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Admin access required."
            );
            return;
        }

        List<Map<String, Object>> foodItems = new ArrayList<>();

        String sql = "SELECT id, name, description, category, price, "
                   + "image_url, available "
                   + "FROM food_items ORDER BY id DESC";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> item = new LinkedHashMap<>();

                item.put("id", rs.getInt("id"));
                item.put("name", rs.getString("name"));
                item.put("description", rs.getString("description"));
                item.put("category", rs.getString("category"));
                item.put("price", rs.getBigDecimal("price"));
                item.put("image_url", rs.getString("image_url"));
                item.put("available", rs.getBoolean("available"));

                foodItems.add(item);
            }

        } catch (SQLException e) {
            throw new ServletException(
                    "Unable to load food menu.", e);
        }

        request.setAttribute("foodItems", foodItems);

        request.getRequestDispatcher(
                "/admin/food-menu.jsp"
        ).forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String context = request.getContextPath();

        if (!isAdmin(request)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Admin access required."
            );
            return;
        }

        String action = request.getParameter("action");

        if (action == null) {
            response.sendRedirect(
                    context + "/admin/food-menu?error=action");
            return;
        }

        try (Connection con = DBConnection.getConnection()) {

            switch (action) {
                case "add":
                    addFood(request, con);
                    response.sendRedirect(
                            context + "/admin/food-menu?success=added");
                    break;

                case "update":
                    updateFood(request, con);
                    response.sendRedirect(
                            context + "/admin/food-menu?success=updated");
                    break;

                case "toggle":
                    toggleAvailability(request, con);
                    response.sendRedirect(
                            context + "/admin/food-menu?success=toggled");
                    break;

                default:
                    response.sendRedirect(
                            context + "/admin/food-menu?error=action");
            }

        } catch (IllegalArgumentException e) {
            response.sendRedirect(
                    context + "/admin/food-menu?error=invalid");

        } catch (SQLException e) {
            throw new ServletException(
                    "Unable to update the food menu.", e);
        }
    }

    private void addFood(HttpServletRequest request, Connection con)
            throws SQLException {

        String name = requiredText(
                request.getParameter("name"), 150);

        String description = optionalText(
                request.getParameter("description"), 500);

        String category = optionalText(
                request.getParameter("category"), 100);

        String imageUrl = optionalText(
                request.getParameter("image_url"), 500);

        BigDecimal price = parsePrice(
                request.getParameter("price"));

        String sql = "INSERT INTO food_items "
                   + "(name, description, category, price, image_url, available) "
                   + "VALUES (?, ?, ?, ?, ?, TRUE)";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, description);
            ps.setString(3, category);
            ps.setBigDecimal(4, price);
            ps.setString(5, imageUrl);

            ps.executeUpdate();
        }
    }

    private void updateFood(HttpServletRequest request, Connection con)
            throws SQLException {

        int id = parseId(request.getParameter("id"));

        String name = requiredText(
                request.getParameter("name"), 150);

        String description = optionalText(
                request.getParameter("description"), 500);

        String category = optionalText(
                request.getParameter("category"), 100);

        String imageUrl = optionalText(
                request.getParameter("image_url"), 500);

        BigDecimal price = parsePrice(
                request.getParameter("price"));

        String sql = "UPDATE food_items "
                   + "SET name = ?, description = ?, category = ?, "
                   + "price = ?, image_url = ? WHERE id = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, description);
            ps.setString(3, category);
            ps.setBigDecimal(4, price);
            ps.setString(5, imageUrl);
            ps.setInt(6, id);

            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException(
                        "Food item not found.");
            }
        }
    }

    private void toggleAvailability(
            HttpServletRequest request, Connection con)
            throws SQLException {

        int id = parseId(request.getParameter("id"));

        String sql = "UPDATE food_items "
                   + "SET available = NOT available WHERE id = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);

            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException(
                        "Food item not found.");
            }
        }
    }

    private int parseId(String value) {
        try {
            int id = Integer.parseInt(value);

            if (id <= 0) {
                throw new NumberFormatException();
            }

            return id;

        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Invalid food ID.");
        }
    }

    private BigDecimal parsePrice(String value) {
        try {
            BigDecimal price = new BigDecimal(value);

            if (price.compareTo(BigDecimal.ZERO) <= 0
                    || price.compareTo(new BigDecimal("99999999")) > 0
                    || price.scale() > 2) {
                throw new NumberFormatException();
            }

            return price;

        } catch (NumberFormatException | NullPointerException e) {
            throw new IllegalArgumentException("Invalid food price.");
        }
    }

    private String requiredText(String value, int maxLength) {
        if (value == null) {
            throw new IllegalArgumentException("Required field missing.");
        }

        String text = value.trim();

        if (text.isEmpty() || text.length() > maxLength) {
            throw new IllegalArgumentException("Invalid text field.");
        }

        return text;
    }

    private String optionalText(String value, int maxLength) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        String text = value.trim();

        if (text.length() > maxLength) {
            throw new IllegalArgumentException("Text is too long.");
        }

        return text;
    }
}
