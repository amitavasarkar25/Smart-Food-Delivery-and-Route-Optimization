
package com.smartfood;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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

@WebServlet("/cart")
public class CartServlet extends HttpServlet {

    private boolean requireLogin(
            HttpServletRequest request,
            HttpServletResponse response) throws IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login.jsp");
            return false;
        }

        return true;
    }

    @SuppressWarnings("unchecked")
    private Map<Integer, Integer> getCart(HttpSession session) {

        Object existing = session.getAttribute("cart");

        if (existing instanceof Map<?, ?>) {
            return (Map<Integer, Integer>) existing;
        }

        Map<Integer, Integer> cart = new LinkedHashMap<>();
        session.setAttribute("cart", cart);

        return cart;
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        if (!requireLogin(request, response)) {
            return;
        }

        HttpSession session = request.getSession(false);
        Map<Integer, Integer> cart = getCart(session);

        List<Map<String, Object>> items = new ArrayList<>();
        BigDecimal total = BigDecimal.ZERO;
        boolean hasUnavailableItems = false;

        String sql = "SELECT id, name, price, available "
                   + "FROM food_items WHERE id = ?";

        try (Connection con = DBConnection.getConnection()) {

            for (Map.Entry<Integer, Integer> entry : cart.entrySet()) {

                Integer foodId = entry.getKey();
                Integer quantity = entry.getValue();

                if (foodId == null || quantity == null
                        || foodId <= 0 || quantity < 1 || quantity > 99) {
                    hasUnavailableItems = true;
                    continue;
                }

                try (PreparedStatement ps = con.prepareStatement(sql)) {

                    ps.setInt(1, foodId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (rs.next()) {

                            BigDecimal price = rs.getBigDecimal("price");
                            boolean available = rs.getBoolean("available");

                            Map<String, Object> item =
                                    new LinkedHashMap<>();

                            item.put("id", rs.getInt("id"));
                            item.put("name", rs.getString("name"));
                            item.put("price", price);
                            item.put("quantity", quantity);
                            item.put("available", available);

                            BigDecimal subtotal = price.multiply(
                                    BigDecimal.valueOf(quantity));

                            item.put("subtotal", subtotal);
                            items.add(item);

                            if (available) {
                                total = total.add(subtotal);
                            } else {
                                hasUnavailableItems = true;
                            }

                        } else {
                            // The item was deleted from the database.
                            Map<String, Object> item =
                                    new LinkedHashMap<>();

                            item.put("id", foodId);
                            item.put("name", "Food item no longer exists");
                            item.put("price", BigDecimal.ZERO);
                            item.put("quantity", quantity);
                            item.put("subtotal", BigDecimal.ZERO);
                            item.put("available", false);

                            items.add(item);
                            hasUnavailableItems = true;
                        }
                    }
                }
            }

            request.setAttribute("cartItems", items);
            request.setAttribute("cartTotal", total);
            request.setAttribute(
                    "hasUnavailableItems", hasUnavailableItems);

            request.getRequestDispatcher("/cart.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            getServletContext().log(
                    "Unable to load shopping cart.", e);

            throw new ServletException(
                    "Unable to load your cart. Please try again.", e);
        }
    }

    @Override
    protected void doPost(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        if (!requireLogin(request, response)) {
            return;
        }

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        Map<Integer, Integer> cart = getCart(session);

        String action = request.getParameter("action");
        String idValue = request.getParameter("foodId");
        String quantityValue = request.getParameter("quantity");

        try {

            if (action == null) {
                throw new IllegalArgumentException("Invalid cart action.");
            }

            int foodId = Integer.parseInt(idValue);

            if (foodId <= 0) {
                throw new NumberFormatException();
            }

            if ("remove".equals(action)) {

                cart.remove(foodId);

                session.setAttribute(
                        "cartMessage", "Item removed from your cart.");

            } else if ("add".equals(action)
                    || "update".equals(action)) {

                if (quantityValue == null) {
                    throw new NumberFormatException();
                }

                int quantity = Integer.parseInt(quantityValue);

                if (quantity < 1 || quantity > 99) {
                    session.setAttribute(
                            "cartMessage",
                            "Quantity must be between 1 and 99.");

                    response.sendRedirect(
                            request.getContextPath() + "/cart");
                    return;
                }

                String sql = "SELECT available FROM food_items WHERE id = ?";

                try (Connection con = DBConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(sql)) {

                    ps.setInt(1, foodId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next() || !rs.getBoolean("available")) {

                            session.setAttribute(
                                    "cartMessage",
                                    "This food item is unavailable. "
                                  + "You cannot add or update it.");

                            response.sendRedirect(
                                    request.getContextPath() + "/cart");
                            return;
                        }
                    }
                }

                if ("add".equals(action)) {

                    int current = cart.getOrDefault(foodId, 0);

                    if (current + quantity > 99) {

                        session.setAttribute(
                                "cartMessage",
                                "Maximum quantity per item is 99.");

                    } else {

                        cart.put(foodId, current + quantity);

                        session.setAttribute(
                                "cartMessage",
                                "Item added to your cart.");
                    }

                } else {

                    cart.put(foodId, quantity);

                    session.setAttribute(
                            "cartMessage",
                            "Cart quantity updated.");
                }

            } else {

                session.setAttribute(
                        "cartMessage", "Invalid cart action.");
            }

        } catch (NumberFormatException e) {

            session.setAttribute(
                    "cartMessage", "Invalid item or quantity.");

        } catch (IllegalArgumentException e) {

            session.setAttribute(
                    "cartMessage", e.getMessage());

        } catch (Exception e) {

            getServletContext().log(
                    "Unable to update shopping cart.", e);

            session.setAttribute(
                    "cartMessage",
                    "Unable to update the cart. Please try again.");
        }

        response.sendRedirect(request.getContextPath() + "/cart");
    }
}
