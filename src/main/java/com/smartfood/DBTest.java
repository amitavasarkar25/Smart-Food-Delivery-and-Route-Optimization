
package com.smartfood;

import java.sql.Connection;
import java.sql.SQLException;

public class DBTest {

    public static void main(String[] args) {

        try (Connection connection =
                 DBConnection.getConnection()) {

            if (connection != null
                    && connection.isValid(5)) {
                System.out.println(
                    "SUCCESS: MySQL connected!"
                );
            }

        } catch (SQLException e) {
            System.out.println(
                "ERROR: MySQL connection failed."
            );
            e.printStackTrace();
        }
    }
}
