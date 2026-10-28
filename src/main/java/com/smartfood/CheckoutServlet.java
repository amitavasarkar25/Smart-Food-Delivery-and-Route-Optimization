
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
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;

@WebServlet("/checkout")
public class CheckoutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login.jsp");
            return;
        }

        Object cartObject = session.getAttribute("cart");

        if (!(cartObject instanceof Map<?, ?>)
                || ((Map<?, ?>) cartObject).isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/cart");
            return;
        }

        Map<Integer, Integer> cart =
                (Map<Integer, Integer>) cartObject;

        BigDecimal total = BigDecimal.ZERO;

        try (Connection con = DBConnection.getConnection()) {

            for (Map.Entry<Integer, Integer> entry : cart.entrySet()) {

                Integer foodId = entry.getKey();
                Integer quantity = entry.getValue();

                if (foodId == null || quantity == null
                        || foodId <= 0 || quantity < 1 || quantity > 99) {
                    response.sendRedirect(
                            request.getContextPath() + "/cart?error=invalid");
                    return;
                }

                String sql = "SELECT price FROM food_items "
                           + "WHERE id = ? AND available = TRUE";

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, foodId);

                    try (ResultSet rs = ps.executeQuery()) {

                        if (!rs.next()) {
                            response.sendRedirect(
                                    request.getContextPath()
                                            + "/cart?error=unavailable");
                            return;
                        }

                        BigDecimal price = rs.getBigDecimal("price");

                        BigDecimal subtotal = price.multiply(
                                BigDecimal.valueOf(quantity));

                        total = total.add(subtotal);
                    }
                }
            }

        } catch (Exception e) {
            throw new ServletException(
                    "Unable to load checkout.", e);
        }

        request.setAttribute("checkoutTotal", total);

        request.getRequestDispatcher("/checkout.jsp")
               .forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login.jsp");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String address = request.getParameter("deliveryAddress");
        String paymentMethod = request.getParameter("paymentMethod");

        if (address == null || address.trim().isEmpty()
                || address.trim().length() > 500) {
            request.setAttribute(
                    "error", "Enter a valid delivery address.");
            doGet(request, response);
            return;
        }

        if (!"COD".equals(paymentMethod)) {
            request.setAttribute(
                    "error",
                    "Currently, only Cash on Delivery is supported.");
            doGet(request, response);
            return;
        }

        Object cartObject = session.getAttribute("cart");

        if (!(cartObject instanceof Map<?, ?>)
                || ((Map<?, ?>) cartObject).isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/cart");
            return;
        }

        Map<Integer, Integer> cart =
                (Map<Integer, Integer>) cartObject;

        int userId = ((Number) session.getAttribute("userId")).intValue();

        Map<Integer, FoodOrderLine> orderLines =
                new LinkedHashMap<>();

        BigDecimal total = BigDecimal.ZERO;

        try (Connection con = DBConnection.getConnection()) {

            con.setAutoCommit(false);

            try {
                /*
                 * Recheck availability and price inside the transaction.
                 * FOR UPDATE locks each existing food row until the
                 * transaction commits or rolls back.
                 */
                String foodSql =
                        "SELECT name, price, available "
                      + "FROM food_items WHERE id = ? FOR UPDATE";

                for (Map.Entry<Integer, Integer> entry
                        : cart.entrySet()) {

                    Integer foodId = entry.getKey();
                    Integer quantity = entry.getValue();

                    if (foodId == null || quantity == null
                            || foodId <= 0
                            || quantity < 1 || quantity > 99) {
                        throw new InvalidCheckoutException(
                                "Invalid cart quantity. Please review your cart.");
                    }

                    try (PreparedStatement ps =
                                 con.prepareStatement(foodSql)) {

                        ps.setInt(1, foodId);

                        try (ResultSet rs = ps.executeQuery()) {

                            if (!rs.next()) {
                                throw new InvalidCheckoutException(
                                        "A food item no longer exists. "
                                      + "Please review your cart.");
                            }

                            if (!rs.getBoolean("available")) {
                                throw new InvalidCheckoutException(
                                        "A food item is no longer available. "
                                      + "Please remove it from your cart "
                                      + "and try again.");
                            }

                            String name = rs.getString("name");
                            BigDecimal price = rs.getBigDecimal("price");

                            BigDecimal subtotal = price.multiply(
                                    BigDecimal.valueOf(quantity));

                            orderLines.put(
                                    foodId,
                                    new FoodOrderLine(
                                            name, quantity, price, subtotal));

                            total = total.add(subtotal);
                        }
                    }
                }

                // Create the order only after all items pass validation.
                String orderSql =
                        "INSERT INTO orders "
                      + "(user_id, total_amount, status, delivery_address, "
                      + "payment_method) "
                      + "VALUES (?, ?, 'PLACED', ?, ?)";

                int orderId;

                try (PreparedStatement ps = con.prepareStatement(
                        orderSql, Statement.RETURN_GENERATED_KEYS)) {

                    ps.setInt(1, userId);
                    ps.setBigDecimal(2, total);
                    ps.setString(3, address.trim());
                    ps.setString(4, "COD");

                    ps.executeUpdate();

                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (!keys.next()) {
                            throw new ServletException(
                                    "Could not create the order.");
                        }

                        orderId = keys.getInt(1);
                    }
                }

                // Record the initial status in the same transaction.
                String historySql =
                        "INSERT INTO order_status_history "
                      + "(order_id, status) VALUES (?, ?)";

                try (PreparedStatement historyPs =
                        con.prepareStatement(historySql)) {

                    historyPs.setInt(1, orderId);
                    historyPs.setString(2, "PLACED");
                    historyPs.executeUpdate();
                }

                // Insert all order items.
                String itemSql =
                        "INSERT INTO order_items "
                      + "(order_id, food_id, food_name, quantity, price, subtotal) "
                      + "VALUES (?, ?, ?, ?, ?, ?)";

                try (PreparedStatement ps = con.prepareStatement(itemSql)) {

                    for (Map.Entry<Integer, FoodOrderLine> entry
                            : orderLines.entrySet()) {

                        FoodOrderLine item = entry.getValue();

                        ps.setInt(1, orderId);
                        ps.setInt(2, entry.getKey());
                        ps.setString(3, item.name);
                        ps.setInt(4, item.quantity);
                        ps.setBigDecimal(5, item.price);
                        ps.setBigDecimal(6, item.subtotal);

                        ps.addBatch();
                    }

                    ps.executeBatch();
                }

                // Commit order, history, and order items together.
                con.commit();

                // Clear the cart only after a successful commit.
                session.removeAttribute("cart");
                session.setAttribute("lastOrderId", orderId);

                response.sendRedirect(
                        request.getContextPath() + "/order-success.jsp");
                return;

            } catch (Exception e) {

                try {
                    con.rollback();
                } catch (Exception rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;

            } finally {

                try {
                    con.setAutoCommit(true);
                } catch (Exception ignored) {
                    // Connection is closed automatically.
                }
            }

        } catch (InvalidCheckoutException e) {

            request.setAttribute("error", e.getMessage());

            // Preserve the cart and return to checkout for correction.
            doGet(request, response);

        } catch (Exception e) {

            throw new ServletException(
                    "Unable to place order.", e);
        }
    }

    private static class FoodOrderLine {
        final String name;
        final int quantity;
        final BigDecimal price;
        final BigDecimal subtotal;

        FoodOrderLine(String name, int quantity,
                      BigDecimal price, BigDecimal subtotal) {
            this.name = name;
            this.quantity = quantity;
            this.price = price;
            this.subtotal = subtotal;
        }
    }

    private static class InvalidCheckoutException extends Exception {
        InvalidCheckoutException(String message) {
            super(message);
        }
    }
}
